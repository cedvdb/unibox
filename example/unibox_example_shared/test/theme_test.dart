import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// Holds the example's palettes to the seeds they are grown from, and its two
/// vocabularies apart.
///
/// The tree names [ExampleColor] roles and nothing else, so every colour the page
/// shows is answered by the theme the host installs for the seed in the address.
/// These are the facts that keeps: each seed grows a whole palette, every role is
/// answered by every seed, no two roles claim one custom property on the web, and a
/// seed the address does not name falls back to the one the example is branded with.
void main() {
  group('ExampleSeed', () {
    test('has a seed for every palette the picker offers', () {
      expect(ExampleSeed.values, isNotEmpty);
      // The first seed is the default, which is what `/` and an unknown name give.
      expect(ExampleSeed.fromName(null), ExampleSeed.values.first);
      expect(ExampleSeed.fromName('nonsense'), ExampleSeed.values.first);
      expect(ExampleSeed.fromName('green'), ExampleSeed.green);
    });

    test('paints each swatch with the accent its seed grows', () {
      for (final ExampleSeed seed in ExampleSeed.values) {
        expect(
          seed.accent,
          ExamplePalette.materialFor(seed).primary,
          reason: '${seed.name} shows the colour the page will use',
        );
      }
      // Six seeds that all looked the same would be a picker of one colour.
      expect(
        ExampleSeed.values.map((ExampleSeed seed) => seed.accent).toSet(),
        hasLength(ExampleSeed.values.length),
      );
    });
  });

  group('ExamplePalette', () {
    test('grows every colour of a seed from that seed', () {
      for (final ExampleSeed seed in ExampleSeed.values) {
        final MaterialPalette grown = MaterialPalette.fromSeed(seed.color);
        final UniboxTheme theme = ExamplePalette.themeFor(seed);

        expect(
          theme.resolve(const BoxColor.role(ExampleColor.accent)),
          grown.primary,
        );
        expect(
          theme.resolve(const BoxColor.role(ExampleColor.panel)),
          grown.surfaceContainerLowest,
        );
        expect(
          theme.resolve(const BoxColor.role(ExampleColor.canvas)),
          grown.surfaceContainerLow,
        );
        expect(
          theme.resolve(const BoxColor.role(ExampleColor.text)),
          grown.onSurface,
        );
        expect(
          theme.resolve(const BoxColor.role(ExampleColor.muted)),
          grown.onSurfaceVariant,
        );
        expect(
          theme.resolve(const BoxColor.role(ExampleColor.border)),
          grown.outlineVariant,
        );
        expect(
          theme.resolve(const BoxColor.role(ExampleColor.danger)),
          grown.error,
        );
      }
    });

    test('answers every role, for every seed', () {
      for (final ExampleSeed seed in ExampleSeed.values) {
        final UniboxTheme theme = ExamplePalette.themeFor(seed);

        for (final ExampleColor role in ExampleColor.values) {
          expect(theme.colorOf(role), isNotNull, reason: '${seed.name} $role');
        }
        // The components of `unibox_material` name roles of their own and are drawn
        // inside the same page, so one theme answers both vocabularies.
        for (final MaterialColorRole role in MaterialColorRole.values) {
          expect(theme.colorOf(role), isNotNull, reason: '${seed.name} $role');
        }
      }
    });

    test('mixes the palette layers into the accent', () {
      // The accent's two states are Material's own layers resolved against the
      // fill: opaque colours, because a box paints one colour and not a layer.
      for (final ExampleSeed seed in ExampleSeed.values) {
        final UniboxTheme theme = ExamplePalette.themeFor(seed);
        final BoxColor accent = theme.resolve(
          const BoxColor.role(ExampleColor.accent),
        );
        final BoxColor hover = theme.resolve(
          const BoxColor.role(ExampleColor.accentHover),
        );

        expect(hover.isOpaque, isTrue, reason: seed.name);
        expect(hover, isNot(accent), reason: seed.name);
      }
    });

    test('gives the confirmation a seed of its own', () {
      // Material's roles carry an error and no success, so the example grows a
      // second palette rather than inventing a green — and it is the same one for
      // every brand seed, because a confirmation is a convention.
      final MaterialPalette grown = MaterialPalette.fromSeed(
        ExamplePalette.successSeed,
      );

      for (final ExampleSeed seed in ExampleSeed.values) {
        final UniboxTheme theme = ExamplePalette.themeFor(seed);

        expect(
          theme.resolve(const BoxColor.role(ExampleColor.success)),
          grown.primary,
        );
        expect(
          theme.resolve(const BoxColor.role(ExampleColor.successSurface)),
          grown.secondaryContainer,
        );
      }
    });

    test('names every role once, across both vocabularies', () {
      for (final ExampleSeed seed in ExampleSeed.values) {
        expect(
          ExamplePalette.themeFor(seed).clashes,
          isEmpty,
          reason: seed.name,
        );
      }
    });

    test('leaves the Material roles to the Material palette', () {
      expect(
        ExamplePalette.themeFor(ExampleSeed.blue)
            .resolve(const BoxColor.role(MaterialColorRole.surface)),
        ExamplePalette.material.surface,
        reason: 'a Material component keeps the colour its palette states',
      );
    });
  });
}
