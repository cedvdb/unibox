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

  /// The page this box was last moved to, so a rebuild with the same page leaves the reader alone.
  int? _appliedPage;

  /// The slot each pinned band keeps in the flow, by the index of its child.
  ///
  /// A band is drawn over the viewport rather than in the flow, and the flow holds its
  /// room open with a box of the height the tree states for it. Where that slot is — which
  /// is where the band settles back to — is a fact only its own layout knows, and the band
  /// reads it from this key.
  final Map<int, GlobalKey> _slots = <int, GlobalKey>{};

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

  /// Slides a pager to the page the tree says it shows, when that is not where it already is.
  ///
  /// A page is a position and not a command, so the box moves only when the value differs from the
  /// one it last applied: a rebuild that states the same page leaves a reader mid-swipe alone, which
  /// is the difference between a description and a controller. It happens after the frame, because
  /// the extent of a page is the viewport's and that is only known once the box has been laid out.
  void _applyPage(core.BoxStyle style) {
    final int? page = style.page;

    if (page == null || page == _appliedPage) {
      return;
    }

    // The first application is a jump: a pager that slides into place on the frame it appears is a
    // flash, and the reader did not ask for the movement. Every later one is the press that asked.
    final bool first = _appliedPage == null;
    _appliedPage = page;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ScrollController? controller = _scroll;

      if (!mounted || controller == null || !controller.hasClients) {
        return;
      }

      final double target = page * controller.position.viewportDimension;

      if (first) {
        controller.jumpTo(target);

        return;
      }

      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
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

    // A link asks the host once, while an inherited widget can be read.
    _open = box.enabled && box is core.LinkNode
        ? FlutterLinkScope.maybeOf(context)
        : null;

    final List<core.Box> pinned = _pinnedBands(box, style);

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

    _applyPage(style);

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
          // the whole of it: a page is a child the size of the box, so the viewport's own
          // boundaries are the children's, and the two targets agree because CSS snaps to the
          // child's own `scroll-snap-align` edge.
          physics: style.snap == core.ScrollSnap.page
              ? const PageScrollPhysics()
              : null,
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
      if (onScroll != null) {
        // *Around* the scroll view: a notification travels up from the scrollable to its
        // ancestors, so a listener inside it hears nothing.
        content = NotificationListener<ScrollUpdateNotification>(
          // A scrollable nested in the content notifies this listener too, at a greater
          // depth: only this box's own viewport is reported, which is what the browser's
          // non-bubbling `scroll` event gives for free.
          onNotification: (ScrollUpdateNotification notification) {
            if (notification.depth == 0) {
              onScroll(notification.metrics.pixels);
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

    content = _applyDimensions(content, style);
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
      return DecoratedBox(decoration: decoration, child: child);
    }

    return TweenAnimationBuilder<Decoration>(
      // The first build paints the decoration as it is; every later one starts
      // from whatever the animation had reached, so a fast hover in and out of a
      // box does not snap back to the old look.
      tween: DecorationTween(begin: decoration, end: decoration),
      duration: timing.duration,
      curve: timing.curve,
      builder: (BuildContext context, Decoration value, Widget? inner) =>
          DecoratedBox(decoration: value, child: inner),
      child: child,
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

  /// Clips [child] to the box, rounded when the box has a corner radius.
  ///
  /// A plain `ClipRect` cuts square corners, while CSS clips an element with
  /// `overflow` to its `border-radius`: a rounded card that hides what sticks out
  /// would be rounded in the browser and square in Flutter. The radius is the one
  /// the box paints with, so the clip and the decoration can never disagree.
  Widget _clipTo(Widget child, core.BoxStyle style) {
    final core.BoxShape? shape = style.shape;

    if (shape != null) {
      return ClipPath(clipper: UniboxShapeClipper(shape), child: child);
    }

    final double? radius = style.borderRadius;

    if (radius == null || radius <= 0) {
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
  /// [slots] names the children that are drawn over the viewport instead of in the flow,
  /// with the height each keeps: the flow keeps their room, so nothing below them moves
  /// while they are pinned.
  ///
  /// A box without children still renders its flex container. It lays out
  /// nothing either way, but the web renderer marks every box as a flex
  /// container, so leaving the empty one out would make the two trees describe
  /// the same box differently.
  Widget _buildContent(
    core.Box box,
    core.BoxStyle style, {
    required double? availableWidth,
    Map<int, double>? slots,
  }) {
    final core.Axis direction = style.resolvedDirection;
    final double? gap = style.gap;
    final bool wrap = style.wrap ?? false;
    // A row of equal shares. It is never a wrapping box (validateTree reports the pair) and
    // never a column, so the only branch that has shares to lay out is the row's.
    final bool shares =
        !wrap &&
        (style.equalShares ?? false) &&
        direction == core.Axis.horizontal;

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

      final double? slot = slots?[index];

      children.add(
        slot == null
            ? _buildChild(
                box.children[index],
                direction,
                availableWidth: availableWidth,
                flexible: !wrap,
                share: shares,
              )
            : SizedBox(
                key: _slots.putIfAbsent(index, GlobalKey.new),
                height: slot,
              ),
      );
    }

    final core.CrossAlign crossAlign =
        style.crossAlign ?? core.CrossAlign.start;
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

    final CrossAxisAlignment crossAxisAlignment = toCrossAxisAlignment(
      crossAlign,
    );

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

      // Equal shares are the row's own width divided between the children, and a `Row`
      // only ever divides the width it is given. `IntrinsicWidth` is what gives it the
      // width the shares ask for — a flexible child reports its max intrinsic width, and the
      // row multiplies the largest of them by the flex factors, so the answer is the count
      // times the widest child, which is the same rule a browser writes as
      // `grid-auto-columns: minmax(0, 1fr)`. The constraints clamp it: a row with less room
      // than that gets the room it has, and every share is then an equal part of it — which
      // is where a label too long for its share starts ellipsising rather than widening the
      // row.
      return shares ? IntrinsicWidth(child: row) : row;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: uniboxTextBaseline,
      children: children,
    );
  }

  /// The content of the box inside its viewport.
  ///
  /// A box that holds a pinned band is laid out by [_buildPinnedContent]: a
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
  static List<core.Box> _pinnedBands(core.Box box, core.BoxStyle style) {
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
  /// A band drawn over the viewport is handed the whole width of it, tight, where a column
  /// hands a child the room it asks for and places it by the box's `crossAlign`. Only a
  /// stretched child wants the whole width; the rest are wrapped.
  Widget _aligned(Widget child, core.CrossAlign crossAlign) {
    final AlignmentGeometry? alignment = toBandAlignment(crossAlign);

    return alignment == null
        ? child
        : Align(alignment: alignment, child: child);
  }

  /// The content of a box that holds pinned bands: the flow it always had, with the
  /// bands drawn over it.
  ///
  /// A pinned band is lifted out of the flow and painted over the viewport at the edge it
  /// named, driven by the scroll offset of this box: it comes to rest at
  /// [core.BoxPin.start] or [core.BoxPin.end] once the content would have carried it past,
  /// and settles back into the flow when its slot comes up. That is what a browser states
  /// with `position: sticky`, and it is why the band paints above the content: a band drawn
  /// in the flow order it was written in would be painted over by the content that scrolls
  /// under it, and a browser only escapes that with the `z-index` it writes beside the
  /// position.
  ///
  /// The slot keeps the room the band takes — the height the tree states for it — so the
  /// children below it never move, which is the promise a pin makes. Laying the flow out
  /// exactly as before is the other half of it: `gap`, `crossAlign` and `mainAlign` stay a
  /// flex container's, so the trees that already exist are drawn as they were.
  Widget _buildPinnedContent(
    core.Box box,
    core.BoxStyle style, {
    required double? availableWidth,
  }) {
    final Map<int, double> slots = <int, double>{};
    final List<Widget> bands = <Widget>[];

    for (var index = 0; index < box.children.length; index++) {
      final core.UINode child = box.children[index];
      final core.Box? band = child is core.Box ? child : null;
      final core.BoxStyle? bandStyle = band?.computedStyle;
      final core.BoxPin? pin = bandStyle?.pin;
      final double? height = bandStyle?.height;

      // A band with no height of its own has no slot to hold open, so it stays in the
      // flow: `validateTree` reports it, and drawing it as an ordinary child is the one
      // answer both targets give for a pin they cannot honour.
      if (band == null || pin == null || height == null || !height.isFinite) {
        continue;
      }

      slots[index] = height;
      bands.add(
        _pinnedBand(
          _buildChild(band, core.Axis.vertical, availableWidth: availableWidth),
          scroll: _scroll,
          pin: pin,
          slot: _slots.putIfAbsent(index, GlobalKey.new),
          height: height,
          inset: bandStyle!.resolvedPinOffset,
          crossAlign: style.crossAlign ?? core.CrossAlign.start,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Filled rather than sized by its content: a stack hands a child loose
        // constraints, and a scroll view handed a loose height is as tall as the content
        // it was given, which is a viewport with nothing to scroll.
        Positioned.fill(
          child: SingleChildScrollView(
            scrollDirection: toAxis(style.resolvedDirection),
            controller: _scroll,
            child: _buildContent(
              box,
              style,
              availableWidth: availableWidth,
              slots: slots,
            ),
          ),
        ),
        ...bands,
      ],
    );
  }

  /// [content] under the look a fold paints.
  ///
  /// The resting look is where the fold starts and [core.BoxFold.to] is where it arrives; the
  /// layer paints the interpolation rather than rebuilding it, so a scroll asks for a repaint
  /// and the box's children are built once — the same reason the pinned band is a layer.
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

  /// [band] drawn at the edge it pins to, over the content that scrolls under it.
  ///
  /// The layer takes the whole viewport and paints the band at the place the scroll offset
  /// puts it, so a scroll repaints the band instead of rebuilding it: the subtree is built
  /// once and painted wherever the edge is, which is also what keeps the band's own
  /// subtree — a field, a menu — alive while it is being carried around.
  Widget _pinnedBand(
    Widget band, {
    required ScrollController? scroll,
    required core.BoxPin pin,
    required GlobalKey slot,
    required double height,
    required double inset,
    required core.CrossAlign crossAlign,
  }) {
    if (scroll == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: _PinnedBand(
        scroll: scroll,
        pin: pin,
        slot: slot,
        height: height,
        inset: inset,
        child: _aligned(band, crossAlign),
      ),
    );
  }

  /// Renders [node] and makes it flexible along the parent's `direction` when it
  /// declares a [core.BoxStyle.flex] factor or an infinite main dimension.
  ///
  /// [flexible] is off for the child of a wrapping box, which has no flex children: a
  /// `Wrap` lays each child out at its own size, so an `Expanded` in it is a Flutter
  /// error rather than a share. `validateTree` reports that tree instead.
  ///
  /// [share] is on for every child of a row of equal shares: the row measured them all and
  /// gave each one width, so each is expanded at one whatever its own tokens say — the
  /// share is the row's answer, and `validateTree` reports a `flex` or a width on a child
  /// that would state one. A child the width does not draw still takes no share, which is
  /// the `display: none` a browser gives it.
  Widget _buildChild(
    core.UINode node,
    core.Axis direction, {
    required double? availableWidth,
    bool flexible = true,
    bool share = false,
  }) {
    final Widget child = renderNode(node, availableWidth: availableWidth);

    if (node is! core.Box) {
      return share ? Expanded(child: child) : child;
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

    if (share) {
      return Expanded(child: child);
    }

    final double? mainSize = direction == core.Axis.horizontal
        ? childStyle.width
        : childStyle.height;
    final int? flex = childStyle.flex;
    final bool expands = mainSize == double.infinity;
    final bool hasFlex = flex != null && flex > 0;

    if (!expands && !hasFlex) {
      return child;
    }

    if (!flexible) {
      return child;
    }

    return Expanded(flex: hasFlex ? flex : 1, child: child);
  }

  /// Applies the fixed sizes, the aspect ratio and the min/max constraints of [style].
  Widget _applyDimensions(Widget content, core.BoxStyle style) {
    Widget result = content;

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
    // one: a share of a row, one tab of a bar. It wins over a stated size, as CSS does.
    if (style.widthFraction != null || style.heightFraction != null) {
      result = FractionallySizedBox(
        widthFactor: style.widthFraction,
        heightFactor: style.heightFraction,
        child: result,
      );
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

  /// The Flutter role of a box's [role], or `null` when Flutter names it as a flag instead.
  ///
  /// Only two are named: a tab and the set it belongs to. The rest are announced by the flags below
  /// — `button`, `link`, `header`, `checked`, `toggled` — which is what a screen reader listens for.
  SemanticsRole? _roleOf(core.BoxRole role) {
    return switch (role) {
      core.BoxRole.tab => SemanticsRole.tab,
      core.BoxRole.tablist => SemanticsRole.tabBar,
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
      enabled: box.enabled,
      focusable: focusable,
      focused: focusable ? _focused : null,
      // A reader can move the focus here, which is what a native control offers and
      // what the `Focus` widget above no longer states for it.
      onFocus: focusable ? _focusNode.requestFocus : null,
      // A tab and its set are roles Flutter has its own names for, and it checks that a tab lives in
      // a tab bar: taking the element's role first would have hidden that from it.
      role:
          _roleOf(role) ??
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

/// A band drawn over its viewport at the edge it pins to.
///
/// It lays out like any child of the drawing stack it sits in — the whole width of the
/// viewport, the height the tree states for it — and paints at the place the scroll offset
/// puts it. Painting rather than rebuilding is what makes the pin cheap: a scroll asks the
/// layer to repaint, the band's own subtree is built once, and a field or a menu inside it
/// keeps its state while it is being carried around.
///
/// The slot the band keeps in the flow is a [RenderObject] of its own, and the band reads
/// its position from it in [RenderBox.performLayout] — after the flow has been laid out and
/// before anything is painted, so the first frame is drawn where the band belongs.
class _PinnedBand extends SingleChildRenderObjectWidget {
  const _PinnedBand({
    required this.scroll,
    required this.pin,
    required this.slot,
    required this.height,
    required this.inset,
    required super.child,
  });

  /// The scroll offset the band follows.
  ///
  /// The controller rather than its position: a band is built before the viewport it
  /// belongs to is, so the position it will follow does not exist yet at that moment.
  final ScrollController scroll;

  /// The edge it comes to rest at.
  final core.BoxPin pin;

  /// The slot it keeps in the flow, whose position is where it settles back to.
  final GlobalKey slot;

  /// The height it keeps, in logical pixels, which is also the slot's.
  final double height;

  /// The room it keeps from the edge while it is pinned.
  final double inset;

  @override
  _RenderPinnedBand createRenderObject(BuildContext context) =>
      _RenderPinnedBand(scroll, pin, slot, height, inset);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPinnedBand renderObject,
  ) {
    renderObject
      ..scroll = scroll
      ..pin = pin
      ..slot = slot
      ..height = height
      ..inset = inset;
  }
}

/// Where a [_PinnedBand] paints: the layout of a box, the geometry of a sticky one.
class _RenderPinnedBand extends RenderProxyBox {
  _RenderPinnedBand(
    this._scroll,
    this._pin,
    this._slot,
    this._height,
    this._inset,
  );

  ScrollController _scroll;
  core.BoxPin _pin;
  GlobalKey _slot;
  double _height;
  double _inset;

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

  set height(double value) {
    if (value == _height) {
      return;
    }

    _height = value;
    markNeedsLayout();
  }

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

  /// Redraws the band where the offset now puts it.
  ///
  /// A band that moved is also a rectangle a screen reader has to be told about, and
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
      // The band keeps the width the viewport hands it and the height it states, which is
      // the room its slot holds in the flow; a viewport that is itself unconstrained across
      // leaves the band its own width rather than an infinity no box can be laid out in.
      child.layout(
        BoxConstraints.tightFor(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          height: _height,
        ),
        parentUsesSize: true,
      );
    }

    // The layer fills the viewport, and takes the band's own height where the viewport was
    // not given an end to fill.
    size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : 0,
        constraints.hasBoundedHeight ? constraints.maxHeight : _height,
      ),
    );
  }

  /// The place the band is painted, in this layer's coordinates.
  ///
  /// At rest it is where the flow put it. Once the content would have carried it past the
  /// edge it named, it keeps that edge's distance, and it goes no further than the box it
  /// is drawn in allows — the box a browser keeps a sticky element inside, which is why a
  /// band that has nothing after it never comes away from its slot.
  ///
  /// Read when the band is painted rather than once per layout: a scroll repaints without
  /// laying anything out, and the place a band belongs is a fact about the scroll offset.
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

  /// Where the slot sits right now, in this layer's coordinates: where the band would be
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

  // The band is laid out where the flow would have put it and painted elsewhere, so the
  // offset it was painted at is the one everything else has to be told about: the position
  // a test reads, the rectangle a screen reader announces, and the box a press lands in.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(Matrix4.translationValues(0, _top, 0));
  }
}

/// A box painted under the look a fold has reached, in the viewport that scrolls it.
///
/// The layer paints; it does not rebuild. The decoration, the opacity and the transform are
/// interpolated when the box is painted, from how far it has travelled out of its viewport, so
/// a scroll costs a repaint of one layer and the box's children are built once. That is the
/// whole reason a fold may not move a layout: a frame of it is a look, and a look is a paint.
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
