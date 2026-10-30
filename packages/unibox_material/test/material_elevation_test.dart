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
    test('states the layers Flutter’s framework keeps for each level', () {
      // `kElevationToShadow` in `package:flutter/material.dart`, copied out layer for
      // layer: this package has no Flutter to ask, so the numbers are written down here
      // and compared with what the framework states. A level that drifts is a card that
      // is no longer a Material card.
      expect(MaterialElevation.level1, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 2,
          blurRadius: 1,
          spreadRadius: -1,
        ),
        BoxShadow(color: BoxColor(0x24000000), offsetY: 1, blurRadius: 1),
        BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 3),
      ]);
      expect(MaterialElevation.level2, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 3,
          blurRadius: 1,
          spreadRadius: -2,
        ),
        BoxShadow(color: BoxColor(0x24000000), offsetY: 2, blurRadius: 2),
        BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 5),
      ]);
      expect(MaterialElevation.level3, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 3,
          blurRadius: 3,
          spreadRadius: -2,
        ),
        BoxShadow(color: BoxColor(0x24000000), offsetY: 3, blurRadius: 4),
        BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 8),
      ]);
      expect(MaterialElevation.level4, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 2,
          blurRadius: 4,
          spreadRadius: -1,
        ),
        BoxShadow(color: BoxColor(0x24000000), offsetY: 4, blurRadius: 5),
        BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 10),
      ]);
      // Material's fifth level is five dp, which the map does not list, so the highest
      // surface takes its six.
      expect(MaterialElevation.level5, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 3,
          blurRadius: 5,
          spreadRadius: -1,
        ),
        BoxShadow(color: BoxColor(0x24000000), offsetY: 6, blurRadius: 10),
        BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 18),
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
      // The framework's own entries are not monotonic layer by layer — level four's
      // umbra sits nearer the edge than level three's — but the reach is.
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
        // `kElevationToShadow`'s three layers: 20% black under the edge, 14% beside it and
        // 12% in the ambient blur — the same three at every level.
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
          closeTo(0.2, 0.01),
        );
        expect(
          MaterialElevation.level3.last.color.opacity,
          closeTo(0.12, 0.01),
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
