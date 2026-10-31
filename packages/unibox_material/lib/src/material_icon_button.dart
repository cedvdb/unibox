import 'package:unibox_core/unibox_core.dart';

import 'material_ink_well.dart';
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

/// A Material 3 icon button: one glyph in a 40 pixel square, with the ink of a press.
///
/// ```dart
/// MaterialIconButton(
///   icon: MaterialIcon.ligature('tune'),
///   label: 'Filters',
///   onTap: openFilters,
/// )
/// MaterialIconButton(
///   icon: MaterialIcon.ligature('notifications'),
///   label: 'Notifications',
///   badgeCount: 3,
///   onTap: openInbox,
/// )
/// ```
///
/// It is a [Box] around a [MaterialInkWell], the way [MaterialButton] is: the fill and the
/// line are the well's surface, the hover, focus and press tints are the well's, over that
/// surface, and the ink starts where the press landed. Neither renderer has to know the
/// name, and the class adds no token the conformance table does not already pin.
///
/// **The square is Material's, and it is a parameter.** A control with no text has to be
/// big enough to hit: 40 by 40 with a 24 pixel glyph, which is what Material states for a
/// touch target. [height] and [width] are the square — a control that names only a height
/// is as wide as it is tall — [iconSize] is the room the glyph is centred in, [padding]
/// the space inside the fill, and [borderRadius] the corner, a full round by default.
/// [ink] is the splash and [transition] the easing of the tints.
///
/// **Every colour is a role**, so a dark theme restyles all four variants without a
/// parameter: `primary`/`onPrimary` for [MaterialIconButtonVariant.filled],
/// `secondaryContainer`/`onSecondaryContainer` for [MaterialIconButtonVariant.tonal],
/// `onSurfaceVariant` for the glyph of the other two, and `outline` for the line of
/// [MaterialIconButtonVariant.outlined].
///
/// **[badgeCount] is a pill over the corner of the glyph** — `error` behind, `onError` in
/// front, 16 pixels tall and as wide as the number needs — placed where the top right of
/// the glyph is, so a counter sits over the icon it counts rather than beside it. It is a
/// picture: it is hidden from a screen reader, because a count is a fact the control's own
/// name should carry — `label: 'Notifications, 3 unread'`.
///
/// **What Material draws that this does not.** A toggle icon button states
/// `aria-pressed` and changes its shape when it is on; this node has one shape, so a
/// toggle is the caller's rebuild — the store picks the variant — and it announces no
/// pressed state, because a `pressed` no view can change is a state a reader is told
/// wrongly. Material also draws a tooltip, an icon theme the glyph inherits, and a badge
/// that scales in: a tooltip is platform chrome, the glyph's size is its own token, and a
/// scale is a transition this model can say, so a caller who wants either draws it. The
/// ripple is the ink's, drawn from boxes rather than by the platform, so both targets
/// paint it the same way.
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
    bool enabled = true,
    int? badgeCount,
    MaterialIconButtonVariant variant = MaterialIconButtonVariant.standard,
    double height = controlHeight,
    double? width,
    BoxSpacing? padding,
    double iconSize = defaultIconSize,
    double borderRadius = radius,
    BoxColor? ink,
    BoxTransition? transition,
    super.margin,
    super.key,
  }) : super(
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
             onTap: onTap,
             url: url,
             newTab: newTab,
             enabled: enabled,
             badgeCount: badgeCount,
             variant: variant,
             height: height,
             width: width ?? height,
             padding: padding,
             iconSize: iconSize,
             borderRadius: borderRadius,
             ink: ink,
             transition: transition,
           ),
         ],
       );

  /// The height Material gives an icon button: the smallest square a finger is aimed at.
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
    required BoxColor? ink,
    required BoxTransition? transition,
  }) {
    final BoxColor foreground = _foregroundOf(variant);

    final UINode target = MaterialInkWell(
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
      border: variant == MaterialIconButtonVariant.outlined ? _outline : null,
      ink: ink ?? foreground,
      padding: padding ?? const BoxSpacing.all(_inset),
      transition: transition ?? MaterialInkWell.defaultTransition,
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

  /// The name this node answers to in an inspector.
  @override
  String? get debugLabel => 'material-icon-button';
}
