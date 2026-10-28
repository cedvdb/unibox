import 'package:unibox_core/unibox_core.dart';

/// Material 3's elevation levels, as the shadow each one casts.
///
/// Material states a level as two layers — `0 1px 2px` at 30% over `0 1px 3px 1px`
/// at 15% for level one — and a [BoxShadow] is one shadow, so each level here is the
/// *second* layer: the wide, soft one, which is what reads as height. The first
/// layer is a hairline the model gets from `BoxBorder` when a design wants it.
///
/// The levels are what a component asks for by name — a card rests at [level1], a
/// dialog is raised at [level3] — so an application that replaces one of them
/// replaces it everywhere, and no component keeps a shadow of its own.
abstract final class MaterialElevation {
  /// Level one: a resting card, a sheet, a raised button.
  static const BoxShadow level1 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x26),
    offsetY: 1,
    blurRadius: 3,
  );

  /// Level two: a hovered card, a menu about to open.
  static const BoxShadow level2 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x26),
    offsetY: 2,
    blurRadius: 6,
  );

  /// Level three: a dialog, a date picker, a floating action button.
  static const BoxShadow level3 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x26),
    offsetY: 4,
    blurRadius: 8,
  );

  /// Level four: a navigation drawer under the pointer.
  static const BoxShadow level4 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x26),
    offsetY: 6,
    blurRadius: 10,
  );

  /// Level five: the highest surface Material states.
  static const BoxShadow level5 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x26),
    offsetY: 8,
    blurRadius: 12,
  );

  /// Level one, cast upwards: the shadow a sheet throws over the page it covers.
  ///
  /// A sheet leaves the bottom of the screen, so its height reads above it rather
  /// than below it — the one place Material mirrors a level instead of using it.
  static const BoxShadow sheet = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x26),
    offsetY: -1,
    blurRadius: 3,
  );
}
