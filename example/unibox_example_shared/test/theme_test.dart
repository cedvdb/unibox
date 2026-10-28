import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// Holds the example's palette to the one seed it is grown from, and its two
/// vocabularies apart.
///
/// The colours of the example are read out of the palette Material builds for
/// [ExamplePalette.seed] rather than typed into `theme.dart`, and the tree both
/// names [ExampleColor] roles and draws components from `unibox_material`, which
/// name [MaterialColorRole]s of their own. Those are the three things these tests
/// keep: every role comes from the seed, one theme answers both vocabularies, and
/// no two roles write the same custom property on the web — two members called
/// `surface` would write `--unibox-color-surface` twice, and the browser would keep
/// the last while Flutter resolved each one, which no token table can catch because
/// both renderers were right about their own colour.
void main() {
  group('ExamplePalette', () {
    test('grows every colour from the seed', () {
      final MaterialPalette grown = MaterialPalette.fromSeed(
        ExamplePalette.seed,
      );

      expect(ExamplePalette.accent, grown.primary);
      expect(ExamplePalette.accentSurface, grown.secondaryContainer);
      expect(ExamplePalette.panel, grown.surfaceContainerLowest);
      expect(ExamplePalette.canvas, grown.surfaceContainerLow);
      expect(ExamplePalette.text, grown.onSurface);
      expect(ExamplePalette.muted, grown.onSurfaceVariant);
      expect(ExamplePalette.border, grown.outlineVariant);
      expect(ExamplePalette.danger, grown.error);
    });

    test('gives the confirmation a seed of its own', () {
      // Material's roles carry an error and no success, so the example grows a
      // second palette rather than inventing a green.
      final MaterialPalette grown = MaterialPalette.fromSeed(
        ExamplePalette.successSeed,
      );

      expect(ExamplePalette.success, grown.primary);
      expect(ExamplePalette.successSurface, grown.secondaryContainer);
    });

    test('mixes the state layers into the accent', () {
      // The accent's two states are Material's own layers resolved against the
      // fill: opaque colours, darker than the accent, because the on-surface colour
      // they are made of is near black in this scheme.
      expect(ExamplePalette.accentHover.isOpaque, isTrue);
      expect(
        ExamplePalette.accentHover.red,
        lessThan(ExamplePalette.accent.red),
      );
      expect(
        ExamplePalette.accentPressed.red,
        lessThanOrEqualTo(ExamplePalette.accentHover.red),
      );
    });

    test('answers every role the pages name', () {
      for (final ExampleColor role in ExampleColor.values) {
        expect(ExamplePalette.theme.colorOf(role), isNotNull, reason: '$role');
      }
      for (final MaterialColorRole role in MaterialColorRole.values) {
        expect(ExamplePalette.theme.colorOf(role), isNotNull, reason: '$role');
      }
    });
  });

  group('ExamplePalette.theme', () {
    test('names every role once, across both vocabularies', () {
      expect(ExamplePalette.theme.clashes, isEmpty);
    });

    test('answers the panel the example paints its raised surfaces with', () {
      expect(
        ExamplePalette.theme.resolve(const BoxColor.role(ExampleColor.panel)),
        ExamplePalette.panel,
      );
    });

    test('leaves the Material roles to the Material palette', () {
      expect(
        ExamplePalette.theme.resolve(
          const BoxColor.role(MaterialColorRole.surface),
        ),
        ExamplePalette.material.surface,
        reason: 'a Material component keeps the colour its palette states',
      );
    });
  });
}
