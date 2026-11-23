import 'package:unibox_core/unibox_core.dart';

import 'material_elevation.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// A Material card declaration for server HTML and Flutter's native `Card`.
///
/// Flutter hosts install the Material substitution map. Application actions belong
/// to a host-owned surface inside the card; this component declares content and paint.
final class MaterialCard extends Box {
  /// Creates a card with shared surface, spacing and content declarations.
  ///
  /// Application actions belong to a host-owned surface inside the card.
  const MaterialCard({
    super.key,
    super.children,
    super.direction,
    super.mainAlign,
    CrossAlign crossAlign = CrossAlign.stretch,
    super.gap,
    super.flex,
    super.overflow,
    super.pin,
    super.pinOffset,
    super.width,
    super.height,
    super.margin,
    super.transition,
    super.fold,
    super.hoverStyle,
    super.stateStyles,
    super.enabled,
    super.semantics,
    super.shadows = elevatedShadows,
    super.border,
    super.padding,
    BoxColor color = _elevatedSurface,
    double borderRadius = 12,
    BoxTextStyle textStyle = MaterialTypography.bodyMedium,
  }) : super(
         crossAlign: crossAlign,
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
    BoxPin? pin,
    double? pinOffset,
    double? width,
    double? height,
    BoxSpacing? margin,
    BoxSpacing? padding,
    BoxTransition? transition,
    BoxStyle? hoverStyle,
    Map<BoxState, BoxStyle>? stateStyles,
    bool enabled = true,
    BoxSemantics? semantics,
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
         pin: pin,
         pinOffset: pinOffset,
         width: width,
         height: height,
         margin: margin,
         padding: padding,
         transition: transition,
         hoverStyle: hoverStyle,
         stateStyles: stateStyles,
         enabled: enabled,
         semantics: semantics,
         borderRadius: borderRadius,
         textStyle: textStyle ?? _bodyOn(),
         color:
             color ??
             const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
         // Level zero, named rather than left to an empty list of its own: `null` would
         // fall through to the primary constructor's `elevatedShadows`, and this shape
         // casts none.
         shadows: shadows ?? MaterialElevation.level0,
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
    BoxPin? pin,
    double? pinOffset,
    double? width,
    double? height,
    BoxSpacing? margin,
    BoxSpacing? padding,
    BoxTransition? transition,
    BoxStyle? hoverStyle,
    Map<BoxState, BoxStyle>? stateStyles,
    bool enabled = true,
    BoxSemantics? semantics,
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
         pin: pin,
         pinOffset: pinOffset,
         width: width,
         height: height,
         margin: margin,
         padding: padding,
         transition: transition,
         hoverStyle: hoverStyle,
         stateStyles: stateStyles,
         enabled: enabled,
         semantics: semantics,
         borderRadius: borderRadius,
         textStyle: textStyle ?? _bodyOn(),
         color: color ?? const BoxColor.role(MaterialColorRole.surface),
         // Level zero, named rather than left to an empty list of its own: `null` would
         // fall through to the primary constructor's `elevatedShadows`, and this shape
         // casts none.
         shadows: shadows ?? MaterialElevation.level0,
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
    BoxPin? pin,
    double? pinOffset,
    double? width,
    double? height,
    BoxSpacing? margin,
    BoxSpacing? padding,
    BoxTransition? transition,
    BoxStyle? hoverStyle,
    Map<BoxState, BoxStyle>? stateStyles,
    bool enabled = true,
    BoxSemantics? semantics,
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
         pin: pin,
         pinOffset: pinOffset,
         width: width,
         height: height,
         margin: margin,
         padding: padding,
         transition: transition,
         hoverStyle: hoverStyle,
         stateStyles: stateStyles,
         enabled: enabled,
         semantics: semantics,
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

  /// Native widget rendering is required on Flutter.
  @override
  bool get requiresWidgetSubstitution => true;

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'material-card';
}
