import 'package:unibox_core/unibox_core.dart';

import 'material_ink_well.dart';
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

/// A Material 3 button: a label on a fill, with the ink of a press.
///
/// ```dart
/// MaterialButton.filled(label: const TextNode('Create account'), onTap: save)
/// MaterialButton.outlined(label: const TextNode('Cancel'), onTap: close)
/// MaterialButton.text(label: const TextNode('Learn more'), onTap: open)
/// ```
///
/// It is a [Box] around a [MaterialInkWell], the way [MaterialListTile] is: the fill
/// is painted by the box, the hover, focus and press tints by the well *over* that
/// fill — so the colour of the button does not wash out under a tint — and the ink
/// starts where the press landed. Neither renderer has to know the name, and the
/// class adds no token the conformance table does not already pin.
///
/// **Every variant paints the same 40 pixels.** Material gives a button a minimum of
/// 64 by 40, and 40 is `labelLarge`'s 20 pixel line with ten above and ten below. The
/// three filled shapes state 24 across and that 10; the text shape is narrower, 12
/// across, which is what makes it read as quieter than the ones that carry a fill —
/// and its vertical room is the same ten, so it is the same height and a row of the
/// four lines up. A disabled button is drawn at 38% and takes no ink, which is what
/// the field does when it is disabled.
///
/// **Every measurement is a parameter.** `padding` is the room inside the fill,
/// `iconGap` the space between `icon` and the label, `borderRadius` the corner,
/// `minWidth` and `height` the size the fill may not go under, and `width` an exact
/// one. A minimum outranks a size on both targets — `min-width` beats `width` in CSS,
/// and a `ConstrainedBox` in Flutter clamps the same way — so `width: 40` on a button
/// is 64 wide on both. The label is centred in whatever the fill turns out to be,
/// which is what keeps a full-width button's label in the middle of it rather than
/// against its left edge.
///
/// **Every colour is a role**, so a dark theme restyles all four variants without a
/// parameter: `primary`/`onPrimary` for [MaterialButtonVariant.filled],
/// `primaryContainer`/`onPrimaryContainer` for [MaterialButtonVariant.tonal], and
/// `primary` with `outline` for the two that have no fill.
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
    BoxColor? ink,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
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
    ink: ink,
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
    BoxColor? ink,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
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
    ink: ink,
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
    BoxColor? ink,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
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
    ink: ink,
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
    BoxColor? ink,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
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
    ink: ink,
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
    BoxColor? ink,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
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
    ink: ink,
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
    BoxColor? ink,
    double borderRadius = _radius,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    double iconGap = _iconGap,
    BoxBorder? border,
    BoxSemantics? semantics,
    double? width,
    double? height,
    double minWidth = _minWidth,
    BoxSpacing? margin,
    BoxTransition? transition,
  }) {
    final BoxColor foreground = _foregroundOf(variant);
    final BoxColor? fill = _fillOf(variant);
    final BoxColor inkColor = ink ?? foreground;

    return MaterialButton._(
      key: key,
      label: label,
      fill: fill,
      // A line is what makes the outlined shape, and any shape may be given one.
      border:
          border ??
          (variant == MaterialButtonVariant.outlined ? _outline : null),
      borderRadius: borderRadius,
      width: width,
      height: height,
      minWidth: minWidth,
      margin: margin,
      inkWell: MaterialInkWell(
        onTap: onTap,
        url: url,
        newTab: newTab,
        onLongPress: onLongPress,
        onHover: onHover,
        enabled: enabled,
        borderRadius: borderRadius,
        ink: inkColor,
        padding: padding ?? _paddingOf(variant),
        transition: transition ?? MaterialInkWell.defaultTransition,
        semantics: semantics ?? _roleFor(onTap),
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
    double minWidth = _minWidth,
    required this.label,
    required UINode inkWell,
    BoxColor? fill,
    double borderRadius = _radius,
  }) : super(
         // A row around the button, so a parent that stretches its children — a
         // card's column, a grid track — has something invisible to stretch. The
         // fill and the ink well inside it keep the size the label asks for, which
         // is what stops a tint painting a band wider than the button it belongs
         // to. Passing [width] pins the fill instead of leaving it natural.
         direction: Axis.horizontal,
         crossAlign: CrossAlign.center,
         children: <UINode>[
           Box(
             width: width,
             height: height,
             // Material's minimum — a button is 64 by 40 whatever its label says —
             // and a minimum outranks a size on both targets, so a 40 pixel button
             // is still 64 wide. The label is centred in the result, which is what
             // keeps a pinned width's label in the middle instead of at its left.
             minWidth: minWidth,
             minHeight: _height,
             mainAlign: MainAlign.center,
             crossAlign: CrossAlign.center,
             backgroundColor: fill,
             borderRadius: borderRadius,
             border: border,
             children: <UINode>[inkWell],
           ),
         ],
       );

  /// The label the button draws.
  final UINode label;

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
    MaterialButtonVariant.tonal => const BoxColor.role(
      MaterialColorRole.primaryContainer,
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
          MaterialColorRole.onPrimaryContainer,
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
  static BoxSemantics? _roleFor(TapCallback? onTap) =>
      onTap == null ? null : const BoxSemantics(role: BoxRole.button);

  /// The name this node answers to in an inspector.
  @override
  String? get debugLabel => 'material-button';
}
