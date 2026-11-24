import 'package:unibox_core/unibox_core.dart';

import 'material_density.dart';
import 'material_surface.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// The shapes Material 3 gives an icon button.
///
/// The four differ in two things only — the fill and the colour of the glyph — so they
/// are one node with a variant rather than four classes, exactly as the four button
/// shapes are.
enum MaterialIconButtonVariant {
  /// No fill and no line: an action in a toolbar or a header.
  standard,

  /// The accent fill: the one action of a surface.
  filled,

  /// The softer fill, for a secondary action beside [filled].
  tonal,

  /// No fill, a line: an action that has to be seen as a button.
  outlined,
}

/// An icon action declaration rendered by a native Flutter icon button.
///
/// The host supplies the glyph and action. Server HTML retains its accessible name.
final class MaterialIconButton extends Box {
  /// Creates an icon button around [icon].
  ///
  /// [label] is what a screen reader says when the control is reached, because a glyph
  /// with no text beside it names nothing; [onTap] is what a press runs, and [enabled]
  /// recalls it without moving the square.
  MaterialIconButton({
    required UINode icon,
    String? label,
    TapCallback? onTap,
    String? url,
    bool newTab = false,
    super.enabled,
    int? badgeCount,
    MaterialIconButtonVariant variant = MaterialIconButtonVariant.standard,
    double height = controlHeight,
    double? width,
    BoxSpacing? padding,
    double iconSize = defaultIconSize,
    double borderRadius = radius,
    BoxTransition? transition,
    MaterialDensity density = MaterialDensity.standard,
    super.margin,
    super.key,
  }) : icon = icon,
       label = label,
       onPressed = onTap,
       url = url,
       badgeCount = badgeCount,
       variant = variant,
       controlStyle = BoxStyle(
         width: width ?? density.adjust(height),
         height: density.adjust(height),
         borderRadius: borderRadius,
         padding: padding ?? const BoxSpacing.all(_inset),
         backgroundColor: _fillOf(variant),
         border: variant == MaterialIconButtonVariant.outlined
             ? _outline
             : null,
       ),
       super(
         // A row around the control, so a parent that stretches its children — a card's
         // column, a grid track — has something invisible to stretch without widening the
         // square itself.
         direction: Axis.horizontal,
         crossAlign: CrossAlign.center,
         // A disabled icon button fades rather than changing role: Material draws the
         // glyph at 38%, and one opacity is what this model can say without an alpha role
         // per token.
         opacity: enabled ? null : 0.38,
         children: <UINode>[
           _control(
             icon: icon,
             label: label,
             density: density,
             onTap: onTap,
             url: url,
             newTab: newTab,
             enabled: enabled,
             badgeCount: badgeCount,
             variant: variant,
             height: density.adjust(height),
             width: width ?? density.adjust(height),
             padding: padding,
             iconSize: iconSize,
             borderRadius: borderRadius,
             transition: transition,
           ),
         ],
       );

  /// The declared control dimensions and paint used by the native widget.
  final BoxStyle controlStyle;

  /// The destination opened by the native host when no action overrides it.
  final String? url;

  /// The height Material gives an icon button: the smallest square a finger is aimed at.
  /// The glyph the control draws.
  final UINode icon;

  /// What a reader calls the control, when the glyph is not a label.
  final String? label;

  /// What a press does, under the name a platform's control gives it.
  final TapCallback? onPressed;

  /// The count over the corner, when the control carries one.
  final int? badgeCount;

  /// The shape it was made in: bare, filled, tonal or outlined.
  final MaterialIconButtonVariant variant;

  static const double controlHeight = 40;

  /// The size Material draws an icon at, and the square this control centres it in.
  static const double defaultIconSize = 24;

  /// The corner radius of a 40 pixel icon button, which is a full round.
  static const double radius = 20;

  /// The height of the badge, and its width before a number wider than one digit.
  static const double _badgeSize = 16;

  /// The line around an outlined icon button.
  static const BoxBorder _outline = BoxBorder(
    color: BoxColor.role(MaterialColorRole.outline),
  );

  /// The square, its ink, and the badge over its corner when there is a count.
  static UINode _control({
    required MaterialDensity density,
    required UINode icon,
    required String? label,
    required TapCallback? onTap,
    required String? url,
    required bool newTab,
    required bool enabled,
    required int? badgeCount,
    required MaterialIconButtonVariant variant,
    required double height,
    required double width,
    required BoxSpacing? padding,
    required double iconSize,
    required double borderRadius,
    required BoxTransition? transition,
  }) {
    final BoxColor foreground = _foregroundOf(variant);

    final UINode target = materialSurface(
      onTap: onTap,
      url: url,
      newTab: newTab,
      enabled: enabled,
      width: width,
      height: height,
      borderRadius: borderRadius,
      // The surface is the well's, so the tints are layered *over* the fill rather than
      // under it, and the ink is clipped to the rounded square.
      fill: _fillOf(variant),
      // The layer is a tint of the glyph, which is Material's rule for a control whose only
      // content is an icon.
      ink: foreground,
      border: variant == MaterialIconButtonVariant.outlined ? _outline : null,
      padding: padding ?? const BoxSpacing.all(_inset),
      transition: transition ?? materialSurfaceTransition,
      semantics: BoxSemantics(
        role: BoxRole.button,
        label: label,
        // A control whose only content is a glyph announces the name it was given: the
        // glyph beside it is a picture of that name, not a second name.
        hidden: label == null,
      ),
      child: Box(
        width: iconSize,
        height: iconSize,
        mainAlign: MainAlign.center,
        crossAlign: CrossAlign.center,
        textStyle: BoxTextStyle(color: foreground),
        children: <UINode>[icon],
      ),
    );

    if (badgeCount == null || badgeCount <= 0) {
      return target;
    }

    // The badge is placed in the square, not added to it: a count over the corner must
    // not make the control wider than the finger it was sized for.
    return StackNode(
      width: width,
      height: height,
      children: <UINode>[target, _badge(badgeCount)],
    );
  }

  /// The count, in a pill over the top right corner of the square.
  ///
  /// The badge is pinned to the end of the *square*, which is where the glyph's corner
  /// is once the 8 pixel inset is taken off: a 16 pixel pill in the corner of a 40 pixel
  /// control sits over the last 16 pixels of the glyph rather than in the middle of the
  /// padding. It is hidden from a screen reader — a count nobody is told is a picture,
  /// and the control's own [label] is where the fact belongs — and it takes no pointer,
  /// so the corner it covers is the control's: the same hover, the same hand, the same
  /// press and the same ink.
  static UINode _badge(int count) => PositionedNode(
    alignment: BoxAlignment.topEnd,
    child: Box(
      height: _badgeSize,
      minWidth: _badgeSize,
      borderRadius: _badgeSize / 2,
      padding: const BoxSpacing.symmetric(horizontal: 4),
      backgroundColor: const BoxColor.role(MaterialColorRole.error),
      mainAlign: MainAlign.center,
      crossAlign: CrossAlign.center,
      semantics: const BoxSemantics(hidden: true),
      capturesPointer: false,
      textStyle: MaterialTypography.labelSmall.copyWith(
        color: const BoxColor.role(MaterialColorRole.onError),
      ),
      children: <UINode>[TextNode('$count', maxLines: 1)],
    ),
  );

  /// The room inside the fill: a 24 pixel glyph centred in 40 leaves 8 on each side.
  static const double _inset = (controlHeight - defaultIconSize) / 2;

  /// The fill of [variant], or `null` for the two that have none.
  static BoxColor? _fillOf(MaterialIconButtonVariant variant) =>
      switch (variant) {
        MaterialIconButtonVariant.standard => null,
        MaterialIconButtonVariant.filled => const BoxColor.role(
          MaterialColorRole.primary,
        ),
        MaterialIconButtonVariant.tonal => const BoxColor.role(
          MaterialColorRole.secondaryContainer,
        ),
        MaterialIconButtonVariant.outlined => null,
      };

  /// The colour the glyph is drawn in, and the ink a press leaves.
  static BoxColor _foregroundOf(MaterialIconButtonVariant variant) =>
      switch (variant) {
        MaterialIconButtonVariant.standard ||
        MaterialIconButtonVariant.outlined => const BoxColor.role(
          MaterialColorRole.onSurfaceVariant,
        ),
        MaterialIconButtonVariant.filled => const BoxColor.role(
          MaterialColorRole.onPrimary,
        ),
        MaterialIconButtonVariant.tonal => const BoxColor.role(
          MaterialColorRole.onSecondaryContainer,
        ),
      };

  /// Native widget rendering is required on Flutter.
  @override
  bool get requiresWidgetSubstitution => true;

  /// The name this node answers to in an inspector.
  @override
  String? get debugLabel => 'material-icon-button';
}
