import 'package:unibox_core/unibox_core.dart';

/// Material 3's elevation levels, as the shadow each one casts.
///
/// The numbers are Flutter's own, not a reading of the specification: every level here
/// is an entry of `kElevationToShadow` (`package:flutter/material.dart`) — the map
/// `Material` itself draws from — layer for layer, from the umbra at the edge through the
/// penumbra to the wide ambient layer. Material states three layers per level and a
/// [Box] takes a list of [BoxShadow]s for exactly this reason, so a card drawn on the
/// web and a card drawn by Flutter are the same three shadows over the same surface.
///
/// **A level is also a surface.** Material states elevation twice over — the shadow a
/// surface casts, and the tone it is tinted with — so [level1] goes with
/// `surfaceContainerLow`, [level2] with `surfaceContainer` and [level3] with
/// `surfaceContainerHigh`. Both halves are values in this package, shadows here and a
/// role in [MaterialPalette], so a card names the pair and the catalogue beside it
/// shows the height the two make between them.
///
/// The levels are what a component asks for by name — a card rests at [level1], a
/// dialog is raised at [level3] — so an application that replaces one of them
/// replaces it everywhere, and no component keeps a shadow of its own.
abstract final class MaterialElevation {
  /// Level one: a resting card, a sheet, a raised button.
  ///
  /// Flutter's `kElevationToShadow[1]`.
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 2, blurRadius: 1, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 1, blurRadius: 1),
    BoxShadow(color: _ambient, offsetY: 1, blurRadius: 3),
  ];

  /// Level two: a card under the pointer, a menu about to open.
  ///
  /// Flutter's `kElevationToShadow[2]`.
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 3, blurRadius: 1, spreadRadius: -2),
    BoxShadow(color: _penumbra, offsetY: 2, blurRadius: 2),
    BoxShadow(color: _ambient, offsetY: 1, blurRadius: 5),
  ];

  /// Level three: a dialog, a date picker, a floating action button.
  ///
  /// Flutter's `kElevationToShadow[3]`.
  static const List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 3, blurRadius: 3, spreadRadius: -2),
    BoxShadow(color: _penumbra, offsetY: 3, blurRadius: 4),
    BoxShadow(color: _ambient, offsetY: 1, blurRadius: 8),
  ];

  /// Level four: a navigation drawer under the pointer.
  ///
  /// Flutter's `kElevationToShadow[4]`.
  static const List<BoxShadow> level4 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 2, blurRadius: 4, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 4, blurRadius: 5),
    BoxShadow(color: _ambient, offsetY: 1, blurRadius: 10),
  ];

  /// Level five: the highest surface Material states.
  ///
  /// Material's fifth level is five dp, which `kElevationToShadow` does not list, so this
  /// is the framework's next entry — `kElevationToShadow[6]`.
  static const List<BoxShadow> level5 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 3, blurRadius: 5, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 6, blurRadius: 10),
    BoxShadow(color: _ambient, offsetY: 1, blurRadius: 18),
  ];

  /// Level one, cast upwards: the shadow a sheet throws over the page it covers.
  ///
  /// A sheet leaves the bottom of the screen, so its height reads above it rather than
  /// below it — the one place Material mirrors a level instead of using it. The umbra's
  /// spread is not mirrored, exactly as the framework's entries are not.
  static const List<BoxShadow> sheet = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: -2, blurRadius: 1, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: -1, blurRadius: 1),
    BoxShadow(color: _ambient, offsetY: -1, blurRadius: 3),
  ];

  /// The layer nearest the edge: the framework's key shadow, 20% black.
  static const BoxColor _umbra = BoxColor(0x33000000);

  /// The layer beside it, 14% black.
  static const BoxColor _penumbra = BoxColor(0x24000000);

  /// The wide, soft layer that reads as height, 12% black.
  static const BoxColor _ambient = BoxColor(0x1F000000);
}
