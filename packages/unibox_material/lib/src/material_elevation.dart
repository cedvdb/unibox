import 'package:unibox_core/unibox_core.dart';

/// Material 3's elevation levels, as the shadow each one casts.
///
/// A level is stated the way the framework *draws* it, which is not the way
/// Material's 2014 table writes it down. A `Card` is a `Material`, and a `Material`
/// draws its shadow with `Canvas.drawShadow`: one colour — the surface's
/// `shadowColor`, the opaque `ColorScheme.shadow` — handed to a light model that
/// spends it as an ambient layer hugging the shape and a key shadow that falls
/// further than the shape as the surface rises.
///
/// `kElevationToShadow` is not that. It is the map Flutter states for the widgets
/// that need a `BoxShadow` list — a menu's panel, a switch's thumb — and copying
/// it read heavier than the card beside it in a Flutter application: its three
/// layers at 20, 14 and 12% black composite to 29% under the edge, where the
/// framework's own card peaks at 22%, and they die within four pixels where its
/// shadow fades over seven. So a level here is
/// the framework's own two layers, in the framework's own two opacities — a key
/// shadow at 20% black and an ambient one at 12% — with the offsets, blurs and
/// spreads measured against what `Canvas.drawShadow` paints at that height, down
/// and sideways alike. The example's Flutter suite is what keeps the two together:
/// it rasterises a card beside a real `Material` of the same height and compares
/// the pixels, which is a comparison this pure Dart package cannot make itself.
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
  /// The framework's `drawShadow` at one dp.
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(color: _key, offsetY: 3, blurRadius: 3, spreadRadius: -1),
    BoxShadow(color: _ambient, offsetY: 2, blurRadius: 5, spreadRadius: -1),
  ];

  /// Level two: a card under the pointer, a menu about to open.
  ///
  /// The framework's `drawShadow` at two dp.
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(color: _key, offsetY: 7, blurRadius: 7, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 1, blurRadius: 4),
  ];

  /// Level three: a dialog, a date picker, a floating action button.
  ///
  /// The framework's `drawShadow` at three dp.
  static const List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(color: _key, offsetY: 10, blurRadius: 10, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 1, blurRadius: 5),
  ];

  /// Level four: a navigation drawer under the pointer.
  ///
  /// The framework's `drawShadow` at four dp.
  static const List<BoxShadow> level4 = <BoxShadow>[
    BoxShadow(color: _key, offsetY: 13, blurRadius: 14, spreadRadius: -3),
    BoxShadow(color: _ambient, offsetY: 3, blurRadius: 8, spreadRadius: -1),
  ];

  /// Level five: the highest surface Material states.
  ///
  /// The framework's `drawShadow` at five dp.
  static const List<BoxShadow> level5 = <BoxShadow>[
    BoxShadow(color: _key, offsetY: 15, blurRadius: 16, spreadRadius: -2),
    BoxShadow(color: _ambient, offsetY: 4, blurRadius: 9, spreadRadius: -2),
  ];

  /// Level one, cast upwards: the shadow a sheet throws over the page it covers.
  ///
  /// A sheet leaves the bottom of the screen, so its height reads above it rather than
  /// below it — the one place Material mirrors a level instead of using it. The key
  /// shadow's spread is not mirrored, exactly as the framework's own is not.
  static const List<BoxShadow> sheet = <BoxShadow>[
    BoxShadow(color: _key, offsetY: -3, blurRadius: 3, spreadRadius: -1),
    BoxShadow(color: _ambient, offsetY: -2, blurRadius: 5, spreadRadius: -1),
  ];

  /// The key shadow: the framework's `_kKeyUmbraOpacity`, 20% black.
  static const BoxColor _key = BoxColor(0x33000000);

  /// The ambient shadow: the framework's `_kAmbientShadowOpacity`, 12% black.
  static const BoxColor _ambient = BoxColor(0x1F000000);
}
