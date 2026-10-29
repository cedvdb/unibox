import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'keys.dart';
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

    Widget content = _holdsThreshold
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                _buildContent(box, style, availableWidth: constraints.maxWidth),
          )
        : _buildContent(box, style, availableWidth: null);

    _applyPage(style);

    final core.BoxTextStyle textStyle =
        style.textStyle ?? const core.BoxTextStyle();
    if (!textStyle.isEmpty) {
      content = _inheritTypography(context, content, textStyle);
    }

    if (style.overflow == core.Overflow.scroll) {
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
    content = _applyLook(content, style, box);
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
  Widget _applyLook(Widget child, core.BoxStyle style, core.Box box) {
    final core.BoxTransform? transform = style.transform;
    final double? opacity = style.opacity;

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
  /// A box without children still renders its flex container. It lays out
  /// nothing either way, but the web renderer marks every box as a flex
  /// container, so leaving the empty one out would make the two trees describe
  /// the same box differently.
  Widget _buildContent(
    core.Box box,
    core.BoxStyle style, {
    required double? availableWidth,
  }) {
    final core.Axis direction = style.resolvedDirection;
    final double? gap = style.gap;
    final List<Widget> children = <Widget>[];

    for (var index = 0; index < box.children.length; index++) {
      if (index > 0 && gap != null && gap > 0) {
        children.add(
          direction == core.Axis.horizontal
              ? SizedBox(width: gap)
              : SizedBox(height: gap),
        );
      }
      children.add(
        _buildChild(
          box.children[index],
          direction,
          availableWidth: availableWidth,
        ),
      );
    }

    final core.CrossAlign crossAlign =
        style.crossAlign ?? core.CrossAlign.start;
    final MainAxisAlignment mainAxisAlignment = toMainAxisAlignment(
      style.mainAlign ?? core.MainAlign.start,
    );
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }

  /// Renders [node] and makes it flexible along the parent's `direction` when it
  /// declares a [core.BoxStyle.flex] factor or an infinite main dimension.
  Widget _buildChild(
    core.UINode node,
    core.Axis direction, {
    required double? availableWidth,
  }) {
    final Widget child = renderNode(node, availableWidth: availableWidth);

    if (node is! core.Box) {
      return child;
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
    final double? mainSize = direction == core.Axis.horizontal
        ? childStyle.width
        : childStyle.height;
    final int? flex = childStyle.flex;
    final bool expands = mainSize == double.infinity;
    final bool hasFlex = flex != null && flex > 0;

    if (!expands && !hasFlex) {
      return child;
    }

    return Expanded(flex: hasFlex ? flex : 1, child: child);
  }

  /// Applies the fixed sizes and the min/max constraints of [style].
  Widget _applyDimensions(Widget content, core.BoxStyle style) {
    Widget result = content;

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
  Widget _applyInteractions(Widget content, core.Box box) {
    final bool interactive = box.isInteractive;
    final bool focusable = box.isFocusable && box.enabled;
    final bool tracksState =
        box.enabled &&
        (box.onHover != null ||
            box.stateStyle(core.BoxState.hover) != null ||
            box.stateStyle(core.BoxState.focus) != null ||
            box.stateStyle(core.BoxState.pressed) != null);

    Widget result = content;

    if (box.onTap != null || box.onLongPress != null || box.onTapDown != null) {
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

    if (interactive || tracksState) {
      result = MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: tracksState
            ? (PointerEnterEvent event) => _setHovered(true)
            : null,
        onExit: tracksState
            ? (PointerExitEvent event) => _setHovered(false)
            : null,
        child: result,
      );
    }

    return _describeToSemantics(result, box);
  }

  /// Activates the box from the keyboard.
  ///
  /// Enter and Space are what a button does everywhere: Enter fires on the way
  /// down, Space on the way up, and both show the pressed state in between.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final core.Box box = widget.box;
    final LogicalKeyboardKey key = event.logicalKey;
    final bool isActivationKey =
        key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space;

    if (!isActivationKey || !box.isInteractive) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      _setPressed(true);
      if (key == LogicalKeyboardKey.enter) {
        box.onTap?.call();
      }
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      _setPressed(false);
      if (key == LogicalKeyboardKey.space) {
        box.onTap?.call();
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
    final bool focusable = box.isFocusable && box.enabled;
    final core.LongPressCallback? longPress = box.enabled
        ? box.onLongPress
        : null;

    if (semantics == null && box.enabled && longPress == null) {
      return content;
    }

    final core.BoxRole role = semantics?.role ?? core.BoxRole.none;
    final bool? checked = semantics?.checked;
    final String? label = semantics?.label;

    return Semantics(
      container: semantics != null || longPress != null,
      // A label replaces the contents, so the accessible name cannot drift
      // away from what the screen reader reads.
      excludeSemantics: label != null,
      button: role == core.BoxRole.button,
      link: role == core.BoxRole.link,
      header: role == core.BoxRole.heading,
      checked: role == core.BoxRole.checkbox ? checked : null,
      // A switch is on or off, and so is a toggle button: Flutter states both with
      // `toggled`, and the web with `aria-checked` and `aria-pressed` respectively.
      toggled: role == core.BoxRole.switch_ ? checked : semantics?.pressed,
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
