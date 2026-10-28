import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// A Material 3 state layer around [child]: the tint that makes a region read as
/// tappable, drawn as a [Box].
///
/// ```dart
/// MaterialInkWell(
///   onTap: openContact,
///   borderRadius: 12,
///   child: const TextNode('Ada Lovelace'),
/// )
/// ```
///
/// It adds no renderer work: it *is* a box, so both targets draw it with the
/// renderer they already have. What the class buys is the combination — the three
/// state layers Material paints over a surface, a short transition so a tint eases
/// instead of flashing, and the button role when the region can be tapped.
///
/// **It paints no surface of its own.** The tint has to sit *above* the fill it
/// belongs to, so the filled box goes around the ink well, not inside it; wrapped
/// the other way round the fill would hide the state layer. That is why the
/// examples that need a button wrap one of these in a box with a colour.
///
/// **What it is not.** It is not a ripple: the ink splash starts at the pointer and
/// grows over a timeline of its own, which the model has no triggered animation
/// for, so a press is a tint. Every colour is a [MaterialColorRole], so a dark
/// scheme is the host's theme rather than a parameter here.
final class MaterialInkWell extends Box {
  /// Creates a region that tints on hover, focus and press around [child].
  ///
  /// `onTap` is read here instead of being passed straight through, because a
  /// tappable region is what gets the button role.
  // ignore: use_super_parameters
  MaterialInkWell({
    super.key,
    required UINode child,
    TapCallback? onTap,
    super.onLongPress,
    super.onHover,
    super.enabled,
    super.margin,
    super.padding,
    super.width,
    super.height,
    super.flex,
    super.borderRadius,
    BoxSemantics? semantics,
    BoxTransition transition = defaultTransition,
    BoxStyle? hoverStyle,
    BoxStyle? focusStyle,
    BoxStyle? pressedStyle,
  }) : super(
         transition: transition,
         onTap: onTap,
         semantics:
             semantics ??
             (onTap == null ? null : const BoxSemantics(role: BoxRole.button)),
         hoverStyle:
             hoverStyle ??
             _tint(const BoxColor.role(MaterialColorRole.hoverLayer)),
         stateStyles: <BoxState, BoxStyle>{
           BoxState.focus:
               focusStyle ??
               _tint(const BoxColor.role(MaterialColorRole.focusLayer)),
           BoxState.pressed:
               pressedStyle ??
               _tint(const BoxColor.role(MaterialColorRole.pressedLayer)),
         },
         children: <UINode>[child],
       );

  /// The easing of the tint: Material's short fade, so a state change is not a
  /// flash.
  static const BoxTransition defaultTransition = BoxTransition(
    duration: Duration(milliseconds: 100),
  );

  /// [color] as the background of a state style.
  static BoxStyle _tint(BoxColor color) => BoxStyle(backgroundColor: color);
}
