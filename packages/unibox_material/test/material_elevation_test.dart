import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The scale is the only place a shadow is written.
///
/// A card, a dialog and a sheet used to carry a shadow each, and the example wrote a
/// fourth; three of them were near-copies of one another and the fourth was a
/// different design. The tests here pin the direction of the dependency — the
/// components read the scale — so a changed elevation changes every surface that
/// rests on it, and a surface cannot quietly keep a shadow of its own. They also pin the
/// numbers themselves, because this package cannot ask Flutter what a level looks like.
void main() {
  group('MaterialElevation', () {
    test('states three layers, placed where the framework paints them', () {
      // The map's roles — umbra, penumbra, ambient — and the map's opacities at 79%, with
      // each level's offsets, blurs and spreads measured against what `Canvas.drawShadow`
      // puts on the page at that height. This package has no Flutter to ask, so the numbers
      // are written down here; the example's Flutter suite is what compares the pixels.
      expect(MaterialElevation.level1, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x28000000),
          offsetY: 2,
          blurRadius: 2,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: BoxColor(0x1C000000),
          offsetY: 4,
          blurRadius: 4,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: BoxColor(0x18000000),
          offsetY: 3,
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ]);
      expect(MaterialElevation.level2, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x28000000),
          offsetY: 2,
          blurRadius: 3,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: BoxColor(0x1C000000),
          offsetY: 5,
          blurRadius: 6,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: BoxColor(0x18000000),
          offsetY: 5,
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ]);
      expect(MaterialElevation.level3, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x28000000),
          offsetY: 3,
          blurRadius: 4,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: BoxColor(0x1C000000),
          offsetY: 6,
          blurRadius: 8,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: BoxColor(0x18000000),
          offsetY: 6,
          blurRadius: 11,
          spreadRadius: -3,
        ),
      ]);
      expect(MaterialElevation.level4, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x28000000),
          offsetY: 3,
          blurRadius: 4,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: BoxColor(0x1C000000),
          offsetY: 6,
          blurRadius: 10,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: BoxColor(0x18000000),
          offsetY: 7,
          blurRadius: 14,
          spreadRadius: -3,
        ),
      ]);
      expect(MaterialElevation.level5, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x28000000),
          offsetY: 3,
          blurRadius: 5,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: BoxColor(0x1C000000),
          offsetY: 7,
          blurRadius: 12,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: BoxColor(0x18000000),
          offsetY: 8,
          blurRadius: 18,
          spreadRadius: -4,
        ),
      ]);
    });

    test('casts three layers, so a surface has an edge and a penumbra', () {
      for (final List<BoxShadow> level in <List<BoxShadow>>[
        MaterialElevation.level1,
        MaterialElevation.level2,
        MaterialElevation.level3,
        MaterialElevation.level4,
        MaterialElevation.level5,
      ]) {
        expect(level, hasLength(3));
        // The layer nearest the edge is the tightest and the darkest; the ambient layer
        // is the widest and the faintest. That is what makes the three read as one.
        expect(level.first.blurRadius, lessThan(level.last.blurRadius));
        expect(
          level.first.color.opacity,
          greaterThan(level.last.color.opacity),
        );
      }
    });

    test('rises: every level casts further than the one below it', () {
      const List<List<BoxShadow>> levels = <List<BoxShadow>>[
        MaterialElevation.level1,
        MaterialElevation.level2,
        MaterialElevation.level3,
        MaterialElevation.level4,
        MaterialElevation.level5,
      ];

      // How far a shadow reaches below its surface: the far edge of its widest layer.
      // The framework's drawing grows the same way — a surface that rises casts further —
      // so the reach is what has to stay monotone, layer by layer or not.
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

    test(
      'casts one shade per layer, so a surface does not darken with height',
      () {
        // `kElevationToShadow`'s three layers — 20% black under the edge, 14% beside it and
        // 12% in the ambient blur — the same three at every level, each cast at 79%.
        final List<List<BoxShadow>> levels = <List<BoxShadow>>[
          MaterialElevation.level1,
          MaterialElevation.level2,
          MaterialElevation.level3,
          MaterialElevation.level4,
          MaterialElevation.level5,
        ];

        for (int layer = 0; layer < 3; layer++) {
          expect(
            levels.map((List<BoxShadow> level) => level[layer].color).toSet(),
            hasLength(1),
            reason: 'layer ${layer + 1} is one shade at every level',
          );
        }

        expect(
          MaterialElevation.level3.first.color.opacity,
          closeTo(0.157, 0.01),
        );
        expect(
          MaterialElevation.level3.last.color.opacity,
          closeTo(0.094, 0.01),
        );
      },
    );

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
          MaterialElevation.sheet[i].spreadRadius,
          MaterialElevation.level1[i].spreadRadius,
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
