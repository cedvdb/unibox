import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
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
}
