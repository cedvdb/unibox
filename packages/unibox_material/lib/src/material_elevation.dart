import 'package:unibox_core/unibox_core.dart';

/// Material 3's elevation levels, as the shadow each one casts.
///
/// A level is **one shadow**. Material's ladder is a single shade that grows wider and
/// falls further as a surface rises, not a stack of layers: five heights, one shade each.
///
/// **Where the numbers come from.** `doc/shadows_material_3_pink_seed.png` in this
/// package is the ladder this package copies — six cards, levels 0 to 5, a pink seed
/// palette. Its rows were read back out of the image one pixel at a time: a 120 dp card at
/// 2x, so every row below its bottom edge is half a dp. Under level one the page reads
/// `54, 32, 14, 4, 0` — darkness out of 255 — and clears within two and a half dp; under
/// level five it reads `65, 60, 54, 49, 44, 40, 36, 32` and still fades at ten. Each level
/// here is the gaussian that paints those rows, within three parts of 255 of them, and both
/// renderers are held to that one shape: the model states a blur radius in Flutter's unit,
/// and `unibox_css` writes the CSS radius that paints the same deviation. A level therefore
/// looks the same in a browser as in a Flutter application, which is the one thing a design
/// system's elevations have to do.
///
/// **Why not `kElevationToShadow`.** That map is the shadow Flutter states for a widget that
/// needs a `BoxShadow` list — a menu's panel, a switch's thumb — and it is three times wider
/// than this ladder: at level one it fades after four dp and reads `72, 37, 15, 5, 2`. Copied
/// from it, a card on the page read a level higher than the card in the design file, which is
/// the drift this scale exists to prevent.
///
/// **Why not what a `Card` paints, either.** A `Card` hands one opaque colour to
/// `Canvas.drawShadow`, which spends it through a light model; that shade reads `56, 40, 28,
/// 17, 9` below its edge — unlike the map, and unlike this ladder, in the middle. So this
/// package follows the design file, and a card drawn from it sits tighter than Flutter's own:
/// a documented difference rather than a coincidence, and the example's suite pins it against
/// the ladder's numbers rather than against a `Card`.
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
  /// The ladder's `Level 1` — `54, 33, 15, 5, 1` under the edge against its `54, 32, 14, 4,
  /// 0`, and clear by two and a half dp.
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(color: _restingShade, offsetY: 0.55, blurRadius: 0.61),
  ];

  /// Level two: a card under the pointer, a menu about to open.
  ///
  /// `59, 48, 37, 26, 18, 11, 6, 3` under the edge, against the ladder's `62, 48, 37, 27,
  /// 18, 11, 6, 3, 1`: the level a card climbs to when the pointer rests on it.
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(color: _shade, offsetY: 0.95, blurRadius: 2.35),
  ];

  /// Level three: a dialog, a date picker, a floating action button.
  ///
  /// `62, 55, 47, 40, 33, 26, 20, 15` against the ladder's `64, 54, 45, 39, 32, 26, 19,
  /// 14`.
  static const List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(color: _shade, offsetY: 1.25, blurRadius: 3.9),
  ];

  /// Level four: a navigation drawer under the pointer.
  ///
  /// `64, 58, 52, 47, 41, 35, 30, 25` against the ladder's `64, 58, 51, 45, 40, 35, 30,
  /// 25`.
  static const List<BoxShadow> level4 = <BoxShadow>[
    BoxShadow(color: _shade, offsetY: 1.55, blurRadius: 5.02),
  ];

  /// Level five: the highest surface Material states.
  ///
  /// `63, 58, 53, 49, 44, 39, 35, 31` against the ladder's `65, 60, 54, 49, 44, 40, 36,
  /// 32`.
  static const List<BoxShadow> level5 = <BoxShadow>[
    BoxShadow(color: _shade, offsetY: 1.9, blurRadius: 6.5),
  ];

  /// Level one, cast upwards: the shadow a sheet throws over the page it covers.
  ///
  /// A sheet leaves the bottom of the screen, so its height reads above it rather than
  /// below it — the one place Material mirrors a level instead of using it.
  static const List<BoxShadow> sheet = <BoxShadow>[
    BoxShadow(color: _restingShade, offsetY: -0.55, blurRadius: 0.61),
  ];

  /// The shade every level above the first is cast in: black at 40%.
  ///
  /// The ladder barely darkens as it rises — the shade holds and the reach grows — so a
  /// surface that climbs the scale reads as further away rather than as dirtier, and the
  /// tone that goes with a level is what carries most of its weight.
  static const BoxColor _shade = BoxColor(0x66000000);

  /// The shade level one is cast in: black at 34%.
  ///
  /// Level one is a shade softer than the rest, which is what the ladder shows under a
  /// resting card: the first level of anything reads as the surface still touching the page.
  static const BoxColor _restingShade = BoxColor(0x57000000);
}
