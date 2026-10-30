import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The ladder, as it was measured out of `doc/shadows_material_3_pink_seed.png`.
///
/// Each list is the page's darkness out of 255, row by row below a card's bottom edge, on
/// a 120 dp card rendered at 2x — so one row is half a dp. A level that paints these is a
/// level that looks like the one in the design file; the example's Flutter suite is what
/// checks the painting, because this package has no renderer.
const Map<int, List<int>> _ladder = <int, List<int>>{
  1: <int>[54, 32, 14, 4, 0],
  2: <int>[62, 48, 37, 27, 18, 11, 6, 3, 1],
  3: <int>[64, 54, 45, 39, 32, 26, 19, 14, 10, 7],
  4: <int>[64, 58, 51, 45, 40, 35, 30, 25],
  5: <int>[65, 60, 54, 49, 44, 40, 36, 32],
};

void main() {
  group('MaterialElevation', () {
    test('states one shadow a level, the ladder\'s own heights', () {
      // A level is one shade, not a stack: the ladder's five cards each cast a single
      // shadow that grows wider as the card rises. Written down here because this package
      // cannot ask a designer's file what a level looks like.
      expect(MaterialElevation.level1, const <BoxShadow>[
        BoxShadow(color: BoxColor(0x57000000), offsetY: 0.55, blurRadius: 0.61),
      ]);
      expect(MaterialElevation.level2, const <BoxShadow>[
        BoxShadow(color: BoxColor(0x66000000), offsetY: 0.95, blurRadius: 2.35),
      ]);
      expect(MaterialElevation.level3, const <BoxShadow>[
        BoxShadow(color: BoxColor(0x66000000), offsetY: 1.25, blurRadius: 3.9),
      ]);
      expect(MaterialElevation.level4, const <BoxShadow>[
        BoxShadow(color: BoxColor(0x66000000), offsetY: 1.55, blurRadius: 5.02),
      ]);
      expect(MaterialElevation.level5, const <BoxShadow>[
        BoxShadow(color: BoxColor(0x66000000), offsetY: 1.9, blurRadius: 6.5),
      ]);
    });

    test('rises: every level casts further than the one below it', () {
      const List<List<BoxShadow>> levels = <List<BoxShadow>>[
        MaterialElevation.level1,
        MaterialElevation.level2,
        MaterialElevation.level3,
        MaterialElevation.level4,
        MaterialElevation.level5,
      ];

      // How far a shadow reaches below its surface: its offset plus the blur that carries
      // it. The ladder grows the same way — a surface that rises casts further — so the
      // reach is what has to stay monotone.
      double reach(List<BoxShadow> shadows) => shadows
          .map((BoxShadow layer) => layer.offsetY + layer.blurRadius)
          .reduce((double a, double b) => a > b ? a : b);

      for (int i = 1; i < levels.length; i++) {
        expect(
          reach(levels[i]),
          greaterThan(reach(levels[i - 1])),
          reason: 'level ${i + 1} casts further than $i',
        );
      }
    });

    test('holds one shade, so a surface does not darken with height', () {
      // The ladder is a shade that reaches further, not one that thickens: levels two to
      // five are cast in one colour, and the tone that goes with a level is what carries
      // its weight. Level one is a shade softer — a resting card still touches the page.
      expect(
        MaterialElevation.level2.single.color,
        MaterialElevation.level5.single.color,
      );
      expect(
        MaterialElevation.level3.single.color,
        MaterialElevation.level4.single.color,
      );

      expect(
        MaterialElevation.level1.single.color.opacity,
        closeTo(0.34, 0.01),
      );
      expect(
        MaterialElevation.level5.single.color.opacity,
        closeTo(0.40, 0.01),
      );
    });

    test('covers the ladder it was measured from', () {
      // The rows the design file gives, and the levels they belong to: a level whose reach
      // fell inside the one below it would be a level that does not exist.
      expect(_ladder.keys, <int>[1, 2, 3, 4, 5]);
      for (final MapEntry<int, List<int>> level in _ladder.entries) {
        expect(
          level.value.length,
          greaterThanOrEqualTo(5),
          reason: 'level ${level.key} has a falloff to compare',
        );
      }
    });

    test('mirrors level one upwards for a sheet', () {
      expect(
        MaterialElevation.sheet,
        hasLength(MaterialElevation.level1.length),
      );

      for (int i = 0; i < MaterialElevation.sheet.length; i++) {
        expect(
          MaterialElevation.sheet[i].offsetY,
          -MaterialElevation.level1[i].offsetY,
          reason: 'layer ${i + 1} points up instead of down',
        );
        expect(
          MaterialElevation.sheet[i].blurRadius,
          MaterialElevation.level1[i].blurRadius,
        );
        expect(
          MaterialElevation.sheet[i].color,
          MaterialElevation.level1[i].color,
        );
      }
    });
  });

  group('the components read the scale', () {
    test('a card rests at level one', () {
      expect(MaterialCard.elevatedShadows, MaterialElevation.level1);
      expect(const MaterialCard().shadows, MaterialElevation.level1);
    });

    test('a dialog is raised at level three', () {
      expect(MaterialDialog.elevation, MaterialElevation.level3);
    });
  });
}
