import 'package:unibox_core/unibox_core.dart';

import 'material_density.dart';
import 'material_surface.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// The shapes Material 3 gives a button.
///
/// The four differ in three things only — the fill, the label colour and whether
/// there is a line around them — so they are one node with four named constructors
/// rather than four classes.
enum MaterialButtonVariant {
  /// The accent fill: the one action of a screen.
  filled,

  /// The softer fill, for a secondary action beside [filled].
  tonal,

  /// No fill, an outline: an action beside the others without weight.
  outlined,

  /// No fill and no line: the quietest action, and the one a dialog uses.
  text,
}

/// A Material button declaration with a native Flutter substitution.
///
/// The application supplies actions and destinations; no store or ink runtime
/// is created. The HTML declaration exposes the same content and design values.
final class MaterialButton extends Box {
  /// Creates a filled button around [label].
  factory MaterialButton({
    Object? key,
    required UINode label,
    UINode? icon,
    TapCallback? onTap,
    String? url,
    bool newTab = false,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
    MaterialDensity density = MaterialDensity.standard,
    BoxBorder? border,
    BoxSemantics? semantics,
    double? width,
    double? height,
    double minWidth = _minWidth,
    BoxSpacing? margin,
    BoxTransition? transition,
  }) => MaterialButton.variant(
    MaterialButtonVariant.filled,
    key: key,
    label: label,
    icon: icon,
    onTap: onTap,
    url: url,
    newTab: newTab,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    borderRadius: borderRadius,
    padding: padding,
    labelStyle: labelStyle,
    iconGap: iconGap,
    border: border,
    semantics: semantics,
    width: width,
    height: height,
    minWidth: minWidth,
    margin: margin,
    transition: transition,
    density: density,
  );

  /// A filled button, named for symmetry with the other three.
  ///
  /// It is the same button as the unnamed constructor, which is the default because
  /// it is the one a screen has.
  factory MaterialButton.filled({
    Object? key,
    required UINode label,
    UINode? icon,
    TapCallback? onTap,
    String? url,
    bool newTab = false,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
    MaterialDensity density = MaterialDensity.standard,
    BoxBorder? border,
    BoxSemantics? semantics,
    double? width,
    double? height,
    double minWidth = _minWidth,
    BoxSpacing? margin,
    BoxTransition? transition,
  }) => MaterialButton(
    key: key,
    label: label,
    icon: icon,
    onTap: onTap,
    url: url,
    newTab: newTab,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    borderRadius: borderRadius,
    padding: padding,
    labelStyle: labelStyle,
    iconGap: iconGap,
    border: border,
    semantics: semantics,
    width: width,
    height: height,
    minWidth: minWidth,
    margin: margin,
    transition: transition,
    density: density,
  );

  /// A tonal button: the softer fill Material gives a secondary action.
  factory MaterialButton.tonal({
    Object? key,
    required UINode label,
    UINode? icon,
    TapCallback? onTap,
    String? url,
    bool newTab = false,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
    MaterialDensity density = MaterialDensity.standard,
    BoxBorder? border,
    BoxSemantics? semantics,
    double? width,
    double? height,
    double minWidth = _minWidth,
    BoxSpacing? margin,
    BoxTransition? transition,
  }) => MaterialButton.variant(
    MaterialButtonVariant.tonal,
    key: key,
    label: label,
    icon: icon,
    onTap: onTap,
    url: url,
    newTab: newTab,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    borderRadius: borderRadius,
    padding: padding,
    labelStyle: labelStyle,
    iconGap: iconGap,
    border: border,
    semantics: semantics,
    width: width,
    height: height,
    minWidth: minWidth,
    margin: margin,
    transition: transition,
    density: density,
  );

  /// An outlined button: an action beside the filled ones, without weight.
  factory MaterialButton.outlined({
    Object? key,
    required UINode label,
    UINode? icon,
    TapCallback? onTap,
    String? url,
    bool newTab = false,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
    MaterialDensity density = MaterialDensity.standard,
    BoxBorder? border,
    BoxSemantics? semantics,
    double? width,
    double? height,
    double minWidth = _minWidth,
    BoxSpacing? margin,
    BoxTransition? transition,
  }) => MaterialButton.variant(
    MaterialButtonVariant.outlined,
    key: key,
    label: label,
    icon: icon,
    onTap: onTap,
    url: url,
    newTab: newTab,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    borderRadius: borderRadius,
    padding: padding,
    labelStyle: labelStyle,
    iconGap: iconGap,
    border: border,
    semantics: semantics,
    width: width,
    height: height,
    minWidth: minWidth,
    margin: margin,
    transition: transition,
    density: density,
  );

  /// A text button: no fill and no line, the quietest action.
  factory MaterialButton.text({
    Object? key,
    required UINode label,
    UINode? icon,
    TapCallback? onTap,
    String? url,
    bool newTab = false,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
    MaterialDensity density = MaterialDensity.standard,
    BoxBorder? border,
    BoxSemantics? semantics,
    double? width,
    double? height,
    double minWidth = _minWidth,
    BoxSpacing? margin,
    BoxTransition? transition,
  }) => MaterialButton.variant(
    MaterialButtonVariant.text,
    key: key,
    label: label,
    icon: icon,
    onTap: onTap,
    url: url,
    newTab: newTab,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    borderRadius: borderRadius,
    padding: padding,
    labelStyle: labelStyle,
    iconGap: iconGap,
    border: border,
    semantics: semantics,
    width: width,
    height: height,
    minWidth: minWidth,
    margin: margin,
    transition: transition,
    density: density,
  );

  /// Creates a button of [variant].
  ///
  /// It is the one constructor the four named ones forward to, so the variant table
  /// is written once: fill, label, line and ink.
  factory MaterialButton.variant(
    MaterialButtonVariant variant, {
    Object? key,
    required UINode label,
    UINode? icon,
    TapCallback? onTap,
    String? url,
    bool newTab = false,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
    MaterialDensity density = MaterialDensity.standard,
    BoxBorder? border,
    BoxSemantics? semantics,
    double? width,
    double? height,
    double minWidth = _minWidth,
    BoxSpacing? margin,
    BoxTransition? transition,
  }) {
    final BoxColor foreground = _foregroundOf(variant);
    // The room inside the pill is Material's density too: compact takes four pixels off each
    // side, which is what turns a 40 pixel button into a 32 one on a desk. A floor alone
    // cannot do it — the padding and the label already add up to 40.
    final BoxSpacing insets = _roomFor(padding ?? _paddingOf(variant), density);
    final BoxColor? fill = _fillOf(variant);

    return MaterialButton._(
      key: key,
      label: label,
      variant: variant,
      icon: icon,
      enabled: enabled,
      onPressed: onTap,
      onLongPress: onLongPress,
      onHover: onHover,
      controlStyle: BoxStyle(
        width: width,
        height: height,
        minWidth: minWidth,
        minHeight: height ?? density.adjust(_height),
        padding: insets,
        backgroundColor: fill,
        border:
            border ??
            (variant == MaterialButtonVariant.outlined ? _outline : null),
        borderRadius: borderRadius,
        textStyle:
            labelStyle ??
            MaterialTypography.labelLarge.merge(
              BoxTextStyle(color: foreground),
            ),
      ),
      url: url,
      fill: fill,
      // A line is what makes the outlined shape, and any shape may be given one.
      border:
          border ??
          (variant == MaterialButtonVariant.outlined ? _outline : null),
      borderRadius: borderRadius,
      width: width,
      height: height,
      density: density,
      margin: margin,
      surface: materialSurface(
        onTap: onTap,
        url: url,
        newTab: newTab,
        onLongPress: onLongPress,
        onHover: onHover,
        enabled: enabled,
        borderRadius: borderRadius,
        padding: insets,
        transition: transition ?? materialSurfaceTransition,
        semantics: semantics ?? _roleFor(onTap),
        // The press is the size of the pill: a pinned width and height are the well's,
        // and so is the floor, so no part of the pill is a look without a target.
        width: width,
        height: height,
        minWidth: minWidth,
        // The height Material paints, at the density this platform draws at — unless the
        // caller stated one, which is the tree's answer and wins.
        minHeight: height ?? density.adjust(_height),
        // A well that is wider or taller than its label centres it, exactly as the fill
        // used to: a 64 pixel pill centres a 46 pixel label.
        mainAlign: MainAlign.center,
        crossAlign: CrossAlign.center,
        child: _labelOf(
          label: label,
          icon: icon,
          gap: iconGap,
          style:
              labelStyle ??
              MaterialTypography.labelLarge.merge(
                BoxTextStyle(color: foreground),
              ),
        ),
      ),
    );
  }

  MaterialButton._({
    super.key,
    super.margin,
    BoxBorder? border,
    double? width,
    double? height,
    required this.label,
    required this.variant,
    required this.onPressed,
    required this.controlStyle,
    super.onLongPress,
    super.onHover,
    this.url,
    required this.density,
    super.enabled,
    this.icon,
    required UINode surface,
    BoxColor? fill,
    double borderRadius = _radius,
  }) : super(
         // A row around the button, so a parent that stretches its children — a
         // card's column, a grid track — has something invisible to stretch. The
         // fill and the ink well inside it keep the size the label asks for, which
         // is what stops a tint painting a bar wider than the button it belongs
         // to. Passing [width] pins the fill instead of leaving it natural.
         direction: Axis.horizontal,
         crossAlign: CrossAlign.center,
         children: <UINode>[
           Box(
             width: width,
             height: height,
             // The minimum is the well's, not the fill's: a floor stated here would paint
             // a pill bigger than the box that takes the press, and the ends of a button
             // would look pressable and be dead. The fill hugs the press instead, and
             // centres it, which is what keeps a pinned width's label in the middle.
             mainAlign: MainAlign.center,
             crossAlign: CrossAlign.center,
             backgroundColor: fill,
             borderRadius: borderRadius,
             border: border,
             children: <UINode>[surface],
           ),
         ],
       );

  /// The destination opened by the native host when no action overrides it.
  final String? url;

  /// The declared control dimensions and paint read by the native mapping.
  final BoxStyle controlStyle;

  /// The label the button draws.
  final UINode label;

  /// The shape it was made in, which is what a host drawing the platform's own button reads
  /// to pick one of four widgets.
  final MaterialButtonVariant variant;

  /// The glyph before the label, when the button has one.
  final UINode? icon;

  /// The density the pill is drawn at, which is what its height is computed from.
  final MaterialDensity density;

  /// What a press does, under the name a platform's button gives it.
  ///
  /// The callback is handed to the ink well, which is the node that takes the press — this is
  /// the same one kept on the button, because a host drawing the platform's own button reads
  /// it as `onPressed` and cannot reach inside the well.
  final TapCallback? onPressed;

  /// The height every variant paints: `labelLarge`'s 20 pixel line with ten above
  /// and below, which is Material's own 40 and the reason a text button and a
  /// filled one line up in a row.
  static const double _height = 40;

  /// The corner radius Material gives a button: a full round on a 40 pixel height.
  static const double _radius = 20;

  /// The narrowest a button paints, whatever its label says: Material's minimum
  /// width, so a short label is a 64 pixel target rather than a 30 pixel one.
  static const double _minWidth = 64;

  /// The space between the icon and the label: Material's own gap in a button.
  static const double _iconGap = 8;

  /// The line around an outlined button.
  static const BoxBorder _outline = BoxBorder(
    color: BoxColor.role(MaterialColorRole.outline),
  );

  /// The room inside the pill at [density]: compact takes four pixels off above and below,
  /// which is the half of Flutter's answer a minimum height cannot state.
  static BoxSpacing _roomFor(BoxSpacing padding, MaterialDensity density) {
    if (density == MaterialDensity.standard) {
      return padding;
    }

    final double drop = -density.vertical * 2;

    return BoxSpacing.only(
      top: padding.top - drop,
      bottom: padding.bottom - drop,
      left: padding.left,
      right: padding.right,
    );
  }

  /// The label of the button, with [icon] beside it when there is one.
  static UINode _labelOf({
    required UINode label,
    required UINode? icon,
    required double gap,
    required BoxTextStyle style,
  }) {
    // Typography is the one inherited axis, so the label's role and colour are
    // stated once on the box around it rather than pushed into every text.
    if (icon == null) {
      return Box(textStyle: style, children: <UINode>[label]);
    }

    return Box(
      direction: Axis.horizontal,
      crossAlign: CrossAlign.center,
      gap: gap,
      textStyle: style,
      children: <UINode>[icon, label],
    );
  }

  /// The fill of [variant], or `null` for the two that have none.
  static BoxColor? _fillOf(MaterialButtonVariant variant) => switch (variant) {
    MaterialButtonVariant.filled => const BoxColor.role(
      MaterialColorRole.primary,
    ),
    // Flutter's own tonal button is the secondary container: the softer fill beside a
    // filled one, not the primary one at a lighter weight.
    MaterialButtonVariant.tonal => const BoxColor.role(
      MaterialColorRole.secondaryContainer,
    ),
    MaterialButtonVariant.outlined => null,
    MaterialButtonVariant.text => null,
  };

  /// The colour the label is drawn in, and the ink a press leaves.
  static BoxColor _foregroundOf(MaterialButtonVariant variant) =>
      switch (variant) {
        MaterialButtonVariant.filled => const BoxColor.role(
          MaterialColorRole.onPrimary,
        ),
        MaterialButtonVariant.tonal => const BoxColor.role(
          MaterialColorRole.onSecondaryContainer,
        ),
        MaterialButtonVariant.outlined => const BoxColor.role(
          MaterialColorRole.primary,
        ),
        MaterialButtonVariant.text => const BoxColor.role(
          MaterialColorRole.primary,
        ),
      };

  /// The room Material gives [variant] around its label.
  ///
  /// Twenty-four across on the three filled shapes is Material's own, and ten above
  /// and below is the vertical half of its 40 pixel minimum — the label's line is 20,
  /// so the two together are the height. The text shape is narrower, 12 across, which
  /// is what makes it the quietest of the four; its vertical room is the same ten, so
  /// it is the same 40 pixels tall and a row of all four lines up.
  static BoxSpacing _paddingOf(MaterialButtonVariant variant) =>
      switch (variant) {
        MaterialButtonVariant.filled ||
        MaterialButtonVariant.tonal ||
        MaterialButtonVariant.outlined => const BoxSpacing.symmetric(
          horizontal: 24,
          vertical: 10,
        ),
        MaterialButtonVariant.text => const BoxSpacing.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      };

  /// The role a button announces, which is a button when it can be tapped.
  static BoxSemantics _roleFor(TapCallback? onTap) =>
      const BoxSemantics(role: BoxRole.button);

  /// Native widget rendering is required on Flutter.
  @override
  bool get requiresWidgetSubstitution => true;

  /// The name this node answers to in an inspector.
  @override
  String? get debugLabel => 'material-button';
}
