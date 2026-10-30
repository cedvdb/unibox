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
/// numbers themselves: this package cannot ask Flutter what a level looks like, so it
/// writes down what the framework paints and the example's Flutter suite is what holds
/// the two together.
void main() {
  group('MaterialElevation', () {
    test('states the shadow the framework paints at each level', () {
      // Not `kElevationToShadow`: that map is what Flutter states for a widget that
      // needs a `BoxShadow` list, and a `Material` does not draw from it — it hands one
      // opaque colour to `Canvas.drawShadow` and lets the light model spend it. These
      // are the layers that reproduce what that drawing looks like, in the framework's
      // own two opacities, measured in the example's Flutter suite.
      expect(MaterialElevation.level1, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 3,
          blurRadius: 3,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: BoxColor(0x1F000000),
          offsetY: 2,
          blurRadius: 5,
          spreadRadius: -1,
        ),
      ]);
      expect(MaterialElevation.level2, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 7,
          blurRadius: 7,
          spreadRadius: -2,
        ),
        BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 4),
      ]);
      expect(MaterialElevation.level3, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 10,
          blurRadius: 10,
          spreadRadius: -2,
        ),
        BoxShadow(color: BoxColor(0x1F000000), offsetY: 1, blurRadius: 5),
      ]);
      expect(MaterialElevation.level4, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 13,
          blurRadius: 14,
          spreadRadius: -3,
        ),
        BoxShadow(
          color: BoxColor(0x1F000000),
          offsetY: 3,
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ]);
      expect(MaterialElevation.level5, const <BoxShadow>[
        BoxShadow(
          color: BoxColor(0x33000000),
          offsetY: 15,
          blurRadius: 16,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: BoxColor(0x1F000000),
          offsetY: 4,
          blurRadius: 9,
          spreadRadius: -2,
        ),
      ]);
    });

    test('casts a key shadow and an ambient one, as Skia composes them', () {
      for (final List<BoxShadow> level in <List<BoxShadow>>[
        MaterialElevation.level1,
        MaterialElevation.level2,
        MaterialElevation.level3,
        MaterialElevation.level4,
        MaterialElevation.level5,
      ]) {
        expect(level, hasLength(2));
        // The key shadow is the darker of the two: it is what gives a surface an edge.
        // The ambient layer is the faint, snug one that reads as height.
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
      // The framework's own drawing grows the same way — the key shadow falls further as
      // the surface rises, while the ambient layer stays a small puddle under it.
      double reach(List<BoxShadow> shadows) => shadows
          .map((BoxShadow layer) => layer.offsetY + layer.blurRadius)
          .reduce((double a, double b) => a > b ? a : b);

      for (int i = 1; i < levels.length; i++) {
        expect(
          reach(levels[i]),
          greaterThan(reach(levels[i - 1])),
          reason: 'level ${i + 1} casts further than $i',
        );
        // And the key shadow is what falls: it leaves the edge by more as the surface
        // rises, while the ambient layer stays tucked under the shape.
        expect(
          levels[i].first.offsetY,
          greaterThan(levels[i - 1].first.offsetY),
          reason: 'level ${i + 1} falls further from its edge than $i',
        );
      }
    });

    test(
      'casts one shade per layer, so a surface does not darken with height',
      () {
        // The framework's two opacities: 20% black for the key shadow and 12% for the
        // ambient one — the same two at every level, so height is a shape and not a
        // colour.
        final List<List<BoxShadow>> levels = <List<BoxShadow>>[
          MaterialElevation.level1,
          MaterialElevation.level2,
          MaterialElevation.level3,
          MaterialElevation.level4,
          MaterialElevation.level5,
        ];

        for (int layer = 0; layer < 2; layer++) {
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
