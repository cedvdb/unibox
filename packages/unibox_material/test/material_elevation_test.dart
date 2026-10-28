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
    test('rises: every level is softer and further than the one below it', () {
      const List<BoxShadow> levels = <BoxShadow>[
        MaterialElevation.level1,
        MaterialElevation.level2,
        MaterialElevation.level3,
        MaterialElevation.level4,
        MaterialElevation.level5,
      ];

      for (int i = 1; i < levels.length; i++) {
        expect(
          levels[i].offsetY,
          greaterThan(levels[i - 1].offsetY),
          reason: 'level ${i + 1} sits above level $i',
        );
        expect(
          levels[i].blurRadius,
          greaterThan(levels[i - 1].blurRadius),
          reason: 'a higher surface has a softer edge',
        );
      }
    });

    test('casts one shade at every level, so a surface does not darken with height', () {
      expect(MaterialElevation.level1.color, MaterialElevation.level5.color);
      expect(MaterialElevation.level3.color.opacity, closeTo(0.15, 0.01));
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
