import 'package:unibox_core/unibox_core.dart';

/// Material 3's elevation levels, as the shadow each one casts.
///
/// The numbers are Flutter's own rather than a reading of the specification: the
/// framework states every level in `kElevationToShadow` (`package:flutter/material.dart`)
/// as three layers, and each constant here is that level's third — the *ambient*
/// layer, the wide soft one at 12% that reads as height. The other two are a tight
/// line under the edge and the penumbra beside it, which is what a [BoxBorder] states
/// more honestly than a second and third shadow would: a [BoxShadow] is one shadow,
/// and the model keeps it that way.
///
/// **A level is also a surface.** Material states elevation twice over — the shadow a
/// surface casts, and the tone it is tinted with — so [level1] goes with
/// `surfaceContainerLow`, [level2] with `surfaceContainer` and [level3] with
/// `surfaceContainerHigh`. Both halves are values in this package, a shadow here and a
/// role in [MaterialPalette], so a card names the pair and the catalogue beside it
/// shows the height the two make between them. A shadow alone is 12% black over a few
/// pixels: cast on a page of the same tone it barely reads.
///
/// The levels are what a component asks for by name — a card rests at [level1], a
/// dialog is raised at [level3] — so an application that replaces one of them
/// replaces it everywhere, and no component keeps a shadow of its own.
abstract final class MaterialElevation {
  /// Level one: a resting card, a sheet, a raised button.
  ///
  /// Flutter's `kElevationToShadow[1]`: `0 1px 3px` at 12%.
  static const BoxShadow level1 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x1F),
    offsetY: 1,
    blurRadius: 3,
  );

  /// Level two: a card under the pointer, a menu about to open.
  ///
  /// Flutter's `kElevationToShadow[2]`: `0 1px 5px` at 12%.
  static const BoxShadow level2 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x1F),
    offsetY: 1,
    blurRadius: 5,
  );

  /// Level three: a dialog, a date picker, a floating action button.
  ///
  /// Flutter's `kElevationToShadow[3]`: `0 1px 8px` at 12%.
  static const BoxShadow level3 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x1F),
    offsetY: 1,
    blurRadius: 8,
  );

  /// Level four: a navigation drawer under the pointer.
  ///
  /// Flutter's `kElevationToShadow[4]`: `0 1px 10px` at 12%.
  static const BoxShadow level4 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x1F),
    offsetY: 1,
    blurRadius: 10,
  );

  /// Level five: the highest surface Material states.
  ///
  /// Material's fifth level is five dp, which `kElevationToShadow` does not list, so
  /// this is the framework's next entry — `kElevationToShadow[6]`: `0 1px 18px` at 12%.
  static const BoxShadow level5 = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x1F),
    offsetY: 1,
    blurRadius: 18,
  );

  /// Level one, cast upwards: the shadow a sheet throws over the page it covers.
  ///
  /// A sheet leaves the bottom of the screen, so its height reads above it rather
  /// than below it — the one place Material mirrors a level instead of using it.
  static const BoxShadow sheet = BoxShadow(
    color: BoxColor.rgba(0, 0, 0, 0x1F),
    offsetY: -1,
    blurRadius: 3,
  );
}
