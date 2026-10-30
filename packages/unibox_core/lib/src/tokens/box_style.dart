import '../enums.dart';
import 'box_border.dart';
import 'box_color.dart';
import 'box_border_radius.dart';
import 'box_shadow.dart';
import 'box_shape.dart';
import 'box_spacing.dart';
import 'box_text_style.dart';
import 'box_transform.dart';
import 'box_transition.dart';
import 'unibox_theme.dart';

/// A reusable, immutable bundle of box tokens.
///
/// Every field is optional: `null` means "not specified". A box applies flat
/// parameters on top of a style with [merge], so flat parameters always win
/// over matching style tokens.
///
/// A [textStyle] is the one exception to "a box styles itself": typography is
/// inherited by the descendants of the box, the way CSS font properties and
/// Flutter's `DefaultTextStyle` are. Every other token only affects the box.
///
/// ```dart
/// const cardStyle = BoxStyle(
///   padding: BoxSpacing.all(16),
///   backgroundColor: BoxColor.white,
///   borderRadius: 12,
///   textStyle: BoxTextStyle(fontSize: 16),
/// );
/// ```
final class BoxStyle {
  /// Creates a style bundle. Unspecified tokens stay `null`.
  const BoxStyle({
    this.direction,
    this.mainAlign,
    this.crossAlign,
    this.gap,
    this.flex,
    this.gridSpan,
    this.overflow,
    this.snap,
    this.page,
    this.width,
    this.height,
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
    this.shadow,
    this.shape,
    this.textStyle,
    this.transition,
    this.opacity,
    this.transform,
    this.visibleFrom,
    this.visibleUntil,
  });

  // Layout.

  /// The layout direction of the children.
  ///
  /// Unset means "not specified"; [resolvedDirection] is what the renderers
  /// actually lay the children out in.
  final Axis? direction;

  /// The direction the renderers lay the children out in.
  ///
  /// An unset [direction] means [Axis.vertical], never "no layout of its own":
  /// a box is a flex container on every target, and a column is the only shape
  /// a Flutter `Column` and a CSS flex column agree on. Resolving the default
  /// once, here, is what keeps `gap`, [mainAlign], [crossAlign] and the `flex`
  /// of a child from silently doing nothing on a box that never named a
  /// direction.
  Axis get resolvedDirection => direction ?? Axis.vertical;

  /// Distribution of the children along the main axis.
  final MainAlign? mainAlign;

  /// Alignment of the children along the cross axis.
  final CrossAlign? crossAlign;

  /// Space between children in logical pixels.
  final double? gap;

  /// How much of the remaining space this box should take up.
  final int? flex;

  /// How many tracks of a grid this box occupies, or `null` for one.
  ///
  /// Only a child of a `GridNode` has tracks to span, and `validateTree` reports
  /// the token anywhere else, because a span with no grid around it does nothing.
  /// It is how a banner interrupts a card grid: two cards, a banner the width of
  /// the row, then the rest.
  ///
  /// The number is clamped to the column count of the grid, so `2` in a one column
  /// grid is one column rather than an overflow — the same answer CSS gives a
  /// `grid-column: span 2` in a one track grid, and the reason both targets keep
  /// `auto-fill`: the count follows the width, and a span that does not fit has to
  /// follow the count.
  final int? gridSpan;

  /// How overflowing content is treated.
  final Overflow? overflow;

  /// Where the box comes to rest when a scroll gesture ends.
  ///
  /// Only meaningful with [overflow] of [Overflow.scroll]: a box that does not scroll has
  /// nothing to settle. [ScrollSnap.page] makes it a pager — it moves one child at a time,
  /// along the box's own axis, and stops on a child rather than between two.
  final ScrollSnap? snap;

  /// The page a snapping box shows, counted along its own axis, or `null` for wherever it is.
  ///
  /// This is the one way to *move* a pager, and it is a position rather than a controller: a tree
  /// drawn twice with the same page does not move the second time, and a tree drawn with another
  /// page slides one child. It is discrete on purpose — a continuous offset belongs to the reader'
  /// finger, and a renderer that set one on every rebuild would fight it.
  ///
  /// Only meaningful with [snap] of [ScrollSnap.page]: [ScrollSnap] says where the box settles and
  /// this says where it is told to settle, which `validateTree` reports when only one is given.
  final int? page;

  // Dimensions.

  /// The width in logical pixels, or `double.infinity` to expand.
  final double? width;

  /// The height in logical pixels, or `double.infinity` to expand.
  final double? height;

  /// The width as a fraction of the parent's, or `null` for a stated width.
  ///
  /// `1` is the whole of it, `0.5` half. This is the size a box can state without knowing a
  /// number: a share of a row, a column of a grid of shares. Material's tab indicator is one
  /// share of the bar, which is a fraction rather than a pixel count because the bar's width is
  /// the layout's business.
  ///
  /// It wins over [width], and `validateTree` reports the two together, because a box that is
  /// told both has been told two things.
  final double? widthFraction;

  /// The height as a fraction of the parent's, or `null` for a stated height.
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

  /// The background color of the box.
  final BoxColor? backgroundColor;

  /// The corner radius in logical pixels, one radius for all four corners.
  ///
  /// A box that must not be round everywhere — a filled text field rounds its
  /// top and leaves the bottom square — names the four in [corners] instead.
  final double? borderRadius;

  /// The radius of each corner, for a box that is not round on all four.
  ///
  /// Takes precedence over [borderRadius]; `validateTree` reports a box that sets
  /// both, because the model cannot honour two answers.
  final BoxBorderRadius? corners;

  /// The border painted around the box.
  final BoxBorder? border;

  /// The drop shadow painted behind the box.
  final BoxShadow? shadow;

  /// The outline the box is painted in, instead of its rectangle.
  ///
  /// Unset means the box is a rectangle, which is what [borderRadius] and
  /// [corners] round. A shape takes over the outline: the background fills it, the
  /// [border] is drawn along it, and [borderRadius] and [corners] no longer apply —
  /// `validateTree` reports a box that states both, because a box has one outline.
  final BoxShape? shape;

  // Typography.

  /// The typography inherited by the descendants of the box.
  ///
  /// Merging two styles merges their text styles token by token, so a box can
  /// change a single font token of an inherited style.
  final BoxTextStyle? textStyle;

  /// How one look of this box becomes another.
  ///
  /// The resting style declares it and a `BoxState` style only names the tokens
  /// that change, so the transition applies to the change itself. Unset means the
  /// look swaps instantly.
  final BoxTransition? transition;

  /// How opaque the box is, from `0` (invisible) to `1` (solid).
  ///
  /// Unset means solid. The space the box occupies stays the same: an invisible
  /// box paints nothing rather than leaving the layout.
  final double? opacity;

  /// The narrowest layout box, in logical pixels, that draws this one.
  ///
  /// Unset means "at every width". The threshold measures the box the node is
  /// drawn in — not the window — so a card inside a panel answers for the panel.
  /// It is a style, not a structure: the node stays in the tree, in the DOM and in
  /// the crawl at every width, and only its `display` changes.
  final double? visibleFrom;

  /// The widest layout box, in logical pixels, that still draws this one.
  ///
  /// The range is half open — `[visibleFrom, visibleUntil)` — so `visibleFrom:
  /// 600, visibleUntil: 900` is drawn from 600 up to, but not including, 900.
  final double? visibleUntil;

  /// Whether the box is drawn at every width.
  bool get isVisibleEverywhere => visibleFrom == null && visibleUntil == null;

  /// Whether a layout box of [width] logical pixels draws this style.
  ///
  /// The one piece of arithmetic both renderers share, the way [GridNode]
  /// shares its column count: the web writes it as a container query and Flutter
  /// runs it against the constraints of the same box, so the two cannot disagree
  /// about which width shows what.
  bool isShownAt(double width) {
    final double? from = visibleFrom;
    final double? until = visibleUntil;

    return (from == null || width >= from) && (until == null || width < until);
  }

  /// How the box is moved, turned or scaled, about its centre.
  ///
  /// Unset means untransformed. Like a `Transform` in Flutter, this paints the
  /// box differently without changing the room it takes.
  final BoxTransform? transform;

  /// Whether no token is set.
  /// Whether any token here names a colour the theme has to resolve.
  bool get hasRoleColors {
    final BoxColor? background = backgroundColor;
    return (background != null && background.isRole) ||
        (border?.color.isRole ?? false) ||
        (shadow?.color.isRole ?? false) ||
        (textStyle?.color?.isRole ?? false);
  }

  /// This style with every role colour looked up in [theme].
  ///
  /// The Flutter renderer calls it once per style and every value it reads after
  /// that is concrete; the web renderer leaves the roles alone and points them at
  /// their custom property. A style with no role comes back as it is, so a tree of
  /// values pays nothing for the possibility.
  BoxStyle resolve(UniboxTheme theme) {
    if (!hasRoleColors) {
      return this;
    }

    final BoxColor? background = backgroundColor;

    return BoxStyle(
      direction: direction,
      mainAlign: mainAlign,
      crossAlign: crossAlign,
      gap: gap,
      flex: flex,
      gridSpan: gridSpan,
      overflow: overflow,
      snap: snap,
      page: page,
      width: width,
      height: height,
      widthFraction: widthFraction,
      heightFraction: heightFraction,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      padding: padding,
      margin: margin,
      backgroundColor: background == null ? null : theme.resolve(background),
      borderRadius: borderRadius,
      corners: corners,
      border: border?.resolve(theme),
      shadow: shadow?.resolve(theme),
      shape: shape,
      textStyle: textStyle?.resolve(theme),
      transition: transition,
      opacity: opacity,
      transform: transform,
      visibleFrom: visibleFrom,
      visibleUntil: visibleUntil,
    );
  }

  bool get isEmpty => this == const BoxStyle();

  /// Creates a copy of this style with the given tokens replaced.
  ///
  /// Passing `null` keeps the current value; use a fresh [BoxStyle] to clear
  /// tokens.
  BoxStyle copyWith({
    Axis? direction,
    MainAlign? mainAlign,
    CrossAlign? crossAlign,
    double? gap,
    int? flex,
    int? gridSpan,
    Overflow? overflow,
    ScrollSnap? snap,
    int? page,
    double? width,
    double? height,
    double? widthFraction,
    double? heightFraction,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    BoxSpacing? padding,
    BoxSpacing? margin,
    BoxColor? backgroundColor,
    double? borderRadius,
    BoxBorderRadius? corners,
    BoxBorder? border,
    BoxShadow? shadow,
    BoxShape? shape,
    BoxTextStyle? textStyle,
    BoxTransition? transition,
    double? opacity,
    BoxTransform? transform,
    double? visibleFrom,
    double? visibleUntil,
  }) {
    return BoxStyle(
      direction: direction ?? this.direction,
      mainAlign: mainAlign ?? this.mainAlign,
      crossAlign: crossAlign ?? this.crossAlign,
      gap: gap ?? this.gap,
      flex: flex ?? this.flex,
      gridSpan: gridSpan ?? this.gridSpan,
      overflow: overflow ?? this.overflow,
      snap: snap ?? this.snap,
      page: page ?? this.page,
      width: width ?? this.width,
      height: height ?? this.height,
      widthFraction: widthFraction ?? this.widthFraction,
      heightFraction: heightFraction ?? this.heightFraction,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      corners: corners ?? this.corners,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      shape: shape ?? this.shape,
      textStyle: textStyle ?? this.textStyle,
      transition: transition ?? this.transition,
      opacity: opacity ?? this.opacity,
      transform: transform ?? this.transform,
      visibleFrom: visibleFrom ?? this.visibleFrom,
      visibleUntil: visibleUntil ?? this.visibleUntil,
    );
  }

  /// Overlays [other] on top of this style.
  ///
  /// Tokens that are `null` in [other] keep the value from this style, all
  /// other tokens take precedence. This is how flat box parameters override
  /// style tokens:
  ///
  /// ```dart
  /// final effective = style.merge(const BoxStyle(padding: BoxSpacing.all(8)));
  /// ```
  BoxStyle merge(BoxStyle? other) {
    if (other == null) {
      return this;
    }
    return BoxStyle(
      direction: other.direction ?? direction,
      mainAlign: other.mainAlign ?? mainAlign,
      crossAlign: other.crossAlign ?? crossAlign,
      gap: other.gap ?? gap,
      flex: other.flex ?? flex,
      gridSpan: other.gridSpan ?? gridSpan,
      overflow: other.overflow ?? overflow,
      snap: other.snap ?? snap,
      page: other.page ?? page,
      width: other.width ?? width,
      height: other.height ?? height,
      widthFraction: other.widthFraction ?? widthFraction,
      heightFraction: other.heightFraction ?? heightFraction,
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      minHeight: other.minHeight ?? minHeight,
      maxHeight: other.maxHeight ?? maxHeight,
      padding: other.padding ?? padding,
      margin: other.margin ?? margin,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      corners: other.corners ?? corners,
      border: other.border ?? border,
      shadow: other.shadow ?? shadow,
      shape: other.shape ?? shape,
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      transition: other.transition ?? transition,
      opacity: other.opacity ?? opacity,
      transform: other.transform ?? transform,
      visibleFrom: other.visibleFrom ?? visibleFrom,
      visibleUntil: other.visibleUntil ?? visibleUntil,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BoxStyle &&
      other.direction == direction &&
      other.mainAlign == mainAlign &&
      other.crossAlign == crossAlign &&
      other.gap == gap &&
      other.flex == flex &&
      other.gridSpan == gridSpan &&
      other.overflow == overflow &&
      other.snap == snap &&
      other.page == page &&
      other.width == width &&
      other.height == height &&
      other.widthFraction == widthFraction &&
      other.heightFraction == heightFraction &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.minHeight == minHeight &&
      other.maxHeight == maxHeight &&
      other.padding == padding &&
      other.margin == margin &&
      other.backgroundColor == backgroundColor &&
      other.borderRadius == borderRadius &&
      other.corners == corners &&
      other.border == border &&
      other.shadow == shadow &&
      other.shape == shape &&
      other.textStyle == textStyle &&
      other.transition == transition &&
      other.opacity == opacity &&
      other.transform == transform &&
      other.visibleFrom == visibleFrom &&
      other.visibleUntil == visibleUntil;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    direction,
    mainAlign,
    crossAlign,
    gap,
    flex,
    gridSpan,
    overflow,
    snap,
    page,
    width,
    height,
    widthFraction,
    heightFraction,
    minWidth,
    maxWidth,
    minHeight,
    maxHeight,
    padding,
    margin,
    backgroundColor,
    borderRadius,
    corners,
    border,
    shadow,
    shape,
    textStyle,
    transition,
    opacity,
    transform,
  ]);

  @override
  String toString() {
    final tokens = <String>[
      if (direction != null) 'direction: $direction',
      if (mainAlign != null) 'mainAlign: $mainAlign',
      if (crossAlign != null) 'crossAlign: $crossAlign',
      if (gap != null) 'gap: $gap',
      if (flex != null) 'flex: $flex',
      if (gridSpan != null) 'gridSpan: $gridSpan',
      if (overflow != null) 'overflow: $overflow',
      if (snap != null) 'snap: $snap',
      if (page != null) 'page: $page',
      if (width != null) 'width: $width',
      if (widthFraction != null) 'widthFraction: $widthFraction',
      if (heightFraction != null) 'heightFraction: $heightFraction',
      if (height != null) 'height: $height',
      if (minWidth != null) 'minWidth: $minWidth',
      if (maxWidth != null) 'maxWidth: $maxWidth',
      if (minHeight != null) 'minHeight: $minHeight',
      if (maxHeight != null) 'maxHeight: $maxHeight',
      if (padding != null) 'padding: $padding',
      if (margin != null) 'margin: $margin',
      if (backgroundColor != null) 'backgroundColor: $backgroundColor',
      if (borderRadius != null) 'borderRadius: $borderRadius',
      if (corners != null) 'corners: $corners',
      if (border != null) 'border: $border',
      if (shadow != null) 'shadow: $shadow',
      if (shape != null) 'shape: $shape',
      if (textStyle != null) 'textStyle: $textStyle',
      if (transition != null) 'transition: $transition',
      if (opacity != null) 'opacity: $opacity',
      if (transform != null) 'transform: $transform',
      if (visibleFrom != null) 'visibleFrom: $visibleFrom',
      if (visibleUntil != null) 'visibleUntil: $visibleUntil',
    ];
    return 'BoxStyle(${tokens.join(', ')})';
  }
}
