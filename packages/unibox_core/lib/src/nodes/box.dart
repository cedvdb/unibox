import '../callbacks.dart';
import '../enums.dart';
import '../tokens/box_border.dart';
import '../tokens/box_color.dart';
import '../tokens/box_border_radius.dart';
import '../tokens/box_semantics.dart';
import '../tokens/box_shadow.dart';
import '../tokens/box_shape.dart';
import '../tokens/box_spacing.dart';
import '../tokens/box_style.dart';
import '../tokens/box_text_style.dart';
import '../tokens/box_transform.dart';
import '../tokens/box_transition.dart';
import 'ui_node.dart';

/// A flex container and the primary building block of Unibox.
///
/// A box lays out its [children] along [direction] (a `Row`/`Column` in
/// Flutter, a flex container in CSS) and paints its background, border and
/// shadow behind them.
///
/// Styling can be expressed in two ways:
/// * flat parameters (`gap`, `padding`, `backgroundColor`, ...), which are the
///   quickest to write, and
/// * reusable bags, `styles: <BoxStyle>[...]`, merged in the order they are given
///   (plus [hoverStyle] for the hovered state).
///
/// Flat parameters always take precedence over the matching token in a bag.
/// The resolved tokens are available through [computedStyle] and
/// [computedHoverStyle].
///
/// ```dart
/// const card = Box(
///   direction: Axis.vertical,
///   gap: 8,
///   padding: BoxSpacing.all(16),
///   styles: <BoxStyle>[BoxStyle(backgroundColor: BoxColor.white)],
///   children: [TextNode('Hello')],
/// );
/// ```
class Box extends UINode {
  /// Creates a box.
  const Box({
    super.key,
    this.children = const <UINode>[],
    this.direction,
    this.mainAlign,
    this.crossAlign,
    this.gap,
    this.wrap,
    this.flex,
    this.gridSpan,
    this.overflow,
    this.snap,
    this.page,
    this.width,
    this.height,
    this.aspectRatio,
    this.widthFraction,
    this.heightFraction,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.corners,
    this.border,
    this.shadows,
    this.shape,
    this.textStyle,
    this.transition,
    this.opacity,
    this.transform,
    this.visibleFrom,
    this.visibleUntil,
    this.styles = const <BoxStyle>[],
    this.hoverStyle,
    this.stateStyles,
    this.enabled = true,
    this.capturesPointer,
    this.semantics,
    this.onTap,
    this.onTapDown,
    this.onLongPress,
    this.onHover,
    this.onScroll,
  });

  /// The child nodes laid out by this box.
  @override
  final List<UINode> children;

  // Layout.

  /// The direction children are laid out in.
  ///
  /// Defaults to [Axis.vertical]: a box without a direction is a column, and it
  /// is one on every target, so leaving the direction out never changes the
  /// shape of the tree between Flutter and the web. See
  /// [BoxStyle.resolvedDirection].
  final Axis? direction;

  /// Distribution of children along the main axis.
  final MainAlign? mainAlign;

  /// Alignment of children along the cross axis.
  final CrossAlign? crossAlign;

  /// Space between children in logical pixels.
  final double? gap;

  /// Whether the children flow onto another line rather than off the end of the box.
  ///
  /// The box is still a flex container — the children are laid out along [direction] and
  /// [gap] is the space between two of them — but a child that does not fit starts
  /// another line instead of running past the edge. [gap] is the space between two lines
  /// as well, so one number spaces a wrapped row in both directions, and [mainAlign] and
  /// [crossAlign] distribute one line and place a child within it, which is what `Wrap`
  /// and `flex-wrap: wrap` both mean.
  ///
  /// It is a token and not a `WrapNode` because it is the same element on the web: a
  /// `display: flex` container with `flex-wrap: wrap`. A node of its own would be a
  /// second name for one element, with its own plan and its own render path, and would
  /// draw exactly what this draws.
  ///
  /// `crossAlign: CrossAlign.stretch`, `crossAlign: CrossAlign.baseline`, and a `flex` on
  /// a child of a wrapping box cannot be honoured by both targets; `validateTree`
  /// reports them instead of drawing one of them twice.
  final bool? wrap;

  /// How much of the remaining space this box should take up.
  final int? flex;

  /// How many tracks of a [GridNode] this box occupies, or `null` for one.
  ///
  /// A card grid that has to be interrupted — a promo banner across the row
  /// between the first two cards — is one grid whose banner says `gridSpan: 2`,
  /// rather than two grids that agree on the column count by accident.
  ///
  /// It is a token on the card and not a `GridItem` wrapper for the reason the model
  /// keeps everywhere: CSS states the span on the element that spans (`grid-column:
  /// span 2`) and not on an element around it, so a wrapper would be a box between the
  /// grid and the card that wins nothing, changes the tree every card is written
  /// against, and would need its own name and its own case in both renderers.
  ///
  /// Only a box inside a [GridNode] has tracks to span; `validateTree` reports the
  /// token anywhere else. A span wider than the grid is clamped to its column
  /// count on both targets, so a full width banner is a large number rather than a
  /// second rule.
  final int? gridSpan;

  /// How content exceeding the box bounds is treated.
  final Overflow? overflow;

  /// Where the box comes to rest when a scroll gesture ends.
  ///
  /// Only a box that scrolls has anything to settle, so this is [ScrollSnap.page] on a box
  /// with `overflow: Overflow.scroll`: it then moves one child at a time and stops on a
  /// child rather than between two, which is a pager. `validateTree` reports a snap on a
  /// box that cannot scroll, because it can do nothing there.
  final ScrollSnap? snap;

  /// The page this box shows, counted along its own axis, or `null` for wherever it is.
  ///
  /// This is how a pager is moved, and it is state rather than a command: the tree says *which*
  /// child the box is showing, the store that owns the index changes it, and a renderer slides the
  /// box when the value differs from what it last applied. Drawn twice with the same page, nothing
  /// moves — which is what makes it safe to state on every rebuild.
  ///
  /// Only meaningful with [snap] of [ScrollSnap.page]; `validateTree` reports a page on a box that
  /// does not snap, and a snap with no page is left alone, since a reader may still swipe.
  final int? page;

  // Dimensions.

  /// The width in logical pixels, or `double.infinity` to expand.
  final double? width;

  /// The height in logical pixels, or `double.infinity` to expand.
  final double? height;

  /// The width divided by the height, or `null` for no ratio.
  ///
  /// `1.5` keeps three units across for every two down, whatever the width turns out
  /// to be: the shape of a thumbnail, an avatar tile or a video still, stated once
  /// instead of as a pair of numbers that only fit one window. One side is measured
  /// and the ratio gives the other, so it needs one to measure against — a [width], a
  /// [height], a [widthFraction], or a parent that fills one. A box that states a
  /// width and a height has answered already, and `validateTree` reports the ratio
  /// that cannot change anything there.
  final double? aspectRatio;

  /// The width as a fraction of the parent's, or `null` for a stated one.
  ///
  /// This is the size that can be stated without knowing a number: a share of a row, one tab of
  /// a bar. It wins over [width], and `validateTree` reports the two together.
  final double? widthFraction;

  /// The height as a fraction of the parent's, or `null` for a stated one.
  final double? heightFraction;

  /// The minimum width in logical pixels.
  final double? minWidth;

  /// The maximum width in logical pixels.
  final double? maxWidth;

  /// The minimum height in logical pixels.
  final double? minHeight;

  /// The maximum height in logical pixels.
  final double? maxHeight;

  // Visuals.

  /// Space reserved inside the box.
  final BoxSpacing? padding;

  /// Space reserved outside the box.
  final BoxSpacing? margin;

  /// The background color painted behind the children.
  final BoxColor? backgroundColor;

  /// The corner radius in logical pixels.
  /// The corner radius in logical pixels, one for all four corners.
  ///
  /// A box that must not be round everywhere names the four in [corners]
  /// instead.
  final double? borderRadius;

  /// The radius of each corner, for a box that is not round on all four.
  ///
  /// Takes precedence over [borderRadius]. `validateTree` reports a box that
  /// sets both, since only one answer can be drawn.
  final BoxBorderRadius? corners;

  /// The border painted around the box.
  final BoxBorder? border;

  /// The drop shadows painted behind the box, in paint order.
  ///
  /// A list rather than one shadow, because a design system states an elevation as
  /// several layers and each of them is a shadow: Material's level one is a tight umbra,
  /// a penumbra and a wide ambient layer, and a browser paints all three.
  final List<BoxShadow>? shadows;

  /// The outline the box is painted in, instead of its rectangle.
  ///
  /// A shape paints the box's region: the background fills the path, the [border]
  /// is drawn along it, and the children are clipped to it when the box also says
  /// `overflow: Overflow.hidden`. It changes nothing about layout.
  final BoxShape? shape;

  // Typography.

  /// The typography inherited by the children of this box.
  ///
  /// Text nodes inside the box take every token they do not set themselves from
  /// here, which mirrors CSS font inheritance and Flutter's
  /// `DefaultTextStyle`. It never affects layout.
  final BoxTextStyle? textStyle;

  /// How one look of this box becomes another.
  ///
  /// A state style names the tokens that change; this says how long the
  /// change takes and how it eases. Unset means the look swaps instantly.
  final BoxTransition? transition;

  /// How opaque the box is, `0` to `1`. Unset means solid.
  final double? opacity;

  /// How the box is moved, turned or scaled about its centre.
  ///
  /// The box paints differently without taking a different amount of room, so
  /// scaling never makes the text inside reflow.
  final BoxTransform? transform;

  // Style tokens.

  /// The bags of tokens this box wears, merged in the order they are given.
  ///
  /// The last bag wins a token over an earlier one, a flat parameter wins over
  /// every bag, and `computedStyle` is the result. It is how a look is composed out
  /// of reusable pieces — a base, a variant, a state — without a name registry and
  /// without leaving a `const` tree:
  ///
  /// ```dart
  /// Box(
  ///   styles: <BoxStyle>[
  ///     Card.base,
  ///     if (selected) Card.selected,
  ///     if (compact) Card.compact,
  ///   ],
  /// );
  /// ```
  final List<BoxStyle> styles;

  /// Tokens applied while the box is hovered, overriding the base style.
  ///
  /// The narrowest layout box, in logical pixels, that draws this box.
  ///
  /// The box names a threshold instead of measuring the screen: the renderer asks
  /// the width of the layout box this one is drawn in — a container query on the
  /// web, the constraints of the same box in Flutter — and hides this one below
  /// it. Hiding is a style, so the node stays in the tree and in the DOM at every
  /// width; a box this one is *not* drawn in still ships its markup.
  final double? visibleFrom;

  /// The widest layout box, in logical pixels, that still draws this box.
  ///
  /// The range is half open, so `visibleFrom: 600, visibleUntil: 900` is drawn
  /// from 600 up to, but not including, 900.
  final double? visibleUntil;

  /// Whether this box is drawn at only some widths, on either side of a band.
  ///
  /// Read from the tokens without resolving the style. A renderer asks this of every child of
  /// every box — a box that holds a threshold is the box a container query measures — and
  /// resolving a style merges every bag and the flat parameters into a fresh one, for a
  /// question about two tokens. Merging can add a threshold and never take one away, so the
  /// answer is whether any of the bags, or the flat parameter, states one.
  bool get hasThreshold {
    if (visibleFrom != null || visibleUntil != null) {
      return true;
    }

    bool states(BoxStyle? style) =>
        style != null &&
        (style.visibleFrom != null || style.visibleUntil != null);

    for (final BoxStyle bag in styles) {
      if (states(bag)) {
        return true;
      }
    }

    return false;
  }

  /// Sugar for `stateStyles: {BoxState.hover: hoverStyle}`. An entry in
  /// [stateStyles] wins over this one.
  final BoxStyle? hoverStyle;

  /// Tokens applied while the box is in a given state.
  ///
  /// Every state overlays the resting style, so a state only has to name the
  /// tokens that change. [BoxState.disabled] wins over all other states, because
  /// a disabled box cannot be hovered, focused or pressed in the first place.
  final Map<BoxState, BoxStyle>? stateStyles;

  /// Whether the box reacts to input.
  ///
  /// A disabled box drops every callback and is reported as disabled to assistive
  /// technologies, but keeps its layout and still renders its
  /// [BoxState.disabled] style. Disabling a box therefore never moves anything.
  final bool enabled;

  /// Whether the pointer may land on this box, or `null` to let the box decide.
  ///
  /// Left unset, a box that holds children, answers a callback or paints a state
  /// takes the pointer, and a painted leaf does not — so a press reaches the control
  /// the leaf was drawn for. `false` says the box is decoration whatever it holds: a
  /// badge over a button gives the hover, the cursor and the press to the button under
  /// it instead of swallowing them in a corner that looks alive and is not.
  final bool? capturesPointer;

  // Accessibility.

  /// What this box means to assistive technologies.
  ///
  /// A box without semantics is a plain container. A role the user can act on
  /// makes the box keyboard focusable, which is the opt in for keyboard
  /// interaction: a box without a role stays out of the tab order.
  final BoxSemantics? semantics;

  // Actions.

  /// Called when the box is tapped.
  final TapCallback? onTap;

  /// Called when a press lands on the box, before it is released.
  ///
  /// The event carries where the press landed inside the box and what pressed it,
  /// which is what an effect that starts at the pointer needs. [onTap] stays for the
  /// case where only the activation matters; a box can have either, both, or
  /// neither.
  final TapDownCallback? onTapDown;

  /// Called when the box is long pressed.
  ///
  /// It is an action a screen reader can invoke where the platform has one: the
  /// Flutter renderer hands it to `Semantics(onLongPress:)`, as `InkWell` does. A
  /// browser has no such action, so on the web a hold is a pointer gesture and
  /// nothing more — a control only a hold reaches needs a visible target beside it,
  /// or a [BoxSemantics.label] that says what the hold does.
  final LongPressCallback? onLongPress;

  /// Called when the pointer enters or leaves the box.
  final HoverCallback? onHover;

  /// Called as the box scrolls, with how far its content has moved.
  ///
  /// Only a box that scrolls ([overflow] of [Overflow.scroll]) reports it, and only for its
  /// own scrolling: a scrollable nested inside it reports to its own box, because the browser
  /// does not let a `scroll` event bubble and Flutter's notifications carry a depth.
  ///
  /// It is how a screen reacts to the scroll itself — a header that folds as the list under it
  /// moves, a control that appears once a reader is part of the way down — which a tree could
  /// not do at all while the position lived only in the host.
  final ScrollCallback? onScroll;

  /// The flat parameters of this box as a style overlay.
  BoxStyle get _flatStyle => BoxStyle(
    direction: direction,
    mainAlign: mainAlign,
    crossAlign: crossAlign,
    gap: gap,
    wrap: wrap,
    flex: flex,
    gridSpan: gridSpan,
    overflow: overflow,
    snap: snap,
    page: page,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    widthFraction: widthFraction,
    heightFraction: heightFraction,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight,
    padding: padding,
    margin: margin,
    backgroundColor: backgroundColor,
    borderRadius: borderRadius,
    corners: corners,
    border: border,
    shadows: shadows,
    shape: shape,
    textStyle: textStyle,
    transition: transition,
    opacity: opacity,
    transform: transform,
    visibleFrom: visibleFrom,
    visibleUntil: visibleUntil,
  );

  /// The resolved style of this box in its resting state.
  ///
  /// [styles] provide the defaults, merged left to right, and every flat parameter
  /// that is not `null` overrides the matching token.
  BoxStyle get computedStyle {
    BoxStyle result = const BoxStyle();

    for (final BoxStyle bag in styles) {
      result = result.merge(bag);
    }

    return result.merge(_flatStyle);
  }

  /// The tokens that apply in [state], or `null` when the state adds nothing.
  BoxStyle? stateStyle(BoxState state) {
    final BoxStyle? fromMap = stateStyles?[state];

    if (state == BoxState.hover && hoverStyle != null) {
      return fromMap == null ? hoverStyle : hoverStyle!.merge(fromMap);
    }

    return fromMap;
  }

  /// The resolved style of this box for [state].
  ///
  /// The resting style is the base and the tokens of the state are laid over
  /// it. [BoxState.disabled] always wins: a disabled box cannot be hovered,
  /// focused or pressed, and asking for the disabled style while the box is
  /// enabled still returns it, so both renderers can describe one state
  /// independently of who set [enabled].
  BoxStyle computedStyleFor(BoxState state) {
    final BoxStyle resting = computedStyle;

    if (!enabled || state == BoxState.disabled) {
      return resting.merge(stateStyle(BoxState.disabled));
    }

    return resting.merge(stateStyle(state));
  }

  /// The resolved style of this box while it is hovered.
  ///
  /// Equal to [computedStyle] when no hover tokens are set, otherwise the
  /// hovered tokens take precedence over the resting ones.
  BoxStyle get computedHoverStyle => computedStyleFor(BoxState.hover);

  /// The typography of this box, or an empty style when none is set.
  ///
  /// Renderers hand this to their descendants as the ambient text style.
  BoxTextStyle get computedTextStyle =>
      computedStyle.textStyle ?? const BoxTextStyle();

  /// Whether this box defines a distinct hovered appearance.
  bool get hasHoverStyle => stateStyle(BoxState.hover) != null;

  /// Whether the box can be reached with the keyboard.
  bool get isFocusable => semantics?.isFocusable ?? false;

  /// Whether this box has an interaction handler it can run.
  ///
  /// A disabled box reports `false` even when it has callbacks, so renderers
  /// serve no pointer cursor, no hover and no press for it.
  bool get isInteractive =>
      enabled && (onTap != null || onTapDown != null || onLongPress != null);

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'box';
}
