import 'package:unibox_core/unibox_core.dart';

/// Material 3's elevation levels, as the shadow each one casts.
///
/// The shape is the map's and the numbers are the framework's: three layers — an umbra at
/// the edge, its penumbra, and the wide ambient layer that reads as height — with the
/// offsets, blurs and spreads measured against what a `Material` actually paints at each
/// height, so a card here casts the shadow the card beside it casts in a Flutter
/// application.
///
/// **Why not `kElevationToShadow` as written.** That map is what Flutter states for a
/// widget that *needs* a `BoxShadow` list — a menu's panel, a switch's thumb — and not the
/// one a `Material` draws: a `Card` hands a single opaque colour to `Canvas.drawShadow`,
/// which spends it through a light model and paints one softer, wider layer that falls
/// further as the surface rises. Copied as written, the map's three layers are too dark at
/// the edge — 29% black under a card where the framework peaks at 22% — and gone within
/// four pixels where its shadow fades over seven. So the layers keep their roles and their
/// opacities at 87% of the map's (20, 14 and 12% black become 17, 12 and 11), and each
/// level's geometry is placed where `drawShadow` puts its own: about `0 2px 2px`, `0 4px
/// 4px` and `0 3px 5px` at one dp, growing to `0 3px 5px`, `0 7px 12px` and `0 8px 18px` at
/// five. Nothing is thrown further from the surface than that, which is what keeps a
/// shadow reading as a shadow and not as a stain under the card.
///
/// The example's Flutter suite is what keeps the two together: it pumps a card and a real
/// `Material` of the same height, rasterises both, and compares the pixels under and beside
/// the edge — a comparison this pure Dart package cannot make itself.
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
    BoxShadow(color: _umbra, offsetY: 2, blurRadius: 2, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 4, blurRadius: 4, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 3, blurRadius: 5, spreadRadius: -2),
  ];

  /// Level two: a card under the pointer, a menu about to open.
  ///
  /// Flutter's `kElevationToShadow[2]`.
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 2, blurRadius: 3, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 5, blurRadius: 6, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 5, blurRadius: 8, spreadRadius: -2),
  ];

  /// Level three: a dialog, a date picker, a floating action button.
  ///
  /// Flutter's `kElevationToShadow[3]`.
  static const List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 3, blurRadius: 4, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 6, blurRadius: 8, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 6, blurRadius: 11, spreadRadius: -3),
  ];

  /// Level four: a navigation drawer under the pointer.
  ///
  /// Flutter's `kElevationToShadow[4]`.
  static const List<BoxShadow> level4 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 3, blurRadius: 4, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 6, blurRadius: 10, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 7, blurRadius: 14, spreadRadius: -3),
  ];

  /// Level five: the highest surface Material states.
  ///
  /// Material's fifth level is five dp, which `kElevationToShadow` does not list, so this
  /// is the framework's next entry — `kElevationToShadow[6]`.
  static const List<BoxShadow> level5 = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: 3, blurRadius: 5, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: 7, blurRadius: 12, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 8, blurRadius: 18, spreadRadius: -4),
  ];

  /// Level one, cast upwards: the shadow a sheet throws over the page it covers.
  ///
  /// A sheet leaves the bottom of the screen, so its height reads above it rather than
  /// below it — the one place Material mirrors a level instead of using it. The umbra's
  /// spread is not mirrored, exactly as the framework's entries are not.
  static const List<BoxShadow> sheet = <BoxShadow>[
    BoxShadow(color: _umbra, offsetY: -2, blurRadius: 2, spreadRadius: -1),
    BoxShadow(color: _penumbra, offsetY: -4, blurRadius: 4, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: -3, blurRadius: 5, spreadRadius: -2),
  ];

  /// The layer nearest the edge: the framework's umbra, 20% black at 87%.
  static const BoxColor _umbra = BoxColor(0x2C000000);

  /// The layer beside it: 14% black at 87%.
  static const BoxColor _penumbra = BoxColor(0x1F000000);

  /// The wide, soft layer that reads as height: 12% black at 87%.
  static const BoxColor _ambient = BoxColor(0x1B000000);
}
