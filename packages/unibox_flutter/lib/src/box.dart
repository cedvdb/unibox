import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'keys.dart';
import 'link_scope.dart';
import 'render.dart';
import 'shape.dart';
import 'stack_node.dart';
import 'text_style_scope.dart';
import 'scroll_scope.dart';
import 'theme_scope.dart';
import 'values.dart';

/// Renders a [core.Box] as a Flutter widget tree.
///
/// The box is built bottom-up: children, scroll viewport, padding, decoration,
/// clipping, dimensions, interactions and finally margin.
class FlutterBox extends StatefulWidget {
  /// Creates a renderer for [box].
  const FlutterBox({required this.box, this.availableWidth, super.key});

  /// The node being rendered.
  final core.Box box;

  /// The width of the layout box this one is drawn in, or `null` when it is not
  /// known.
  ///
  /// A box that names a width threshold hides itself when this is narrower than the
  /// threshold, and a box that holds such a child measures itself so its children can
  /// answer. It is the same quantity the web renderer resolves with a container
  /// query, which is what keeps the two renderings equal at every width.
  final double? availableWidth;

  @override
  State<FlutterBox> createState() => FlutterBoxState();
}

class FlutterBoxState extends State<FlutterBox> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  /// The controller of a box that scrolls, or `null` for one that does not.
  ///
  /// It is created with the offset the page recorded, so the region is at the position the
  /// reader left it *at the first layout*: applying it afterwards would show the top of the
  /// list and then correct it.
  ScrollController? _scroll;

  /// The page this box was last told to show, so a rebuild that states the same one leaves
  /// the reader where they are.
  ///
  /// A page is a position rather than a controller, and a reader may have swiped away from the
  /// one the tree last named: applying it again on every rebuild would drag them back.
  int? _appliedIndex;

  /// The slot each pinned bar keeps in the flow, by the index of its child.
  ///
  /// A bar is drawn over the viewport rather than in the flow, and the flow holds its
  /// room open with a slot that reads the bar's own measured height. Where that slot is —
  /// which is where the bar settles back to — is a fact only its own layout knows, and the
  /// bar reads it from this key.
  final Map<int, GlobalKey> _slots = <int, GlobalKey>{};

  /// The layer each pinned bar is drawn on, by the index of its child.
  ///
  /// The slot in the flow holds the room for the bar it stands for, so it needs a way to
  /// reach it: the key is the bar's, and the layer lays the bars out before the flow that
  /// reads them.
  final Map<int, GlobalKey> _bars = <int, GlobalKey>{};

  /// How this box opens its destination, or `null` when it has none and no scope above it.
  ///
  /// Read while building, so the gesture and the keyboard can both use it: an inherited
  /// widget is looked up during build, not in the handler a press runs.
  FlutterLinkOpener? _open;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _useRecordedScroll();
  }

  @override
  void didUpdateWidget(FlutterBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A different box in this position is a different region, and its position is its own.
    if (oldWidget.box.key != widget.box.key) {
      _useRecordedScroll();
    }
  }

  @override
  void dispose() {
    _scroll?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Moves a pager to the child the tree says it shows, when that is not where it was last sent.
  ///
  /// A page is a position and not a command, so the pager moves only when the value differs from
  /// the one it last applied: a rebuild that states the same index leaves a reader mid-swipe
  /// alone, which is the difference between a description and a controller. The move itself is a
  /// jump — a browser's programmatic scroll can be given neither a duration nor a curve, so an
  /// eased one here would be an animation only Flutter has, and the two renderings would differ
  /// by exactly the thing the model refuses to leave to a host. It happens after the frame,
  /// because a page is the viewport's size and that is only known once the box has been laid out.
  void _applyIndex(core.PagerNode? pager) {
    final int? index = pager?.index;

    if (index == null || index == _appliedIndex) {
      return;
    }

    _appliedIndex = index;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ScrollController? controller = _scroll;

      if (!mounted || controller == null || !controller.hasClients) {
        return;
      }

      controller.jumpTo(index * controller.position.viewportDimension);
    });
  }

  /// Creates the controller of a scrolling box, at the offset the page recorded for it.
  ///
  /// The scope is read here and not in `initState`, because an inherited widget is not
  /// available there. Once created, the controller belongs to the reader: a rebuild does
  /// not move them back to where the page said.
  void _useRecordedScroll() {
    final bool scrolls =
        widget.box.computedStyle.overflow == core.Overflow.scroll;

    if (!scrolls) {
      _scroll?.dispose();
      _scroll = null;

      return;
    }

    if (_scroll != null) {
      return;
    }

    final core.BoxScrollOffset? offset = UniboxScrollScope.offsetOf(
      context,
      widget.box.key,
    );
    final bool vertical =
        toAxis(widget.box.computedStyle.resolvedDirection) == Axis.vertical;

    _scroll = ScrollController(
      initialScrollOffset: offset == null
          ? 0
          : (vertical ? offset.dy : offset.dx),
    );
  }

  /// The keyboard focus of this box, when it is focusable.
  ///
  /// The box states its own focusable and focused flags to a screen reader, so the
  /// [Focus] widget around it must not state them again: a `Focus` that describes
  /// itself is a semantics node of its own, and the label and the tap action merged
  /// into *that* node instead of the one carrying the button role — which is how an
  /// enabled button came to be announced as plain text with a tap action, and a
  /// disabled one, with no action to merge into, as the button it is.
  final FocusNode _focusNode = FocusNode(debugLabel: 'unibox-box');

  @override
  Widget build(BuildContext context) {
    final core.Box box = widget.box;
    final core.BoxStyle style = _resolvedStyle(box)
        .resolve(UniboxThemeScope.of(context) ?? core.UniboxTheme.none);

    // A stretching parent says so here instead of handing a tight width: a box that states
    // a size of its own keeps it, which is what `align-items: stretch` does to a flex item
    // whose cross size is not `auto`.
    final Axis? stretchedAcross = _StretchedAcross.maybeOf(context);

    // A link asks the host once, while an inherited widget can be read.
    _open = box.enabled && box is core.LinkNode
        ? FlutterLinkScope.maybeOf(context)
        : null;

    final List<core.Box> pinned = _pinnedChildren(box, style);

    // A pager is a node rather than a token, so the renderer reads it here: the physics below, the
    // index it is told to show and the settled page it reports all come from it.
    final core.PagerNode? pager = box is core.PagerNode ? box : null;

    // A fold is driven by whatever scrolls the box, which is the nearest `Scrollable` and not
    // necessarily this box: a hero inside a scrolling column folds over that column's scroll.
    // No scrollable above it means the box never leaves, so it keeps its resting look.
    final ScrollPosition? foldedAt = style.fold == null
        ? null
        : Scrollable.maybeOf(context)?.position;
    final core.BoxFold? fold = foldedAt == null ? null : style.fold;

    Widget content = _holdsThreshold
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                _buildFlow(
                  box,
                  style,
                  pinned,
                  availableWidth: constraints.maxWidth,
                ),
          )
        : _buildFlow(box, style, pinned, availableWidth: null);

    // The flag stops at the item it reached: this box was the child the parent stretched,
    // and what it holds is laid out by its own flex, not by the parent's.
    content = _StretchedAcross(flexDirection: null, child: content);

    // A direction wraps the flow and never sits inside it: a `Row` reads
    // `Directionality` when it lays its children out, so the inherited widget has to be
    // above the flex. That is also where CSS puts the inherited `direction` — on the
    // element, which its children inherit — so a box that states one reverses its
    // children without a second tree, and a box that states none keeps the closest one
    // above it, ending at the application's own.
    final core.WritingDirection? writingDirection = style.writingDirection;
    if (writingDirection != null) {
      content = Directionality(
        textDirection: toTextDirection(writingDirection),
        child: content,
      );
    }

    _applyIndex(pager);

    final core.BoxTextStyle textStyle =
        style.textStyle ?? const core.BoxTextStyle();
    if (!textStyle.isEmpty) {
      content = _inheritTypography(context, content, textStyle);
    }

    // A pinned child needs a viewport of its own — `_buildFlow` built one when it found
    // one — so the box only scrolls through a plain scroll view when nothing pins.
    if (style.overflow == core.Overflow.scroll) {
      if (pinned.isEmpty) {
        content = SingleChildScrollView(
          scrollDirection: toAxis(style.resolvedDirection),
          controller: _scroll,
          // A pager settles on a child instead of wherever the finger stopped. The physics is
          // the whole of it: a page is a child the size of the box — the rule `validateTree`
          // states — so the viewport's own boundaries are the children's, and the two targets
          // agree because CSS snaps to the child's own `scroll-snap-align` edge.
          physics: pager == null ? null : const PageScrollPhysics(),
          child: content,
        );
      }

      // A scroll view pulled past its end is decorated by its host: a Material application glows,
      // or stretches the content, and a browser paints nothing at all. That decoration is chrome,
      // which is the one thing a node never keeps — a box states what it looks like, and the
      // scrollbar and the physics stay the host's.
      content = ScrollConfiguration(
        behavior: _NoOverscrollGlow(ScrollConfiguration.of(context)),
        child: content,
      );

      final core.ScrollCallback? onScroll = box.onScroll;
      final core.PageChangedCallback? onPageChanged = pager?.onPageChanged;

      if (onScroll != null || onPageChanged != null) {
        // *Around* the scroll view: a notification travels up from the scrollable to its
        // ancestors, so a listener inside it hears nothing.
        content = NotificationListener<ScrollNotification>(
          // A scrollable nested in the content notifies this listener too, at a greater
          // depth: only this box's own viewport is reported, which is what the browser's
          // non-bubbling `scroll` event gives for free.
          onNotification: (ScrollNotification notification) {
            if (notification.depth != 0) {
              return false;
            }

            final ScrollMetrics metrics = notification.metrics;

            if (onScroll != null && notification is ScrollUpdateNotification) {
              onScroll(metrics.pixels);
            }

            // A page is where the pager came to rest, so this is the end of a gesture or of the
            // move the tree asked for — never the frames in between. The index is read back from
            // the viewport rather than remembered, so a swipe and a stated index are the same
            // answer, which is what lets a store keep one number and follow both.
            if (onPageChanged != null &&
                notification is ScrollEndNotification &&
                metrics.viewportDimension > 0) {
              onPageChanged(
                (metrics.pixels / metrics.viewportDimension).round(),
              );
            }

            return false;
          },
          child: content,
        );
      }
    }

    final core.BoxSpacing? padding = style.padding;
    if (padding != null && !padding.isZero) {
      content = Padding(padding: toEdgeInsets(padding), child: content);
    }

    final core.BoxShape? shape = style.shape;

    // A scrolling box already clips its own viewport, but squarely: it needs an
    // explicit clip only when the box is rounded, so that the content is cut to the
    // radius the way CSS cuts it.
    final double radius = style.borderRadius ?? 0;
    final bool clipsContent =
        style.overflow == core.Overflow.hidden ||
        (style.overflow == core.Overflow.scroll &&
            (radius > 0 || shape != null));

    // The clip goes *inside* the decoration, not around it. CSS cuts a box's content
    // to its radius and never its own `box-shadow`, which paints outside the border
    // box; a ClipRRect around a DecoratedBox would swallow the shadow, and a card with
    // `overflow: hidden` would be lifted on the web and flat in Flutter.
    if (clipsContent) {
      content = _clipTo(content, style);
    }

    // A shape replaces the rectangle the decoration would paint: the same box, drawn
    // as its outline. It goes where the decoration goes — around the clipped content
    // — so the fill is behind the children, the way CSS paints a background behind
    // content, and the clip still cuts them to the same path.
    if (shape != null) {
      content = CustomPaint(
        painter: UniboxShapePainter(
          shape: shape,
          fill: style.backgroundColor,
          border: style.border,
        ),
        child: content,
      );
    } else if (fold != null) {
      content = _folded(content, style, fold, foldedAt!);
    } else {
      final BoxDecoration? decoration = toDecoration(style);
      if (decoration != null) {
        content = _decorated(
          decoration,
          _paintTiming(style.transition),
          content,
        );
      }
    }

    content = _applyDimensions(
      content,
      style,
      stretchedAcross: stretchedAcross,
    );
    content = _applyLook(content, style, box, fold: fold);
    content = _applyInteractions(content, box);

    final core.BoxSpacing? margin = style.margin;
    if (margin != null && !margin.isZero) {
      content = Padding(padding: toEdgeInsets(margin), child: content);
    }

    return _visibleEverywhere(content, style);
  }

  /// Paints [decoration] behind [child], interpolating when the box asks for it.
  ///
  /// A `DecoratedBox` cannot animate itself, so a box with a transition hands its
  /// decoration to a `TweenAnimationBuilder`: on the next rebuild the widget tweens
  /// from the decoration it painted last to the one the new state asks for, which
  /// is exactly the set `BoxDecoration.lerp` covers — background, border colour,
  /// corner radius and shadow. Layout never animates, matching the CSS side.
  Widget _decorated(BoxDecoration decoration, _Timing? timing, Widget child) {
    if (timing == null) {
      return _painted(decoration, child);
    }

    return TweenAnimationBuilder<Decoration>(
      // The first build paints the decoration as it is; every later one starts
      // from whatever the animation had reached, so a fast hover in and out of a
      // box does not snap back to the old look.
      tween: DecorationTween(begin: decoration, end: decoration),
      duration: timing.duration,
      curve: timing.curve,
      builder: (BuildContext context, Decoration value, Widget? inner) =>
          _painted(value, inner),
      child: child,
    );
  }

  /// Paints [decoration]: its shadows the way CSS draws them, then its fill, its border and
  /// its children over them.
  ///
  /// The two are separate only when there are shadows to place, because `DecoratedBox` paints
  /// a shadow *through* a box that has no fill — see [_OuterShadowPainter] — and the split
  /// costs a `CustomPaint` that a box without shadows does not pay for.
  Widget _painted(Decoration decoration, Widget? child) {
    if (decoration is! BoxDecoration ||
        (decoration.boxShadow?.isEmpty ?? true)) {
      return DecoratedBox(decoration: decoration, child: child);
    }

    return CustomPaint(
      painter: _OuterShadowPainter(decoration),
      child: DecoratedBox(
        // The shadows are the painter's, so the box paints only what is left: the same
        // decoration, one list shorter.
        decoration: decoration.copyWith(boxShadow: const <BoxShadow>[]),
        child: child,
      ),
    );
  }

  /// The timing the paint of this box eases with, if it eases at all.
  ///
  /// The four paint looks share one timing (validated), so any of them stands for
  /// the decoration they all belong to.
  _Timing? _paintTiming(core.BoxTransition? transition) {
    return transition == null
        ? null
        : _timingOf(transition, core.BoxProperty.backgroundColor);
  }

  /// Resolves the timing of [look] out of [transition].
  ///
  /// A delay becomes an `Interval` of the longest timeline in the transition, so an
  /// implicit animation can wait without an `AnimationController` of its own: before
  /// its interval it holds the value it had, after it the one it is heading for.
  _Timing _timingOf(core.BoxTransition transition, core.BoxProperty look) {
    final core.BoxTransitionTiming timing = transition.timingOf(look);
    final int total = transition.totalDuration.inMicroseconds;
    final Curve curve = toCurve(timing.curve);

    if (total <= 0) {
      return (duration: transition.totalDuration, curve: curve);
    }

    final double start = timing.delay.inMicroseconds / total;
    final double end = (timing.delay + timing.duration).inMicroseconds / total;

    return (
      duration: transition.totalDuration,
      curve: start <= 0 && end >= 1
          ? curve
          : Interval(start, end, curve: curve),
    );
  }

  /// Clips [child] to the box's content, rounded when the box has a corner radius.
  ///
  /// A plain `ClipRect` cuts square corners, while CSS clips an element with
  /// `overflow` to its `border-radius`: a rounded card that hides what sticks out
  /// would be rounded in the browser and square in Flutter. The radius is the one
  /// the box paints with, so the clip and the decoration can never disagree.
  ///
  /// A box with a line is cut at the *inner* edge of that line, which is where a browser
  /// cuts it: CSS clips an element's overflow to its padding box, and the padding box
  /// starts inside the border. Flutter clipped the whole box, so a child that fills it —
  /// the fill of a chosen segment, the tint of a hover — painted over the outline of the
  /// pill around it, and in the browser it stopped at the line. The radius shrinks with
  /// the inset, as CSS reduces an inner radius by the border's width, so the children are
  /// cut with the curve of the line's inside rather than a curve that has moved away from
  /// it.
  Widget _clipTo(Widget child, core.BoxStyle style) {
    final core.BoxShape? shape = style.shape;

    if (shape != null) {
      return ClipPath(clipper: UniboxShapeClipper(shape), child: child);
    }

    final double radius = style.borderRadius ?? 0;
    final core.BoxBorder? border = style.border;
    final double line = border != null && border.isVisible ? border.width : 0;

    if (line > 0) {
      return ClipPath(
        clipper: _BorderBoxClipper(line: line, radius: radius),
        child: child,
      );
    }

    if (radius <= 0) {
      return ClipRect(child: child);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }

  /// Moves, turns, scales and fades the box, easing when the box asks for it.
  ///
  /// A transform and an opacity paint differently without taking different room,
  /// which is what CSS does with `transform` and `opacity` and what Flutter does
  /// with `Transform` (about the centre, like CSS's default origin) and `Opacity`.
  ///
  /// A box whose look can change — one with state styles — gets the animated
  /// versions, so a state that *introduces* a scale or a fade eases in from the
  /// identity instead of jumping, exactly as a CSS transition does when the resting
  /// rule declares nothing. A box that is not animated and has nothing to paint
  /// differently is left untouched.
  Widget _applyLook(
    Widget child,
    core.BoxStyle style,
    core.Box box, {
    core.BoxFold? fold,
  }) {
    // A fold owns the two looks it moves: it paints them from the scroll offset, so applying
    // the resting value here as well would paint the box twice.
    final Set<core.BoxProperty> folded =
        fold?.looks ?? const <core.BoxProperty>{};
    final core.BoxTransform? transform =
        folded.contains(core.BoxProperty.transform) ? null : style.transform;
    final double? opacity = folded.contains(core.BoxProperty.opacity)
        ? null
        : style.opacity;

    final core.BoxTransition? transition = style.transition;
    final bool animated = transition != null;

    // A box that cannot change and has nothing to paint differently is left
    // alone. A box that *can* change keeps the wrappers even while its resting
    // look is identity, or the state that introduces a scale would insert them
    // mid-life and start from the end value instead of easing into it.
    if (transform == null && opacity == null && !animated) {
      return child;
    }
    final core.BoxTransform value = transform ?? const core.BoxTransform();
    final double alpha = (opacity ?? 1).clamp(0.0, 1.0);

    Widget result = child;

    if (!value.isIdentity || animated) {
      result = _transformed(
        result,
        value,
        animated ? _timingOf(transition, core.BoxProperty.transform) : null,
      );
    }
    if (alpha < 1 || animated) {
      result = _opacified(
        result,
        alpha,
        animated ? _timingOf(transition, core.BoxProperty.opacity) : null,
      );
    }

    return result;
  }

  /// Applies [transform] to [child], animating it when [transition] is given.
  Widget _transformed(
    Widget child,
    core.BoxTransform transform,
    _Timing? timing,
  ) {
    // The fraction is a translation of the box by its own size, which Flutter keeps out of the
    // matrix: `FractionalTranslation` is that, and CSS writes the same thing as a percentage.
    Widget fractioned(Widget inner, core.BoxTransform value) {
      if (value.fractionX == 0 && value.fractionY == 0) {
        return inner;
      }

      return FractionalTranslation(
        translation: Offset(value.fractionX, value.fractionY),
        child: inner,
      );
    }

    if (timing == null) {
      return fractioned(
        Transform(
          transform: toMatrix4(transform),
          alignment: Alignment.center,
          child: child,
        ),
        transform,
      );
    }

    return TweenAnimationBuilder<core.BoxTransform>(
      tween: _BoxTransformTween(begin: transform, end: transform),
      duration: timing.duration,
      curve: timing.curve,
      builder:
          (BuildContext context, core.BoxTransform animated, Widget? inner) =>
              fractioned(
                Transform(
                  transform: toMatrix4(animated),
                  alignment: Alignment.center,
                  child: inner,
                ),
                animated,
              ),
      child: child,
    );
  }

  /// Applies [opacity] to [child], animating it when [transition] is given.
  Widget _opacified(Widget child, double opacity, _Timing? timing) {
    if (timing == null) {
      return Opacity(opacity: opacity, child: child);
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: timing.duration,
      curve: timing.curve,
      child: child,
    );
  }

  /// Passes the typography of the box down to its descendants.
  ///
  /// The `DefaultTextStyle` makes Flutter's own widgets inherit the tokens, and
  /// the scope records the resolved typography for renderers that have to opt
  /// in, such as text fields. Only tokens the box sets are laid over the ambient
  /// style, so everything else keeps being inherited from the host application.
  Widget _inheritTypography(
    BuildContext context,
    Widget child,
    core.BoxTextStyle textStyle,
  ) {
    final core.BoxTextStyle inherited = FlutterTextStyleScope.of(context)
        .merge(textStyle);

    return DefaultTextStyle.merge(
      style: toTextStyle(textStyle),
      child: FlutterTextStyleScope(style: inherited, child: child),
    );
  }

  /// Lays out the children, inserting `gap` separators between them.
  ///
  /// The direction resolves to a column when the box does not name one (see
  /// [core.BoxStyle.resolvedDirection]), so `gap`, `mainAlign` and `crossAlign`
  /// apply to every box instead of only to the ones that spelled the direction
  /// out.
  ///
  /// [bars] names the children that are drawn over the viewport instead of in the flow, by the
  /// index of the child: the flow keeps their room, so nothing below them moves while they are
  /// pinned. The room is the bar's own measured height, which the bar states, or its content
  /// decides, or its `minHeight` floors.
  ///
  /// A box without children still renders its flex container. It lays out
  /// nothing either way, but the web renderer marks every box as a flex
  /// container, so leaving the empty one out would make the two trees describe
  /// the same box differently.
  Widget _buildContent(
    core.Box box,
    core.BoxStyle style, {
    required double? availableWidth,
    Map<int, GlobalKey>? bars,
  }) {
    final core.Axis direction = style.resolvedDirection;
    final double? gap = style.gap;
    final bool wrap = style.wrap ?? false;
    final core.CrossAlign crossAlign =
        style.crossAlign ?? core.CrossAlign.start;
    final bool stretch = crossAlign == core.CrossAlign.stretch;

    // A wrapping box spaces its children itself, between two of them and between two
    // lines, which a `Wrap` does with two numbers; a flex adds a spacer child instead.
    final List<Widget> children = <Widget>[];

    for (var index = 0; index < box.children.length; index++) {
      if (!wrap && index > 0 && gap != null && gap > 0) {
        children.add(
          direction == core.Axis.horizontal
              ? SizedBox(width: gap)
              : SizedBox(height: gap),
        );
      }

      final GlobalKey? bar = bars?[index];

      children.add(
        bar == null
            ? _buildChild(
                box.children[index],
                direction,
                availableWidth: availableWidth,
                flexible: !wrap,
                stretch: stretch,
              )
            : _PinnedSlot(
                key: _slots.putIfAbsent(index, GlobalKey.new),
                bar: bar,
              ),
      );
    }

    final MainAxisAlignment mainAxisAlignment = toMainAxisAlignment(
      style.mainAlign ?? core.MainAlign.start,
    );

    // A wrap is its own layout widget: it breaks a run where CSS breaks a line, and it
    // has no flex children, so a child that states a share is reported by `validateTree`.
    if (wrap) {
      return Wrap(
        direction: toAxis(direction),
        alignment: toWrapAlignment(style.mainAlign ?? core.MainAlign.start),
        crossAxisAlignment:
            toWrapCrossAlignment(crossAlign) ?? WrapCrossAlignment.start,
        spacing: gap ?? 0,
        runSpacing: gap ?? 0,
        children: children,
      );
    }

    // A stretch is not Flutter's `CrossAxisAlignment.stretch`: that hands every child a
    // tight width, and a tight constraint wins over the child's own `width`, so a box that
    // states 280 came out as wide as the section while the browser left it at 280. The model's
    // stretch is CSS's: an item whose cross size is `auto` fills the line, and one that
    // states a size keeps it. So the children are placed at the cross start and each one
    // decides — `_stretchedChild` tells a box it is stretched, and fills a leaf that has no
    // size of its own.
    final CrossAxisAlignment crossAxisAlignment =
        crossAlign == core.CrossAlign.stretch
        ? CrossAxisAlignment.start
        : toCrossAxisAlignment(crossAlign);

    // A stack is a layer, not a flow child, so it takes the box's own constraints
    // instead of a flex's: a flex hands its children an unbounded main axis, and a
    // stack cannot be laid out in one. It is the shape that clips a layer —
    // `Box(overflow: hidden, child: StackNode(...))` — and the web renderer already
    // draws it, since an absolutely positioned child of a flow-sized item lands
    // where it was put.
    //
    // The pair is not lost with the flex: on the web the stack is the flex's one flow
    // child, so the alignment places the stack itself — which hugs its content — and
    // a stack that fills the box has to place its children instead. It is the same
    // rectangle, and without it a segmented button's label sat at the top of its pill
    // in Flutter while the browser centred it.
    if (box.children.length == 1 && box.children.single is core.StackNode) {
      final core.StackNode stack = box.children.single as core.StackNode;

      return FlutterStack(
        node: stack,
        alignment: toBoxAlignment(
          style.mainAlign ?? core.MainAlign.start,
          crossAlign,
          direction,
        ),
        key: toFlutterKey(stack.key),
      );
    }

    if (direction == core.Axis.horizontal) {
      final Widget row = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        // Stated even when it is not used: a baseline alignment is the one value that
        // needs it, and a flex that leaves it out asserts when it is.
        textBaseline: uniboxTextBaseline,
        children: children,
      );

      return stretch ? _StretchedLine(across: Axis.vertical, child: row) : row;
    }

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: uniboxTextBaseline,
      children: children,
    );

    return stretch
        ? _StretchedLine(across: Axis.horizontal, child: column)
        : column;
  }

  /// The content of the box inside its viewport.
  ///
  /// A box that holds a pinned bar is laid out by [_buildPinnedContent]: a
  /// `SingleChildScrollView` lays its whole content out in one box, so a child of it has
  /// nowhere to stay while the content moves past. Every other box is a flex container.
  Widget _buildFlow(
    core.Box box,
    core.BoxStyle style,
    List<core.Box> pinned, {
    required double? availableWidth,
  }) => pinned.isEmpty
      ? _buildContent(box, style, availableWidth: availableWidth)
      : _buildPinnedContent(box, style, availableWidth: availableWidth);

  /// The children of [box] that pin to the edge of its viewport.
  ///
  /// A pin holds a vertical edge, so only a box that scrolls down has edges to pin to: a
  /// pin in any other box is reported by `validateTree`, and drawing it in the flow is
  /// the one answer both targets give for a tree it refuses.
  static List<core.Box> _pinnedChildren(core.Box box, core.BoxStyle style) {
    if (box is core.PagerNode) {
      // A pager's viewport holds one child at a time, so a bar pinned to it would be painted
      // over the page that replaced it. `validateTree` reports the tree; drawing it in the flow
      // is the one answer both targets give for a tree they refuse.
      return const <core.Box>[];
    }

    if (style.overflow != core.Overflow.scroll ||
        style.resolvedDirection != core.Axis.vertical) {
      return const <core.Box>[];
    }

    return <core.Box>[
      for (final core.UINode child in box.children)
        if (child is core.Box && child.computedStyle.pin != null) child,
    ];
  }

  /// [child] placed across the axis a viewport cannot align on its own.
  ///
  /// A bar drawn over the viewport is handed the whole width of it, tight, where a column
  /// hands a child the room it asks for and places it by the box's `crossAlign`. Only a
  /// stretched child wants the whole width; the rest are wrapped.
  Widget _aligned(Widget child, core.CrossAlign crossAlign) {
    final AlignmentGeometry? alignment = toPinnedAlignment(crossAlign);

    return alignment == null
        ? child
        : Align(alignment: alignment, child: child);
  }

  /// The content of a box that holds pinned bars: the flow it always had, with the
  /// bars drawn over it.
  ///
  /// A pinned bar is lifted out of the flow and painted over the viewport at the edge it
  /// named, driven by the scroll offset of this box: it comes to rest at
  /// [core.BoxPin.start] or [core.BoxPin.end] once the content would have carried it past,
  /// and settles back into the flow when its slot comes up. That is what a browser states
  /// with `position: sticky`, and it is why the bar paints above the content: a bar drawn
  /// in the flow order it was written in would be painted over by the content that scrolls
  /// under it, and a browser only escapes that with the `z-index` it writes beside the
  /// position.
  ///
  /// The slot keeps the room the bar takes, which is the height the bar laid itself out at —
  /// a number it does not have to state, because a bar whose content wraps has no height to
  /// state. Laying the flow out exactly as before is the other half of it: `gap`, `crossAlign`
  /// and `mainAlign` stay a flex container's, so the trees that already exist are drawn as
  /// they were.
  Widget _buildPinnedContent(
    core.Box box,
    core.BoxStyle style, {
    required double? availableWidth,
  }) {
    final Map<int, GlobalKey> slots = <int, GlobalKey>{};
    final List<Widget> bars = <Widget>[];

    for (var index = 0; index < box.children.length; index++) {
      final core.UINode child = box.children[index];
      final core.Box? bar = child is core.Box ? child : null;
      final core.BoxStyle? barStyle = bar?.computedStyle;
      final core.BoxPin? pin = barStyle?.pin;

      // A bar has to be a length: `validateTree` reports one that states an infinity, since
      // nothing can hold a slot of no size open, and drawing it in the flow is the one answer
      // both targets give for a pin they cannot honour.
      if (bar == null ||
          pin == null ||
          (barStyle!.height?.isInfinite ?? false)) {
        continue;
      }

      final GlobalKey barKey = _bars.putIfAbsent(index, GlobalKey.new);

      slots[index] = barKey;
      bars.add(
        _pinnedChild(
          _buildChild(bar, core.Axis.vertical, availableWidth: availableWidth),
          scroll: _scroll,
          pin: pin,
          slot: _slots.putIfAbsent(index, GlobalKey.new),
          inset: barStyle.resolvedPinOffset,
          crossAlign: style.crossAlign ?? core.CrossAlign.start,
          key: barKey,
        ),
      );
    }

    return _PinnedLayer(
      children: <Widget>[
        // A scroll view handed a loose height is as tall as the content it was given, which is
        // a viewport with nothing to scroll; the layer hands every child the room the box was
        // given instead.
        SingleChildScrollView(
          scrollDirection: toAxis(style.resolvedDirection),
          controller: _scroll,
          child: _buildContent(
            box,
            style,
            availableWidth: availableWidth,
            bars: slots,
          ),
        ),
        ...bars,
      ],
    );
  }

  /// [content] under the look a fold paints.
  ///
  /// The resting look is where the fold starts and [core.BoxFold.to] is where it arrives; the
  /// layer paints the interpolation rather than rebuilding it, so a scroll asks for a repaint
  /// and the box's children are built once — the same reason the pinned bar is a layer.
  Widget _folded(
    Widget content,
    core.BoxStyle style,
    core.BoxFold fold,
    ScrollPosition position,
  ) {
    return _FoldedBox(
      position: position,
      fold: fold,
      resting: style,
      folded: style.merge(fold.to),
      child: content,
    );
  }

  /// [bar] drawn at the edge it pins to, over the content that scrolls under it.
  ///
  /// The layer takes the whole viewport and paints the bar at the place the scroll offset
  /// puts it, so a scroll repaints the bar instead of rebuilding it: the subtree is built
  /// once and painted wherever the edge is, which is also what keeps the bar's own
  /// subtree — a field, a menu — alive while it is being carried around.
  Widget _pinnedChild(
    Widget bar, {
    required ScrollController? scroll,
    required core.BoxPin pin,
    required GlobalKey slot,
    required double inset,
    required core.CrossAlign crossAlign,
    required GlobalKey key,
  }) {
    if (scroll == null) {
      return SizedBox.shrink(key: key);
    }

    return _PinnedBar(
      key: key,
      scroll: scroll,
      pin: pin,
      slot: slot,
      inset: inset,
      child: _aligned(bar, crossAlign),
    );
  }

  /// Renders [node] and makes it flexible along the parent's `direction` when it
  /// declares a [core.BoxStyle.flex] factor or an infinite main dimension.
  ///
  /// [flexible] is off for the child of a wrapping box, which has no flex children: a
  /// `Wrap` lays each child out at its own size, so an `Expanded` in it is a Flutter
  /// error rather than a share. `validateTree` reports that tree instead.
  ///
  Widget _buildChild(
    core.UINode node,
    core.Axis direction, {
    required double? availableWidth,
    bool flexible = true,
    bool stretch = false,
  }) {
    Widget child = renderNode(node, availableWidth: availableWidth);

    if (node is! core.Box) {
      return stretch ? _stretchedChild(child, node, direction) : child;
    }

    final core.BoxStyle childStyle = node.computedStyle;

    // A box this width does not draw takes no room, including the share its `flex`
    // would claim: `display: none` removes a flex item in CSS, so the Flutter side
    // must not reserve the space it is not using.
    if (!childStyle.isShownAt(availableWidth ?? double.infinity)) {
      // Kept alive and out of the layout: the zero box is what stops an `Offstage`
      // child in a row from being measured against an unbounded main axis, where a
      // `width: double.infinity` inside it would become an invalid constraint.
      return Visibility(
        visible: false,
        maintainState: true,
        child: SizedBox(width: 0, height: 0, child: child),
      );
    }

    if (stretch) {
      child = _stretchedChild(child, node, direction);
    }

    final double? mainSize = direction == core.Axis.horizontal
        ? childStyle.width
        : childStyle.height;
    // A box that fills only *up to a measure* is not a flex child. CSS gives it
    // `min(100%, max-width)`, so the container's own alignment can then place the result on
    // the line — and an `Expanded` would claim the whole line and leave that alignment
    // nothing to move, which put a centred section's 1080-pixel column against its left edge.
    final double? mainMax = direction == core.Axis.horizontal
        ? childStyle.maxWidth
        : childStyle.maxHeight;
    final int? flex = childStyle.flex;
    final bool expands = mainSize == double.infinity && mainMax == null;
    final bool hasFlex = flex != null && flex > 0;

    if (!expands && !hasFlex) {
      return child;
    }

    if (!flexible) {
      return child;
    }

    return Expanded(flex: hasFlex ? flex : 1, child: child);
  }

  /// [child] as the child of a stretching flex: filled across [direction]'s other axis
  /// unless it states a size of its own.
  ///
  /// A box, or the view of a stateful node, decides for itself — it knows whether it states
  /// a width, and [_StretchedAcross] lets it fill when it does not. A leaf has no renderer
  /// to ask, so the decision is made here: a picture keeps its intrinsic size, a stack that
  /// states one keeps it, an overlay is out of the flow, and every other leaf fills the line
  /// — which is what a browser does to a block whose cross size is `auto`.
  Widget _stretchedChild(Widget child, core.UINode node, core.Axis direction) {
    if (node is core.Box || node is core.StatefulNode) {
      return _StretchedAcross(flexDirection: toAxis(direction), child: child);
    }

    final bool sized = switch (node) {
      // A picture keeps its own size: a replaced element's width is its intrinsic one,
      // so a browser's stretch does not reach it either.
      core.ImageNode() => true,
      // A layer is not drawn in the flow of its parent, so there is no line to fill.
      core.OverlayNode() => true,
      final core.StackNode stack =>
        direction == core.Axis.vertical
            ? stack.width != null
            : stack.height != null,
      _ => false,
    };

    if (sized) {
      return child;
    }

    return _FillCross(
      across: direction == core.Axis.vertical ? Axis.horizontal : Axis.vertical,
      child: child,
    );
  }

  /// [child] sized the way the shares the box states ask for.
  ///
  /// A share of the parent with nothing taken off it is a `FractionallySizedBox`: it is the
  /// one shape whose constraint is the same on both targets, because a percentage is. The
  /// other cases each need a number that build time may not have — a share of the viewport is
  /// resolved from the window, which is known while the box is built, and a share of the
  /// parent that loses an inset needs the room the parent offers, which only a layout pass
  /// knows, so it is measured with a `LayoutBuilder`. A box that states neither pays for
  /// neither.
  Widget _fractioned(
    Widget child,
    core.BoxFraction? width,
    core.BoxFraction? height,
  ) {
    final bool plain =
        (width?.isPlainParentShare ?? true) &&
        (height?.isPlainParentShare ?? true);

    if (plain) {
      return FractionallySizedBox(
        widthFactor: width?.value,
        heightFactor: height?.value,
        child: child,
      );
    }

    final Size window = MediaQuery.sizeOf(context);
    Widget result = child;

    final double? across = width != null && width.isOfViewport
        ? width.resolve(window.width)
        : null;
    final double? along = height != null && height.isOfViewport
        ? height.resolve(window.height)
        : null;

    if (across != null || along != null) {
      result = SizedBox(width: across, height: along, child: result);
    }

    final core.BoxFraction? parentAcross = width != null && width.isOfParent
        ? width
        : null;
    final core.BoxFraction? parentAlong = height != null && height.isOfParent
        ? height
        : null;

    if (parentAcross == null && parentAlong == null) {
      return result;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => SizedBox(
        width: parentAcross?.resolve(constraints.maxWidth),
        height: parentAlong?.resolve(constraints.maxHeight),
        child: result,
      ),
    );
  }

  /// Applies the fixed sizes, the aspect ratio and the min/max constraints of [style].
  ///
  /// [stretchedAcross] is the direction of a parent flex that stretches this box, when
  /// one does. CSS fills an item whose cross size is `auto` and leaves one that states its
  /// own size alone, so a box without a size on that axis fills the line here; a maximum
  /// still caps it, because the fill goes inside the constraints at the end.
  Widget _applyDimensions(
    Widget content,
    core.BoxStyle style, {
    Axis? stretchedAcross,
  }) {
    Widget result = content;

    if (stretchedAcross != null) {
      final bool acrossWidth = stretchedAcross == Axis.vertical;
      final bool statesSize = acrossWidth
          ? style.width != null || style.widthFraction != null
          : style.height != null || style.heightFraction != null;

      if (!statesSize) {
        result = _FillCross(
          across: acrossWidth ? Axis.horizontal : Axis.vertical,
          child: result,
        );
      }
    }

    // The ratio goes *inside* the sizes and not around them: a box that states a width
    // hands the ratio a width to measure, and the ratio gives the height back. Wrapped
    // the other way round it would be handed the same tight box the `SizedBox` made and
    // could only keep it, which is what CSS does with a declared width and height too.
    final double? aspectRatio = style.aspectRatio;
    if (aspectRatio != null) {
      result = AspectRatio(aspectRatio: aspectRatio, child: result);
    }

    if (style.width != null || style.height != null) {
      result = SizedBox(
        width: style.width,
        height: style.height,
        child: result,
      );
    }

    // A fraction of the space offered, which is the one size a box can state without knowing
    // one: a share of a row, one tab of a bar. It wins over a stated size, as CSS does, and it
    // names what it is a share of: the box around it, or the viewport — the extent that is
    // known without a bounded parent to hand over.
    if (style.widthFraction != null || style.heightFraction != null) {
      result = _fractioned(result, style.widthFraction, style.heightFraction);
    }

    final BoxConstraints? constraints = toConstraints(style);
    if (constraints != null) {
      result = ConstrainedBox(constraints: constraints, child: result);
    }

    return result;
  }

  /// Wraps [content] with the tap, keyboard, hover and semantics layers of [box].
  ///
  /// A disabled box keeps the same widget shape but serves no handler, no
  /// pointer cursor and no focus, so disabling never moves anything and only
  /// removes what the user can do.
  ///
  /// A link is the anchor: the pointer over it is a hand, the press that the box
  /// itself does not answer opens the destination through the host's scope, and a screen
  /// reader is told it is a link. The gesture stays the box's, which is what keeps the
  /// pressed state and the ink a well starts on tap-down working — wrapping the box in a
  /// wrapper would put a second gesture and a second semantics node around it.
  Widget _applyInteractions(Widget content, core.Box box) {
    final bool interactive = box.isInteractive;
    final core.LinkNode? destination = box is core.LinkNode ? box : null;
    final bool link = destination != null && box.enabled;
    final bool focusable = box.isFocusable && box.enabled;
    final bool tracksState =
        box.enabled &&
        (box.onHover != null ||
            box.stateStyle(core.BoxState.hover) != null ||
            box.stateStyle(core.BoxState.focus) != null ||
            box.stateStyle(core.BoxState.pressed) != null);

    Widget result = content;

    if (link) {
      assert(
        _open != null || box.onTap != null,
        'Unibox: "${destination.url}" is a link, but no FlutterLinkScope is '
        'above it and the box has no onTap, so pressing it does nothing. Wrap the '
        'tree in a FlutterLinkScope(open: ...) or give the Box an onTap callback.',
      );

      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _activate(box),
        onLongPress: interactive ? box.onLongPress : null,
        onTapDown: interactive ? _handleTapDown : null,
        onTapUp: interactive ? (TapUpDetails _) => _setPressed(false) : null,
        onTapCancel: interactive ? () => _setPressed(false) : null,
        child: result,
      );
    } else if (box.onTap != null ||
        box.onLongPress != null ||
        box.onTapDown != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: interactive ? box.onTap : null,
        onLongPress: interactive ? box.onLongPress : null,
        onTapDown: interactive ? _handleTapDown : null,
        onTapUp: interactive ? (TapUpDetails _) => _setPressed(false) : null,
        onTapCancel: interactive ? () => _setPressed(false) : null,
        child: result,
      );
    }

    if (focusable) {
      result = Focus(
        focusNode: _focusNode,
        // The box describes its own focus to a reader; a second description here
        // would be a node of its own and split the control in two.
        includeSemantics: false,
        onFocusChange: _setFocused,
        onKeyEvent: _handleKeyEvent,
        child: result,
      );
    }

    if (interactive || link || tracksState) {
      result = MouseRegion(
        cursor: interactive || link
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: tracksState
            ? (PointerEnterEvent event) => _setHovered(true)
            : null,
        onExit: tracksState
            ? (PointerExitEvent event) => _setHovered(false)
            : null,
        child: result,
      );
    }

    // A decoration takes no pointer, so the hover, the cursor and the press reach the control
    // under it — the web writes the same thing as `pointer-events: none`. A box that says it
    // does take one becomes a target of its own, where CSS would write `auto`.
    final bool? capturesPointer = box.capturesPointer;
    if (capturesPointer == false) {
      result = IgnorePointer(child: result);
    } else if (capturesPointer == true && !interactive && !link) {
      result = Listener(behavior: HitTestBehavior.opaque, child: result);
    }

    return _describeToSemantics(result, box);
  }

  /// Runs what a press of [box] does: its own handler, or its destination.
  ///
  /// One function for the pointer and for the keyboard, so that a control cannot answer
  /// one and be dead to the other. The handler wins over the opener, which is the rule a
  /// web renderer states: a press the tree answers does not also load the page it names.
  void _activate(core.Box box) {
    final core.TapCallback? onTap = box.onTap;

    if (onTap != null) {
      onTap();
    } else if (box is core.LinkNode) {
      _open?.call(box.url);
    }
  }

  /// Activates the box from the keyboard.
  ///
  /// Enter and Space are what a button does everywhere: Enter fires on the way down,
  /// Space on the way up, and both show the pressed state in between. A link is the
  /// exception, and on both targets: `Enter` opens it and `Space` does nothing, because
  /// that is what a browser does with an `<a href>` and a Flutter that disagreed would be
  /// the drift this model exists to prevent.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final core.Box box = widget.box;
    final LogicalKeyboardKey key = event.logicalKey;
    final bool link = box.enabled && box is core.LinkNode;
    final bool isActivationKey =
        key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space;

    if (!isActivationKey || (!box.isInteractive && !link)) {
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.space && !box.isInteractive) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      _setPressed(true);
      if (key == LogicalKeyboardKey.enter) {
        _activate(box);
      }
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      _setPressed(false);
      if (key == LogicalKeyboardKey.space) {
        _activate(box);
      }
    }

    return KeyEventResult.handled;
  }

  /// The Flutter role of a box's [semantics], or `null` when Flutter names it as a flag instead.
  ///
  /// Only four are named: a tab, the set it belongs to, and the two kinds of bar — Flutter has a
  /// name for a bar with a figure (`progressBar`) and for one without (`loadingSpinner`), while
  /// ARIA has the single `progressbar` and states the figure only when there is one. The rest are
  /// announced by the flags below — `button`, `link`, `header`, `checked`, `toggled` — which is
  /// what a screen reader listens for.
  SemanticsRole? _roleOf(core.BoxSemantics? semantics) {
    if (semantics == null) {
      return null;
    }

    return switch (semantics.role) {
      core.BoxRole.tab => SemanticsRole.tab,
      core.BoxRole.tablist => SemanticsRole.tabBar,
      core.BoxRole.progressBar =>
        semantics.progress == null
            ? SemanticsRole.loadingSpinner
            : SemanticsRole.progressBar,
      _ => null,
    };
  }

  /// The Flutter role of [element], or `null` when Flutter has no counterpart.
  ///
  /// Flutter's accessibility tree has no landmarks: a screen reader on a phone
  /// navigates by headings and reading order, not by `main` or `nav`, so those
  /// elements say something only a browser can pass on. The three Flutter does have
  /// a role for are the ones where the structure is also about content — a list, its
  /// items, and a form — and those become the matching `SemanticsRole`.
  SemanticsRole? _semanticsRole(core.BoxElement element) {
    return switch (element) {
      core.BoxElement.ul || core.BoxElement.ol => SemanticsRole.list,
      core.BoxElement.li => SemanticsRole.listItem,
      core.BoxElement.form => SemanticsRole.form,
      _ => null,
    };
  }

  /// Describes [content] to assistive technologies.
  ///
  /// A plain enabled container is left untouched: an extra `Semantics` node on
  /// every box would only make the tree harder to read. A box with a description
  /// or a disabled state gets one, and so does a focusable box, which needs the
  /// focused flag to be announced — and so does one with a long press, because a
  /// long press is an *action*: Flutter's own `InkWell` hands it to a reader the same
  /// way, and without it a "hold to delete" row is a control a screen reader cannot
  /// find. The web has no equivalent action, which is why `Box.onLongPress` is
  /// documented there as a pointer affordance.
  Widget _describeToSemantics(Widget content, core.Box box) {
    final core.BoxSemantics? semantics = box.semantics;
    final bool link = box is core.LinkNode;
    final bool focusable = box.isFocusable && box.enabled;
    final core.LongPressCallback? longPress = box.enabled
        ? box.onLongPress
        : null;

    if (semantics == null && box.enabled && longPress == null && !link) {
      return content;
    }

    final core.BoxRole role = semantics?.role ?? core.BoxRole.none;
    final bool? checked = semantics?.checked;
    final String? label = semantics?.label;
    // A figure, and the range it sits in. Flutter reads the three as text, and its own check in
    // debug refuses a bar that states the role without them.
    final core.BoxProgress? progress = role == core.BoxRole.progressBar
        ? semantics?.progress
        : null;

    return Semantics(
      container: semantics != null || longPress != null || link,
      // A label replaces the contents, so the accessible name cannot drift
      // away from what the screen reader reads.
      excludeSemantics: label != null,
      // A destination is a link whatever role a component gave it: the web has no role
      // attribute to write on an `<a href>`, and a reader that heard "button" here and
      // "link" there would be reading two different trees.
      button: role == core.BoxRole.button && !link,
      link: link || role == core.BoxRole.link,
      header: role == core.BoxRole.heading,
      checked: role == core.BoxRole.checkbox ? checked : null,
      // A switch is on or off, and so is a toggle button: Flutter states both with
      // `toggled`, and the web with `aria-checked` and `aria-pressed` respectively. A
      // link is neither, for the same reason it announces no button.
      toggled: link
          ? null
          : (role == core.BoxRole.switch_ ? checked : semantics?.pressed),
      label: label,
      // The figure a bar has reached, and the ends of its range. A reader hears "42% complete,
      // progress bar" — the name, then the value, then the role.
      value: progress == null ? null : '${progress.value}',
      minValue: progress == null ? null : '${progress.min}',
      maxValue: progress == null ? null : '${progress.max}',
      enabled: box.enabled,
      focusable: focusable,
      focused: focusable ? _focused : null,
      // A reader can move the focus here, which is what a native control offers and
      // what the `Focus` widget above no longer states for it.
      onFocus: focusable ? _focusNode.requestFocus : null,
      // A tab and its set are roles Flutter has its own names for, and it checks that a tab lives in
      // a tab bar: taking the element's role first would have hidden that from it.
      role:
          _roleOf(semantics) ??
          _semanticsRole(semantics?.element ?? core.BoxElement.div),
      expanded: semantics?.expanded,
      // `aria-current` has no Flutter counterpart; the closest thing a phone
      // reader understands is that this box is the selected item of a set.
      selected:
          semantics?.selected ?? (semantics?.current == null ? null : true),
      hidden: semantics?.hidden ?? false,
      liveRegion: semantics?.liveRegion ?? false,
      onLongPress: longPress,
      child: content,
    );
  }

  /// Whether a child of this box names a width threshold, which makes this box the
  /// one that threshold measures.
  bool get _holdsThreshold => widget.box.children.any(
    (core.UINode child) =>
        child is core.Box && !child.computedStyle.isVisibleEverywhere,
  );

  /// [content] with the whole box gone when this width does not draw it.
  ///
  /// `maintainState` keeps the subtree alive, so a box a wider width draws again
  /// comes back with the state it had, and a hidden box takes no room, exactly like
  /// the `display: none` the web renderer writes.
  Widget _visibleEverywhere(Widget content, core.BoxStyle style) {
    if (style.isVisibleEverywhere) {
      return content;
    }

    return Visibility(
      visible: style.isShownAt(widget.availableWidth ?? double.infinity),
      maintainState: true,
      child: content,
    );
  }

  /// The style of [box] for the states it is in right now.
  ///
  /// States stack the way CSS pseudo classes do: the hovered tokens are laid
  /// over the resting style, then the focus and the press tokens, so a pressed
  /// hovered box keeps both.
  core.BoxStyle _resolvedStyle(core.Box box) {
    if (!box.enabled) {
      return box.computedStyleFor(core.BoxState.disabled);
    }

    core.BoxStyle style = box.computedStyle;

    if (_hovered) {
      style = style.merge(box.stateStyle(core.BoxState.hover));
    }
    if (_focused) {
      style = style.merge(box.stateStyle(core.BoxState.focus));
    }
    if (_pressed) {
      style = style.merge(box.stateStyle(core.BoxState.pressed));
    }

    return style;
  }

  void _setHovered(bool hovered) {
    if (_hovered == hovered) {
      return;
    }

    setState(() {
      _hovered = hovered;
    });

    widget.box.onHover?.call(hovered);
  }

  void _setFocused(bool focused) {
    if (_focused == focused) {
      return;
    }

    setState(() {
      _focused = focused;
    });
  }

  /// Reports the press to the tree, then marks the box as pressed.
  ///
  /// The event is what an effect that starts at the pointer needs: where the press
  /// landed inside the box, and what pressed it.
  void _handleTapDown(TapDownDetails details) {
    _setPressed(true);

    final core.TapDownCallback? onTapDown = widget.box.onTapDown;
    if (onTapDown == null) {
      return;
    }

    onTapDown(
      core.BoxTapEvent(
        position: core.BoxPoint(
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        pointer: toPointerKind(details.kind),
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }

    setState(() {
      _pressed = pressed;
    });
  }
}

/// Paints a box's shadows the way CSS paints them: outside the border box, never through it.
///
/// An outer `box-shadow` is drawn *as if the border box were opaque* and clipped to the
/// outside of it, which is why a hairline — `BoxShadow(offsetY: 1, blurRadius: 0)` on a row
/// that has no fill of its own — is one pixel on the web. `DecoratedBox` paints the shadow
/// as a second shape behind the box instead, so a box with no background showed the whole
/// rectangle in the shadow's colour: the tab bar of the catalogue came out as a filled bar
/// the height of its own tabs.
///
/// The clip is the complement of the box's outline: one path with two subpaths and the
/// even-odd rule is everything the shadow may reach.
final class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter(this.decoration);

  /// The decoration whose `boxShadow` is painted.
  final BoxDecoration decoration;

  @override
  void paint(Canvas canvas, Size size) {
    final List<BoxShadow> shadows = decoration.boxShadow ?? const <BoxShadow>[];
    final Rect rect = Offset.zero & size;
    final RRect box = _outline(decoration, rect);
    Rect bounds = rect;

    for (final BoxShadow shadow in shadows) {
      bounds = bounds.expandToInclude(
        box
            .inflate(shadow.spreadRadius)
            .shift(shadow.offset)
            .outerRect
            // A blurred shadow reaches past the shape it was cast from, and a layer that
            // clipped it would cut the soft edge off.
            .inflate(shadow.blurRadius * 2),
      );
    }

    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(bounds)
          ..addRRect(box),
      );

    for (final BoxShadow shadow in shadows) {
      canvas.drawRRect(
        box.inflate(shadow.spreadRadius).shift(shadow.offset),
        shadow.toPaint(),
      );
    }

    canvas.restore();
  }

  /// The outline [decoration] paints inside [rect].
  ///
  /// The renderer builds a `BoxDecoration` with a plain `BorderRadius`, so resolving the
  /// geometry needs no writing direction.
  RRect _outline(BoxDecoration decoration, Rect rect) {
    if (decoration.shape == BoxShape.circle) {
      return RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.shortestSide / 2),
      );
    }

    final BorderRadiusGeometry? radius = decoration.borderRadius;

    return radius == null
        ? RRect.fromRectAndRadius(rect, Radius.zero)
        : radius.resolve(TextDirection.ltr).toRRect(rect);
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      oldDelegate.decoration != decoration;
}

/// Interpolates a [core.BoxTransform] part by part.
///
/// `Matrix4Tween` would interpolate the composed matrices, and a box that only
/// turns would then shrink through the middle of the animation; CSS interpolates
/// the transform functions one by one, and so does this.
final class _BoxTransformTween extends Tween<core.BoxTransform> {
  _BoxTransformTween({super.begin, super.end});

  @override
  core.BoxTransform lerp(double t) =>
      core.BoxTransform.lerp(begin ?? end!, end ?? begin!, t);
}

/// How one look group of a box is animated: over what, and with which curve.
///
/// The curve is an `Interval` when the look waits for another one to settle, which
/// is how a delay is expressed without a controller.
typedef _Timing = ({Duration duration, Curve curve});

/// A bar drawn over its viewport at the edge it pins to.
///
/// It takes the whole width of the viewport and the height its own content asks for, and
/// paints at the place the scroll offset puts it. Painting rather than rebuilding is what
/// makes the pin cheap: a scroll asks the layer to repaint, the bar's own subtree is built
/// once, and a field or a menu inside it keeps its state while it is being carried around.
///
/// The height is measured rather than stated, which is what lets a bar whose content wraps
/// pin: the slot it keeps in the flow reads [height] back, so a filter row that takes a
/// second line on a narrow window is as tall as the label it could not fit.
///
/// The slot the bar keeps in the flow is a [RenderObject] of its own, and the bar reads
/// its position from it in [RenderBox.performLayout] — after the flow has been laid out and
/// before anything is painted, so the first frame is drawn where the bar belongs.
class _PinnedBar extends SingleChildRenderObjectWidget {
  const _PinnedBar({
    super.key,
    required this.scroll,
    required this.pin,
    required this.slot,
    required this.inset,
    required super.child,
  });

  /// The scroll offset the bar follows.
  ///
  /// The controller rather than its position: a bar is built before the viewport it
  /// belongs to is, so the position it will follow does not exist yet at that moment.
  final ScrollController scroll;

  /// The edge it comes to rest at.
  final core.BoxPin pin;

  /// The slot it keeps in the flow, whose position is where it settles back to.
  final GlobalKey slot;

  /// The room it keeps from the edge while it is pinned.
  final double inset;

  @override
  _RenderPinnedBar createRenderObject(BuildContext context) =>
      _RenderPinnedBar(scroll, pin, slot, inset);

  @override
  void updateRenderObject(BuildContext context, _RenderPinnedBar renderObject) {
    renderObject
      ..scroll = scroll
      ..pin = pin
      ..slot = slot
      ..inset = inset;
  }
}

/// Where a [_PinnedBar] paints: the layout of a box, the geometry of a sticky one.
class _RenderPinnedBar extends RenderProxyBox {
  _RenderPinnedBar(this._scroll, this._pin, this._slot, this._inset);

  ScrollController _scroll;
  core.BoxPin _pin;
  GlobalKey _slot;
  double _inset;

  /// The height the bar measured for itself in the last layout, which is the room its slot
  /// keeps in the flow.
  double _height = 0;

  set scroll(ScrollController value) {
    if (identical(value, _scroll)) {
      return;
    }

    if (attached) {
      _scroll.removeListener(_scrollChanged);
      value.addListener(_scrollChanged);
    }

    _scroll = value;
    markNeedsLayout();
  }

  set pin(core.BoxPin value) {
    if (value == _pin) {
      return;
    }

    _pin = value;
    markNeedsLayout();
  }

  set slot(GlobalKey value) {
    if (identical(value, _slot)) {
      return;
    }

    _slot = value;
    markNeedsLayout();
  }

  /// The height the bar laid itself out at, which is the room it keeps in the flow.
  ///
  /// Read by the slot the flow holds open for it, in the same layout pass and after this
  /// bar: the layer lays its children out in reverse for exactly this reason.
  double get height => _height;

  set inset(double value) {
    if (value == _inset) {
      return;
    }

    _inset = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scroll.addListener(_scrollChanged);
  }

  @override
  void detach() {
    _scroll.removeListener(_scrollChanged);
    super.detach();
  }

  /// Redraws the bar where the offset now puts it.
  ///
  /// A bar that moved is also a rectangle a screen reader has to be told about, and
  /// marking both is what keeps the announced box where the painted one is. With no
  /// semantics owner — the ordinary case — the second call is a flag check.
  void _scrollChanged() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    final BoxConstraints constraints = this.constraints;

    if (child != null) {
      // The bar keeps the width the viewport hands it — a viewport that is itself unconstrained
      // across leaves the bar its own width rather than an infinity no box can be laid out in —
      // and it is as tall as its own content asks. Measuring it is what the slot in the flow
      // reads, so a bar that wraps needs no stated height and no second build to learn one.
      child.layout(
        BoxConstraints(
          minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
          maxWidth: constraints.hasBoundedWidth
              ? constraints.maxWidth
              : double.infinity,
        ),
        parentUsesSize: true,
      );

      _height = child.size.height;
    }

    // The layer fills the viewport, and takes the bar's own height where the viewport was
    // not given an end to fill.
    size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : 0,
        constraints.hasBoundedHeight ? constraints.maxHeight : _height,
      ),
    );
  }

  /// The place the bar is painted, in this layer's coordinates.
  ///
  /// At rest it is where the flow put it. Once the content would have carried it past the
  /// edge it named, it keeps that edge's distance, and it goes no further than the box it
  /// is drawn in allows — the box a browser keeps a sticky element inside, which is why a
  /// bar that has nothing after it never comes away from its slot.
  ///
  /// Read when the bar is painted rather than once per layout: a scroll repaints without
  /// laying anything out, and the place a bar belongs is a fact about the scroll offset.
  double get _top {
    if (!_scroll.hasClients) {
      return 0;
    }

    final ScrollPosition position = _scroll.position;

    if (!position.hasViewportDimension || !position.hasContentDimensions) {
      return 0;
    }

    final double viewport = position.viewportDimension;
    final double scroll = position.pixels;
    final double edge = _pin == core.BoxPin.start
        ? _inset
        : viewport - _inset - _height;
    final double at = _slotTop ?? edge;

    if (_pin == core.BoxPin.start) {
      // It is never lifted above its slot, and never past the end of the content.
      final double end = position.maxScrollExtent + viewport - scroll - _height;

      return math.min(math.max(at, edge), end);
    }

    // The end edge is the mirror of the start one: never pushed below its slot, never
    // above the start of the content.
    return math.max(math.min(at, edge), -scroll);
  }

  /// Where the slot sits right now, in this layer's coordinates: where the bar would be
  /// if it did not pin.
  ///
  /// Read from the slot's own place in the tree rather than counted from the children above
  /// it, which would mean laying them out here a second time. The scroll offset is part of
  /// the transform, so this is the position on screen and not the position in the content.
  double? get _slotTop {
    final RenderObject? found = _slot.currentContext?.findRenderObject();
    final RenderObject? layer = parent;

    if (found is! RenderBox || !found.attached || layer == null) {
      return null;
    }

    final RenderBox slot = found;

    return slot.localToGlobal(Offset.zero, ancestor: layer).dy -
        localToGlobal(Offset.zero, ancestor: layer).dy;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;

    if (child != null) {
      context.paintChild(child, offset + Offset(0, _top));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;

    if (child == null) {
      return false;
    }

    return result.addWithPaintOffset(
      offset: Offset(0, _top),
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  // The bar is laid out where the flow would have put it and painted elsewhere, so the
  // offset it was painted at is the one everything else has to be told about: the position
  // a test reads, the rectangle a screen reader announces, and the box a press lands in.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(Matrix4.translationValues(0, _top, 0));
  }
}

/// The content of a box that holds pinned bars: the flow, with the bars layered over it.
///
/// A `Stack` would almost do, and does not, for one reason: a stack lays its children out in
/// the order it paints them, and this layer needs the reverse. The slot a bar keeps in the
/// flow is the height the bar laid itself out at, so the bars have to be laid out *before*
/// the flow that reads them — and painted *after* it, because a bar covers the content that
/// scrolls under it.
class _PinnedLayer extends MultiChildRenderObjectWidget {
  const _PinnedLayer({required super.children});

  @override
  _RenderPinnedLayer createRenderObject(BuildContext context) =>
      _RenderPinnedLayer();
}

/// Where a child of a [_PinnedLayer] sits, which is nowhere: every child fills the layer.
final class _PinnedLayerData extends ContainerBoxParentData<RenderBox> {}

class _RenderPinnedLayer extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PinnedLayerData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PinnedLayerData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PinnedLayerData) {
      child.parentData = _PinnedLayerData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() {
    final Size extent = constraints.biggest;
    final BoxConstraints tight = BoxConstraints.tight(extent);

    // The flow is the first child and the bars follow it, which is the order they are painted
    // in; the order they are laid out in is the reverse, so the slot a bar leaves in the flow
    // is filled with a height this pass measured rather than the one the pass before it did.
    final List<RenderBox> ordered = <RenderBox>[];
    RenderBox? child = firstChild;

    while (child != null) {
      ordered.add(child);
      child = childAfter(child);
    }

    for (final RenderBox each in ordered.reversed) {
      // `parentUsesSize` on every one of them: a bar that grows its content has to relayout
      // the flow that keeps its room, and a slot is read from a bar, not owned by it.
      each.layout(tight, parentUsesSize: true);
    }

    size = extent;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A box painted under the look a fold has reached, in the viewport that scrolls it.
///
/// The layer paints; it does not rebuild. The decoration, the opacity and the transform are
/// interpolated when the box is painted, from how far it has travelled out of its viewport, so
/// a scroll costs a repaint of one layer and the box's children are built once. That is the
/// whole reason a fold may not move a layout: a frame of it is a look, and a look is a paint.

/// The room a pinned bar keeps in the flow, read from the bar's own layout.
///
/// A bar with no stated height is as tall as its content, which nobody knows until it has
/// been laid out: this is the widget that turns that measurement into the space the flow
/// holds open, so nothing below the bar moves when it is away at the edge. The number is read
/// from the bar's render object rather than passed through a callback, because a callback
/// would mean a rebuild and a frame drawn at the height of the frame before.
class _PinnedSlot extends LeafRenderObjectWidget {
  const _PinnedSlot({required this.bar, super.key});

  /// The key of the bar this slot keeps the room for.
  final GlobalKey bar;

  @override
  _RenderPinnedSlot createRenderObject(BuildContext context) =>
      _RenderPinnedSlot(bar);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPinnedSlot renderObject,
  ) {
    renderObject.bar = bar;
  }
}

class _RenderPinnedSlot extends RenderBox {
  _RenderPinnedSlot(this._bar);

  GlobalKey _bar;

  set bar(GlobalKey value) {
    if (identical(value, _bar)) {
      return;
    }

    _bar = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final RenderObject? found = _bar.currentContext?.findRenderObject();
    final double height = found is _RenderPinnedBar ? found.height : 0;

    // A slot keeps the room and no width: it sits in a column, where the cross axis is the
    // box's own business.
    size = constraints.constrain(Size(0, height));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => Size.zero;

  // The slot draws nothing — the bar it stands for is painted by the layer — so it takes no
  // press either: a press where the bar came from belongs to the content underneath it.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}

/// A line that is as tall — or as wide — as its tallest item when nothing gave it an end.
///
/// A stretch is CSS's `align-items: stretch`, and the half of it that Flutter's own
/// `CrossAxisAlignment.stretch` cannot express is where the line's extent comes from: a
/// browser makes the line as tall as its tallest item and fills the rest to it, so a row
/// inside a column that scrolls has a height although nothing above it stated one. A flex
/// handed an endless cross axis refuses instead — "BoxConstraints forces an infinite height"
/// — because it is asked to fill an extent that does not exist yet.
///
/// So the line is laid out twice when it has no end: once as it is, to find the tallest item,
/// and once tight to that extent, which is the extent the items then fill. A line that *was*
/// given an end — a row in a box that states its height, a `flex` child of a column — is laid
/// out once and costs nothing, which is every stretch that already worked.
class _StretchedLine extends SingleChildRenderObjectWidget {
  const _StretchedLine({required this.across, required super.child});

  /// The axis the items fill: the cross axis of the line, which is the axis of the extent
  /// that has to be measured.
  final Axis across;

  @override
  _RenderStretchedLine createRenderObject(BuildContext context) =>
      _RenderStretchedLine(across);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStretchedLine renderObject,
  ) {
    renderObject.across = across;
  }
}

class _RenderStretchedLine extends RenderProxyBox {
  _RenderStretchedLine(this._across);

  Axis _across;

  set across(Axis value) {
    if (value == _across) {
      return;
    }

    _across = value;
    markNeedsLayout();
  }

  bool _hasEnd(BoxConstraints constraints) => _across == Axis.vertical
      ? constraints.hasBoundedHeight
      : constraints.hasBoundedWidth;

  @override
  void performLayout() {
    final RenderBox? child = this.child;

    if (child == null) {
      size = constraints.smallest;

      return;
    }

    if (_hasEnd(constraints)) {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);

      return;
    }

    // No end to fill: the line is as tall as the tallest item, which is what a browser
    // resolves `align-items: stretch` against. Measured on a first pass and filled on a
    // second, so the items are handed a number rather than an infinity.
    final BoxConstraints unbounded = _across == Axis.vertical
        ? constraints.copyWith(maxHeight: double.infinity)
        : constraints.copyWith(maxWidth: double.infinity);

    child.layout(unbounded, parentUsesSize: true);

    final double extent = _across == Axis.vertical
        ? child.size.height
        : child.size.width;
    final BoxConstraints tight = _across == Axis.vertical
        ? constraints.copyWith(minHeight: extent, maxHeight: extent)
        : constraints.copyWith(minWidth: extent, maxWidth: extent);

    child.layout(tight, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}

/// Fills the room it is offered on one axis, and asks for nothing when there is none.
///
/// This is the other half of a stretch: an item whose cross size is `auto` fills the line,
/// and the line is as tall as its tallest item. `SizedBox(height: double.infinity)` was the
/// earlier spelling and could not express the second half — an infinity inside a line that
/// has no end is the constraint Flutter refuses, and it is also a number an intrinsic pass
/// cannot measure, so the line could not be measured before it was filled.
///
/// The fill is only ever as big as the room offered: a line measured at 300 fills 300, and a
/// line with no end at all leaves the child at its own size, which is what makes the two-pass
/// layout of [_StretchedLine] possible.
class _FillCross extends SingleChildRenderObjectWidget {
  const _FillCross({required this.across, required super.child});

  /// The axis to fill.
  final Axis across;

  @override
  _RenderFillCross createRenderObject(BuildContext context) =>
      _RenderFillCross(across);

  @override
  void updateRenderObject(BuildContext context, _RenderFillCross renderObject) {
    renderObject.across = across;
  }
}

class _RenderFillCross extends RenderProxyBox {
  _RenderFillCross(this._across);

  Axis _across;

  set across(Axis value) {
    if (value == _across) {
      return;
    }

    _across = value;
    markNeedsLayout();
  }

  /// The constraints that fill [available] on this axis, or `null` when there is nothing to
  /// fill because the axis has no end.
  BoxConstraints? _fill(BoxConstraints available) {
    if (_across == Axis.vertical) {
      return available.hasBoundedHeight
          ? BoxConstraints.tightFor(height: available.maxHeight)
                .enforce(available)
          : null;
    }

    return available.hasBoundedWidth
        ? BoxConstraints.tightFor(width: available.maxWidth).enforce(available)
        : null;
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;

    if (child == null) {
      size = constraints.smallest;

      return;
    }

    child.layout(_fill(constraints) ?? constraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}

class _FoldedBox extends SingleChildRenderObjectWidget {
  const _FoldedBox({
    required this.position,
    required this.fold,
    required this.resting,
    required this.folded,
    required super.child,
  });

  /// The scroll the fold follows, which is the nearest one above the box.
  final ScrollPosition position;

  /// The fold: which looks move, how far it takes, and how they ease.
  final core.BoxFold fold;

  /// The look the box has at rest.
  final core.BoxStyle resting;

  /// The look it has once it has left.
  final core.BoxStyle folded;

  @override
  _RenderFoldedBox createRenderObject(BuildContext context) => _RenderFoldedBox(
    position,
    fold,
    resting,
    folded,
    Directionality.maybeOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderFoldedBox renderObject) {
    renderObject
      ..position = position
      ..fold = fold
      ..resting = resting
      ..folded = folded
      ..textDirection = Directionality.maybeOf(context);
  }
}

/// Where a [_FoldedBox] paints, and how far into the fold it is.
class _RenderFoldedBox extends RenderProxyBox {
  _RenderFoldedBox(
    this._position,
    this._fold,
    this._resting,
    this._folded,
    this._textDirection,
  );

  ScrollPosition _position;
  core.BoxFold _fold;
  core.BoxStyle _resting;
  core.BoxStyle _folded;
  TextDirection? _textDirection;

  set position(ScrollPosition value) {
    if (identical(value, _position)) {
      return;
    }

    if (attached) {
      _position.removeListener(_scrollChanged);
      value.addListener(_scrollChanged);
    }

    _position = value;
    markNeedsPaint();
  }

  set fold(core.BoxFold value) {
    if (value == _fold) {
      return;
    }

    _fold = value;
    markNeedsPaint();
  }

  set resting(core.BoxStyle value) {
    if (value == _resting) {
      return;
    }

    _resting = value;
    markNeedsPaint();
  }

  set folded(core.BoxStyle value) {
    if (value == _folded) {
      return;
    }

    _folded = value;
    markNeedsPaint();
  }

  set textDirection(TextDirection? value) {
    if (value == _textDirection) {
      return;
    }

    _textDirection = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position.addListener(_scrollChanged);
  }

  @override
  void detach() {
    _position.removeListener(_scrollChanged);
    super.detach();
  }

  /// Repaints the box under the look the scroll offset now asks for.
  void _scrollChanged() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// How far into the fold the box is, from where it sits in its viewport.
  ///
  /// The quantity a browser takes from `view()`: the box's leading edge has travelled from the
  /// scrollport's start edge to a whole box above it, which is zero at rest and one once the box
  /// has gone. A box that has never reached the top, or a page with no viewport at all, reads as
  /// the resting look rather than as a fold that has arrived.
  double get _progress {
    final RenderObject? found = RenderAbstractViewport.maybeOf(this);

    if (found is! RenderBox || !found.attached || !attached || size.isEmpty) {
      return 0;
    }

    final double viewport = found.size.height;

    if (viewport <= 0) {
      return 0;
    }

    final double top = localToGlobal(Offset.zero, ancestor: found).dy;
    final double left = (-top / size.height).clamp(0.0, 1.0);

    return toCurve(_fold.curve).transform(_fold.progressAt(left));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double t = _progress;
    final BoxDecoration? decoration = _decorationAt(t);

    if (decoration != null) {
      // A decoration paints through a painter of its own: `BoxDecoration` has no `paint`, and
      // the painter is the one thing that knows how a shape is drawn at a size.
      final BoxPainter painter = decoration.createBoxPainter();

      painter.paint(
        context.canvas,
        offset,
        ImageConfiguration(size: size, textDirection: _textDirection),
      );
      painter.dispose();
    }

    final RenderBox? child = this.child;

    if (child == null) {
      return;
    }

    final double opacity = lerpDouble(
      (_resting.opacity ?? 1).clamp(0.0, 1.0),
      (_folded.opacity ?? 1).clamp(0.0, 1.0),
      t,
    )!;
    final Matrix4? matrix = _matrixAt(t);

    void paintChild(PaintingContext context, Offset offset) {
      if (matrix == null) {
        context.paintChild(child, offset);
        return;
      }

      context.pushTransform(
        false,
        offset,
        matrix,
        (PaintingContext context, Offset offset) =>
            context.paintChild(child, offset),
      );
    }

    if (opacity >= 1) {
      paintChild(context, offset);
      return;
    }

    context.pushOpacity(offset, (opacity * 255).round(), paintChild);
  }

  /// The decoration at [t], or `null` when the fold moves none of it.
  BoxDecoration? _decorationAt(double t) {
    final Set<core.BoxProperty> looks = _fold.looks;
    final bool moves =
        looks.contains(core.BoxProperty.backgroundColor) ||
        looks.contains(core.BoxProperty.borderColor) ||
        looks.contains(core.BoxProperty.borderRadius) ||
        looks.contains(core.BoxProperty.shadows);
    final BoxDecoration? from = toDecoration(_resting);

    if (!moves) {
      return from;
    }

    return BoxDecoration.lerp(from, toDecoration(_folded) ?? from, t);
  }

  /// The transform at [t], or `null` when the box is not moved.
  ///
  /// The matrix is applied about the box's centre, as a resting `transform` is, and the fraction
  /// of the box's own size is added as the translation a `FractionalTranslation` would make.
  Matrix4? _matrixAt(double t) {
    if (!_fold.looks.contains(core.BoxProperty.transform)) {
      return null;
    }

    final core.BoxTransform value = core.BoxTransform.lerp(
      _resting.transform ?? const core.BoxTransform(),
      _folded.transform ?? const core.BoxTransform(),
      t,
    );
    final Matrix4 matrix = toMatrix4(value);

    if (value.fractionX != 0 || value.fractionY != 0) {
      matrix.multiply(
        Matrix4.translationValues(
          value.fractionX * size.width,
          value.fractionY * size.height,
          0,
        ),
      );
    }

    final Offset centre = size.center(Offset.zero);

    return Matrix4.translationValues(centre.dx, centre.dy, 0)
      ..multiply(matrix)
      ..multiply(Matrix4.translationValues(-centre.dx, -centre.dy, 0));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;
    final Matrix4? matrix = _matrixAt(_progress);

    if (child == null) {
      return false;
    }

    if (matrix == null) {
      return child.hitTest(result, position: position);
    }

    // A box that is scaled is pressed where it is painted, which is what a resting transform
    // already does through the `Transform` widget.
    return child.hitTest(
      result,
      position: MatrixUtils.transformPoint(Matrix4.inverted(matrix), position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Matrix4? matrix = _matrixAt(_progress);

    if (matrix != null) {
      transform.multiply(matrix);
    }
  }
}

/// The scroll behaviour a box runs under: the host's, without its overscroll decoration.
///
/// A Material application wraps every scroll view in a `GlowingOverscrollIndicator` — a wash of
/// the primary colour, or a stretch of the content — and a browser draws nothing when a box is
/// pulled past its end. Keeping the glow would make the same tree look different on the two
/// targets for the one reason this library refuses everywhere else: the host's chrome is not the
/// tree's. Everything else is passed through, so the physics, the devices a drag may use and the
/// scrollbar stay the host's.
class _NoOverscrollGlow extends ScrollBehavior {
  const _NoOverscrollGlow(this._host);

  /// The behaviour the surrounding application installed.
  final ScrollBehavior _host;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      _host.getScrollPhysics(context);

  @override
  Set<PointerDeviceKind> get dragDevices => _host.dragDevices;

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      _host.getPlatform(context);

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => _host.buildScrollbar(context, child, details);

  /// No decoration at all: the box's content is the whole of what a pull past the end shows.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// The padding box of a box that draws a line: the box's content, cut square or round.
///
/// It is the region a browser clips an element's overflow to, and Flutter had none of its
/// own: a `ClipRect` cuts the whole box, so the last `line` pixels on every side — the ones
/// the border paints over — were the children's to paint, and a child that filled the box
/// covered the line where it met it. A chosen segment's fill broke the outline of the pill
/// around it and the tint of a hover lit a bar the browser never lights; both targets now
/// stop at the line.
///
/// The corner is the inside of the border's, which is the outer radius less the line, the
/// way CSS reduces an inner radius by the border's width. A line wider than half the box has
/// no content left to clip to, so the inset stops there rather than inverting the rectangle.
class _BorderBoxClipper extends CustomClipper<Path> {
  const _BorderBoxClipper({required this.line, required this.radius});

  /// The width of the border painted on the box's edge.
  final double line;

  /// The radius the box's outer corner is drawn with.
  final double radius;

  @override
  Path getClip(Size size) {
    final double inset = math.min(line, size.shortestSide / 2);
    final RRect inner = RRect.fromRectAndRadius(
      Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset),
      Radius.circular(math.max(0, radius - inset)),
    );

    return Path()..addRRect(inner);
  }

  @override
  bool shouldReclip(_BorderBoxClipper oldClipper) =>
      oldClipper.line != line || oldClipper.radius != radius;
}

/// Says that the box below is the child of a flex that stretches it across one axis.
///
/// A stretch cannot be expressed by handing the child a tight size: a tight constraint wins
/// over the child's own `width`, while a browser only stretches an item whose cross size is
/// `auto`. The flag therefore travels down instead of a constraint, the first box it reaches
/// uses it to fill its own cross axis when it states no size there, and it clears the flag for
/// what that box holds. It reaches the view of a stateful node for the same reason — the view
/// is the element the parent stretches — and a box that states its own size ignores it.
class _StretchedAcross extends InheritedWidget {
  /// Marks [child] as stretched by a flex that runs along [flexDirection], or clears the
  /// mark when [flexDirection] is `null`.
  const _StretchedAcross({required this.flexDirection, required super.child});

  /// The direction of the parent's flex, or `null` below the box the flag reached.
  final Axis? flexDirection;

  /// The axis of the flex that stretches the box being built, or `null` when the box is not
  /// the child of one.
  static Axis? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_StretchedAcross>()
      ?.flexDirection;

  @override
  bool updateShouldNotify(_StretchedAcross oldWidget) =>
      oldWidget.flexDirection != flexDirection;
}
