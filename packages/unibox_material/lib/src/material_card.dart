import 'package:unibox_core/unibox_core.dart';

import 'material_elevation.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// A Material 3 card: a surface with the padding, shape, elevation and body
/// typography Material gives a card, drawn as a [Box].
///
/// ```dart
/// const MaterialCard(
///   children: <UINode>[
///     TextNode('Order summary', style: MaterialTypography.titleMedium),
///     TextNode('Two nights, one room.'),
///   ],
/// );
/// ```
///
/// It adds no renderer work: it *is* a box, so both targets draw it with the
/// renderer they already have, and every token it sets is one the conformance
/// table already pins. What the class buys is the combination — a column with 16
/// logical pixels of padding, a 12 pixel radius, a level one drop shadow, a white
/// surface and `bodyMedium` for the texts inside — and a name that says a card.
/// A node that extends [Box] renders as that box on both targets, which the
/// renderer suites pin.
///
/// **What it is not.** It is not a colour scheme: Material picks a card's surface
/// from `surfaceContainerLow`, so the default is the baseline light value written
/// out, and a themed application passes the roles it wants —
/// `color: const BoxColor.role(MaterialColorRole.surfaceContainerLow)`, `border: BoxBorder(color:
/// const BoxColor.role(MaterialColorRole.outlineVariant))` — from a `MaterialPalette`.
///
/// The three official variants are named constructors, as in Flutter's `Card`:
/// [MaterialCard.elevated] (`surfaceContainerLow` and the level one shadow),
/// [MaterialCard.filled] (`surfaceContainerHighest`) and [MaterialCard.outlined]
/// (`surface` and a 1 pixel `outlineVariant` border). Each takes the card's whole
/// parameter list and lets the caller replace the surface, the line or the shadow
/// it starts from. It is not a ripple: a press is [stateStyles], the same as on any
/// other control.
///
/// **The escape hatch is a [Box].** The card states its surface, the layout of
/// its content and its interaction; anything else — a style bag, opacity, a
/// transform, a size bound — is a plain box around it, and the `Box` you would
/// have written is the one this class builds.
final class MaterialCard extends Box {
  /// Creates a card, with the tokens Material gives one.
  ///
  /// `padding`, `color`, `borderRadius`, `shadows`, `border` and `textStyle` are
  /// the card's own defaults; every one is a parameter so an application can
  /// theme them without giving up the card. So is `crossAlign`, and it stretches:
  /// a card's content spans the card, which is what Material's own card does, and
  /// what makes a `width: double.infinity` inside a card mean the same thing on
  /// both targets — a percentage inside a box that hugs its own content resolves
  /// to `auto` in CSS and fills in Flutter, which is how the example's rows came to
  /// stop half way across the card on the web.
  const MaterialCard({
    super.key,
    super.children,
    super.direction,
    super.mainAlign,
    CrossAlign crossAlign = CrossAlign.stretch,
    super.gap,
    super.flex,
    super.overflow,
    super.width,
    super.height,
    super.margin,
    super.transition,
    super.hoverStyle,
    super.stateStyles,
    super.enabled,
    super.semantics,
    super.onTap,
    super.onLongPress,
    super.onHover,
    super.shadows = elevatedShadows,
    super.border,
    BoxSpacing padding = const BoxSpacing.all(16),
    BoxColor color = _elevatedSurface,
    double borderRadius = 12,
    BoxTextStyle textStyle = MaterialTypography.bodyMedium,
  }) : super(
         crossAlign: crossAlign,
         padding: padding,
         backgroundColor: color,
         borderRadius: borderRadius,
         textStyle: textStyle,
       );

  /// A filled card: `surfaceContainerHighest`, no shadow, 12 pixel radius.
  ///
  /// It takes the card's whole parameter list, as `Card.filled` does in Flutter:
  /// the variant states the surface, the elevation and the line, and each of them
  /// can be overridden without giving up the card.
  MaterialCard.filled({
    Object? key,
    List<UINode> children = const <UINode>[],
    Axis? direction,
    MainAlign? mainAlign,
    CrossAlign? crossAlign,
    double? gap,
    int? flex,
    Overflow? overflow,
    double? width,
    double? height,
    BoxSpacing? margin,
    BoxSpacing padding = const BoxSpacing.all(16),
    BoxTransition? transition,
    BoxStyle? hoverStyle,
    Map<BoxState, BoxStyle>? stateStyles,
    bool enabled = true,
    BoxSemantics? semantics,
    TapCallback? onTap,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    BoxColor? color,
    List<BoxShadow>? shadows,
    BoxBorder? border,
    double borderRadius = 12,
    BoxTextStyle? textStyle,
  }) : this(
         key: key,
         children: children,
         direction: direction,
         mainAlign: mainAlign,
         crossAlign: crossAlign ?? CrossAlign.stretch,
         gap: gap,
         flex: flex,
         overflow: overflow,
         width: width,
         height: height,
         margin: margin,
         padding: padding,
         transition: transition,
         hoverStyle: hoverStyle,
         stateStyles: stateStyles,
         enabled: enabled,
         semantics: semantics,
         onTap: onTap,
         onLongPress: onLongPress,
         onHover: onHover,
         borderRadius: borderRadius,
         textStyle: textStyle ?? _bodyOn(),
         color:
             color ??
             const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
         // No shadow is a statement, not the absence of one: `null` would fall through to
         // the primary constructor's `elevatedShadows`, and this shape casts none.
         shadows: shadows ?? const <BoxShadow>[],
         border: border,
       );

  /// An outlined card: `surface` with a 1 pixel `outlineVariant` border, no
  /// shadow, 12 pixel radius.
  ///
  /// The whole parameter list, like [MaterialCard.filled]; the border is the one
  /// token the variant states, and passing another replaces it.
  MaterialCard.outlined({
    Object? key,
    List<UINode> children = const <UINode>[],
    Axis? direction,
    MainAlign? mainAlign,
    CrossAlign? crossAlign,
    double? gap,
    int? flex,
    Overflow? overflow,
    double? width,
    double? height,
    BoxSpacing? margin,
    BoxSpacing padding = const BoxSpacing.all(16),
    BoxTransition? transition,
    BoxStyle? hoverStyle,
    Map<BoxState, BoxStyle>? stateStyles,
    bool enabled = true,
    BoxSemantics? semantics,
    TapCallback? onTap,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    BoxColor? color,
    List<BoxShadow>? shadows,
    BoxBorder? border,
    double borderRadius = 12,
    BoxTextStyle? textStyle,
  }) : this(
         key: key,
         children: children,
         direction: direction,
         mainAlign: mainAlign,
         crossAlign: crossAlign ?? CrossAlign.stretch,
         gap: gap,
         flex: flex,
         overflow: overflow,
         width: width,
         height: height,
         margin: margin,
         padding: padding,
         transition: transition,
         hoverStyle: hoverStyle,
         stateStyles: stateStyles,
         enabled: enabled,
         semantics: semantics,
         onTap: onTap,
         onLongPress: onLongPress,
         onHover: onHover,
         borderRadius: borderRadius,
         textStyle: textStyle ?? _bodyOn(),
         color: color ?? const BoxColor.role(MaterialColorRole.surface),
         // No shadow is a statement, not the absence of one: `null` would fall through to
         // the primary constructor's `elevatedShadows`, and this shape casts none.
         shadows: shadows ?? const <BoxShadow>[],
         border:
             border ??
             BoxBorder(
               color: const BoxColor.role(MaterialColorRole.outlineVariant),
             ),
       );

  /// An elevated card: the `surfaceContainerLow` role with the level one shadow,
  /// which is the look the default constructor states.
  ///
  /// The whole parameter list, like [MaterialCard.filled].
  MaterialCard.elevated({
    Object? key,
    List<UINode> children = const <UINode>[],
    Axis? direction,
    MainAlign? mainAlign,
    CrossAlign? crossAlign,
    double? gap,
    int? flex,
    Overflow? overflow,
    double? width,
    double? height,
    BoxSpacing? margin,
    BoxSpacing padding = const BoxSpacing.all(16),
    BoxTransition? transition,
    BoxStyle? hoverStyle,
    Map<BoxState, BoxStyle>? stateStyles,
    bool enabled = true,
    BoxSemantics? semantics,
    TapCallback? onTap,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    BoxColor? color,
    List<BoxShadow>? shadows,
    BoxBorder? border,
    double borderRadius = 12,
    BoxTextStyle? textStyle,
  }) : this(
         key: key,
         children: children,
         direction: direction,
         mainAlign: mainAlign,
         crossAlign: crossAlign ?? CrossAlign.stretch,
         gap: gap,
         flex: flex,
         overflow: overflow,
         width: width,
         height: height,
         margin: margin,
         padding: padding,
         transition: transition,
         hoverStyle: hoverStyle,
         stateStyles: stateStyles,
         enabled: enabled,
         semantics: semantics,
         onTap: onTap,
         onLongPress: onLongPress,
         onHover: onHover,
         borderRadius: borderRadius,
         textStyle: textStyle ?? _bodyOn(),
         color:
             color ??
             const BoxColor.role(MaterialColorRole.surfaceContainerLow),
         shadows: shadows ?? elevatedShadows,
         border: border,
       );

  static BoxTextStyle _bodyOn() => MaterialTypography.bodyMedium.merge(
    BoxTextStyle(color: const BoxColor.role(MaterialColorRole.onSurface)),
  );

  /// `surfaceContainerLow` of the baseline light scheme: the elevated surface.
  ///
  /// It is a literal because a default parameter has to be a constant expression,
  /// and a field of a const object is not one. The test beside the card pins it to
  /// the palette role it names, so the two cannot drift apart.
  static const BoxColor _elevatedSurface = BoxColor.role(
    MaterialColorRole.surfaceContainerLow,
  );

  /// The drop shadows of elevation level one, the level Material gives a resting
  /// card.
  ///
  /// It is [MaterialElevation.level1] under the name a card reads best: one scale, so a
  /// card, a dialog and a sheet cannot drift into three different shadows. The shape is the
  /// ladder's in `shadows_material_3_pink_seed.png` — one shade, one height — so a card
  /// drawn from this tree sits at the height the design file gives it, which is a little
  /// tighter than a Flutter `Card`'s own `drawShadow`; how a shadow is *blurred* is still
  /// outside the parity contract, so the value states the shape of the shadow, not a pixel
  /// promise.
  static const List<BoxShadow> elevatedShadows = MaterialElevation.level1;

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'material-card';
}
