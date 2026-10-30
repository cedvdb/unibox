import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The scale is the only place a shadow is written.
///
/// A card, a dialog and a sheet used to carry a shadow each, and the example wrote a
/// fourth; three of them were near-copies of one another and the fourth was a
/// different design. The tests here pin the direction of the dependency — the
/// components read the scale — so a changed elevation changes every surface that
/// rests on it, and a surface cannot quietly keep a shadow of its own.
void main() {
  group('MaterialElevation', () {
    test('states the layer Flutter’s framework keeps for each level', () {
      // `kElevationToShadow` in `package:flutter/material.dart`, third layer of each
      // entry, copied out: this package cannot import Flutter to ask, so the numbers
      // are written down here and compared with what the framework states. A level
      // that drifts is a card that is no longer a Material card.
      expect(
        MaterialElevation.level1,
        const BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 3),
      );
      expect(
        MaterialElevation.level2,
        const BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 5),
      );
      expect(
        MaterialElevation.level3,
        const BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 8),
      );
      expect(
        MaterialElevation.level4,
        const BoxShadow(
          color: BoxColor(0x1F000000),
          offsetY: 1,
          blurRadius: 10,
        ),
      );
      // Material's fifth level is five dp, which the map does not list, so the
      // highest surface takes its six.
      expect(
        MaterialElevation.level5,
        const BoxShadow(
          color: BoxColor(0x1F000000),
          offsetY: 1,
          blurRadius: 18,
        ),
      );
    });

    test('rises: every level is a softer edge than the one below it', () {
      const List<BoxShadow> levels = <BoxShadow>[
        MaterialElevation.level1,
        MaterialElevation.level2,
        MaterialElevation.level3,
        MaterialElevation.level4,
        MaterialElevation.level5,
      ];

      for (int i = 1; i < levels.length; i++) {
        expect(
          levels[i].blurRadius,
          greaterThan(levels[i - 1].blurRadius),
          reason: 'a higher surface has a softer edge',
        );
        expect(
          levels[i].offsetY,
          greaterThanOrEqualTo(levels[i - 1].offsetY),
          reason: 'level ${i + 1} sits at least as far below its surface as $i',
        );
      }
    });

    test('casts one shade at every level, so a surface does not darken with height', () {
      expect(MaterialElevation.level1.color, MaterialElevation.level5.color);
      // `kElevationToShadow`'s ambient layer is `Color(0x1F000000)`, 12% black.
      expect(MaterialElevation.level3.color.opacity, closeTo(0.12, 0.01));
    });

    test('mirrors level one upwards for a sheet', () {
      expect(
        MaterialElevation.sheet.offsetY,
        -MaterialElevation.level1.offsetY,
      );
      expect(
        MaterialElevation.sheet.blurRadius,
        MaterialElevation.level1.blurRadius,
      );
    });
  });

  group('the components read the scale', () {
    test('a card rests at level one', () {
      expect(MaterialCard.elevatedShadow, MaterialElevation.level1);
      expect(const MaterialCard().shadow, MaterialElevation.level1);
    });

    test('a dialog is raised at level three', () {
      expect(MaterialDialog.elevation, MaterialElevation.level3);
    });
  });
}
