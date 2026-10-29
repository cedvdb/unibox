import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('the scheme', () {
    test('is read from the surface a palette paints on', () {
      expect(MaterialPalette.light.colorScheme, BoxColorScheme.light);
      expect(MaterialPalette.dark.colorScheme, BoxColorScheme.dark);
    });

    test('follows the seed when a palette is grown from one', () {
      const BoxColor seed = BoxColor(0xFF8C4A5D);

      expect(MaterialPalette.fromSeed(seed).colorScheme, BoxColorScheme.light);
      expect(
        MaterialPalette.fromSeed(seed, isDark: true).colorScheme,
        BoxColorScheme.dark,
      );
    });

    test('is what the theme it builds states', () {
      // The palette is the one that knows, so a host that installs `darkTheme` never writes the
      // fact twice — and a document writes `color-scheme: dark` from the theme alone.
      expect(MaterialPalette.light.theme.colorScheme, BoxColorScheme.light);
      expect(MaterialPalette.dark.theme.colorScheme, BoxColorScheme.dark);
      expect(MaterialPalette.lightTheme.colorScheme, BoxColorScheme.light);
    });
  });

  group('MaterialPalette', () {
    test('states a Material 3 baseline light scheme', () {
      const MaterialPalette palette = MaterialPalette.light;

      expect(palette.primary, const BoxColor(0xFF6750A4));
      expect(palette.onPrimary, BoxColors.white);
      expect(palette.onSurface, const BoxColor(0xFF1D1B20));
      expect(palette.onSurfaceVariant, const BoxColor(0xFF49454F));
      expect(palette.surfaceContainerLowest, BoxColors.white);
      expect(palette.surfaceContainer, const BoxColor(0xFFF3EDF7));
      expect(palette.outlineVariant, const BoxColor(0xFFCAC4D0));
      expect(palette.error, const BoxColor(0xFFB3261E));
    });

    test('states a Material 3 baseline dark scheme', () {
      const MaterialPalette palette = MaterialPalette.dark;

      expect(palette.primary, const BoxColor(0xFFD0BCFF));
      expect(palette.onPrimary, const BoxColor(0xFF381E72));
      expect(palette.onSurface, const BoxColor(0xFFE6E0E9));
      expect(palette.surface, const BoxColor(0xFF141218));
      // The two schemes are not the same palette with a different name.
      expect(palette.onSurface, isNot(MaterialPalette.light.onSurface));
      expect(palette.surface, isNot(MaterialPalette.light.surface));
    });

    test('draws no text role as its own surface', () {
      // A role that names text or icons must be readable on the role it pairs
      // with, so it is never the same colour.
      for (final MaterialPalette palette in <MaterialPalette>[
        MaterialPalette.light,
        MaterialPalette.dark,
      ]) {
        expect(palette.onPrimary, isNot(palette.primary));
        expect(palette.onSurface, isNot(palette.surface));
        expect(palette.onError, isNot(palette.error));
        expect(palette.onPrimaryContainer, isNot(palette.primaryContainer));
      }
    });

    test('paints the state layers at the opacities Material states', () {
      const MaterialPalette palette = MaterialPalette.light;

      // Material 3's state layers: 8% hover, 10% focus and press, 16% dragged.
      expect(palette.hoverLayer.opacity, closeTo(0.08, 0.005));
      expect(palette.focusLayer.opacity, closeTo(0.10, 0.005));
      expect(palette.pressedLayer.opacity, closeTo(0.10, 0.005));
      expect(palette.draggedLayer.opacity, closeTo(0.16, 0.005));

      // The layer is the on-surface colour, so it reads over any surface tone.
      expect(palette.hoverLayer.red, palette.onSurface.red);
      expect(palette.hoverLayer.blue, palette.onSurface.blue);
      // A dark scheme layers its own light on-surface colour.
      expect(
        MaterialPalette.dark.hoverLayer.red,
        MaterialPalette.dark.onSurface.red,
      );
    });

    test('gives every role a value, in both schemes', () {
      // A component names a role and expects the theme to answer it, so a role
      // missing from a scheme would be a colour nobody notices until it is drawn.
      for (final UniboxTheme theme in <UniboxTheme>[
        MaterialPalette.lightTheme,
        MaterialPalette.darkTheme,
      ]) {
        for (final MaterialColorRole role in MaterialColorRole.values) {
          expect(theme.colorOf(role), isNotNull, reason: '$role has no colour');
        }
      }
    });

    test('resolves a role to the value the palette holds', () {
      expect(
        MaterialPalette.lightTheme.resolve(
          const BoxColor.role(MaterialColorRole.onSurface),
        ),
        MaterialPalette.light.onSurface,
      );
      expect(
        MaterialPalette.darkTheme.resolve(
          const BoxColor.role(MaterialColorRole.primary),
        ),
        MaterialPalette.dark.primary,
      );
    });

    test('spells its roles as custom properties of their names', () {
      expect(
        MaterialPalette.lightTheme.variables.keys,
        contains('--unibox-color-surface-container-high'),
      );
      expect(
        MaterialPalette.lightTheme.variables.keys,
        contains('--unibox-color-hover-layer'),
      );
    });

    test('lets a component be restyled by another theme', () {
      final MaterialCard card = MaterialCard(
        children: <UINode>[const TextNode('Order summary')],
      );

      // The card names roles, so it is the same card in a dark scheme: nothing in
      // the tree changes, only the theme the renderer is given.
      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerLow),
      );
      expect(
        MaterialPalette.darkTheme.resolve(card.backgroundColor!),
        MaterialPalette.dark.surfaceContainerLow,
      );
    });
  });

  group('MaterialPalette.fromSeed', () {
    // The example's accent, so the numbers a reader sees in the README are the
    // numbers these tests hold.
    const BoxColor brand = BoxColor(0xFF2D6CF3);

    test('grows every role from one colour', () {
      final MaterialPalette palette = MaterialPalette.fromSeed(brand);

      expect(
        palette.theme.colors.keys,
        unorderedEquals(MaterialColorRole.values),
        reason: 'a generated palette answers every role, like a written one',
      );
      // The state layers come out of the generated on-surface colour, so a
      // generated palette tints its own surfaces rather than the baseline's.
      expect(palette.hoverLayer.red, palette.onSurface.red);
      expect(palette.pressedLayer.opacity, closeTo(0.10, 0.005));
    });

    test('keeps the hue of the seed', () {
      // A palette keeps a hue and a chroma and replaces the tone: a blue seed
      // never draws a red accent.
      final MaterialPalette blue = MaterialPalette.fromSeed(
        const BoxColor(0xFF2D6CF3),
      );
      final MaterialPalette red = MaterialPalette.fromSeed(
        const BoxColor(0xFFB3261E),
      );

      expect(blue.primary.blue, greaterThan(blue.primary.red));
      expect(red.primary.red, greaterThan(red.primary.blue));
      expect(blue.primary, isNot(red.primary));
    });

    test('lowers a saturated seed to a tonal spot accent', () {
      // tonalSpot is the Material You scheme, and it spends a saturated brand
      // colour on a low chroma palette: #2D6CF3 is a saturated blue and the
      // accent it becomes is a quiet one. A scheme that keeps the brand's own
      // chroma is `MaterialSchemeVariant.fidelity`.
      final MaterialPalette palette = MaterialPalette.fromSeed(brand);

      expect(palette.primary, const BoxColor(0xFF4A5C92));
      expect(palette.onPrimary, BoxColors.white);
      expect(palette.onSurface, const BoxColor(0xFF1A1B21));
      expect(palette.scrim, const BoxColor(0x52000000));
    });

    test('builds the scheme the algorithm builds from Material\'s own seed', () {
      // These are the values a Flutter `ColorScheme.fromSeed` gives for
      // #6750A4, because both call the same algorithm. They are a step away from
      // `MaterialPalette.light`, which is the specification's written baseline:
      // the parity that matters is between a tree and the host's theme, and that
      // is this scheme.
      final MaterialPalette light = MaterialPalette.fromSeed(
        const BoxColor(0xFF6750A4),
      );

      expect(light.primary, const BoxColor(0xFF65558F));
      expect(light.primaryContainer, const BoxColor(0xFFE9DDFF));
      expect(light.onPrimaryContainer, const BoxColor(0xFF4D3D75));
      expect(light.surface, const BoxColor(0xFFFDF7FF));
      expect(light.outlineVariant, const BoxColor(0xFFCAC4CF));
      expect(light.error, const BoxColor(0xFFBA1A1A));
    });

    test('builds a dark scheme from the seed, not from the light one', () {
      final MaterialPalette dark = MaterialPalette.fromSeed(
        brand,
        isDark: true,
      );

      // The accent is a light tone of the seed's palette and the surface is near
      // black: a dark scheme is not the light one with its roles swapped.
      expect(dark.primary, const BoxColor(0xFFB3C5FF));
      expect(dark.surface, const BoxColor(0xFF121318));
      expect(dark.onSurface, const BoxColor(0xFFE3E2E9));
      expect(dark.onSurface, isNot(MaterialPalette.fromSeed(brand).onSurface));
    });

    test('spends the seed the way the variant asks', () {
      final MaterialPalette tonalSpot = MaterialPalette.fromSeed(brand);
      final MaterialPalette vibrant = MaterialPalette.fromSeed(
        brand,
        variant: MaterialSchemeVariant.vibrant,
      );
      final MaterialPalette monochrome = MaterialPalette.fromSeed(
        brand,
        variant: MaterialSchemeVariant.monochrome,
      );

      // The same seed, a louder accent.
      expect(vibrant.primary, const BoxColor(0xFF0054D7));
      expect(vibrant.primary, isNot(tonalSpot.primary));
      // A monochrome scheme has no hue left at all.
      for (final BoxColor colour in <BoxColor>[
        monochrome.primary,
        monochrome.secondary,
        monochrome.outline,
      ]) {
        expect(colour.red, colour.green);
        expect(colour.green, colour.blue);
      }
    });

    test('leaves no variant unable to answer a role', () {
      // A variant is a different assignment of the same roles, so none of them
      // may leave one unanswered or draw a text in its own background.
      for (final MaterialSchemeVariant variant
          in MaterialSchemeVariant.values) {
        for (final bool isDark in <bool>[false, true]) {
          final MaterialPalette palette = MaterialPalette.fromSeed(
            brand,
            variant: variant,
            isDark: isDark,
          );

          expect(
            palette.theme.colors.keys,
            unorderedEquals(MaterialColorRole.values),
            reason: '$variant is missing a role',
          );
          expect(palette.onPrimary, isNot(palette.primary), reason: '$variant');
          expect(palette.onSurface, isNot(palette.surface), reason: '$variant');
        }
      }
    });

    test('trades colour for contrast when asked', () {
      final MaterialPalette normal = MaterialPalette.fromSeed(brand);
      final MaterialPalette high = MaterialPalette.fromSeed(
        brand,
        contrastLevel: 1,
      );

      // The most contrasted scheme draws its text in black on the light surface
      // and its accent in a darker tone of the same hue.
      expect(high.onSurface, BoxColors.black);
      expect(high.onSurfaceVariant, BoxColors.black);
      expect(high.primary, const BoxColor(0xFF14295C));
      expect(high.primary, isNot(normal.primary));
    });

    test('clamps a contrast level that is out of range', () {
      expect(
        MaterialPalette.fromSeed(brand, contrastLevel: 4).primary,
        MaterialPalette.fromSeed(brand, contrastLevel: 1).primary,
      );
      expect(
        MaterialPalette.fromSeed(brand, contrastLevel: -9).primary,
        MaterialPalette.fromSeed(brand, contrastLevel: -1).primary,
      );
    });

    test('seeds a palette from a hue, not from an alpha', () {
      // A brand colour is a hue and a chroma; its alpha is the page's business.
      final MaterialPalette opaque = MaterialPalette.fromSeed(brand);
      final MaterialPalette translucent = MaterialPalette.fromSeed(
        const BoxColor(0x332D6CF3),
      );

      expect(translucent.theme.colors, opaque.theme.colors);
    });

    test('refuses a role as a seed', () {
      // A role is a colour a theme answers, and this is the call that builds the
      // theme: reading it here would throw a message about a missing theme.
      expect(
        () => MaterialPalette.fromSeed(
          const BoxColor.role(MaterialColorRole.primary),
        ),
        throwsArgumentError,
      );
    });

    test('restyles a component like a written palette', () {
      final MaterialPalette palette = MaterialPalette.fromSeed(brand);
      final MaterialCard card = MaterialCard(
        children: <UINode>[const TextNode('Order summary')],
      );

      expect(
        palette.theme.resolve(card.backgroundColor!),
        palette.surfaceContainerLow,
      );
    });
  });
}
