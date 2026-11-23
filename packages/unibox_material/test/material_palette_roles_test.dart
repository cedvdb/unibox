import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' show BoxColor;
import 'package:unibox_material/unibox_material.dart';

void main() {
  test('answers every role the model can name', () {
    // The list only grows: a role added to the enum without a value here is a colour nobody
    // notices is missing until a control that names it appears, and the trees that use it fail
    // at render time instead of at this line.
    final MaterialPalette palette = MaterialPalette.fromSeed(
      const BoxColor(0xFF2D6CF3),
    );

    for (final MaterialColorRole role in MaterialColorRole.values) {
      expect(
        palette.theme.colors[role],
        isNotNull,
        reason: 'the palette has no value for $role',
      );
    }
  });

  test('keeps the accents it calls fixed the same in both schemes', () {
    // A `*Fixed` role is the one pair Material does not reverse: it is the same tone on a light
    // page and on a dark one, which is why a rating mark or a badge can use it.
    final MaterialPalette light = MaterialPalette.fromSeed(
      const BoxColor(0xFF2D6CF3),
    );
    final MaterialPalette dark = MaterialPalette.fromSeed(
      const BoxColor(0xFF2D6CF3),
      isDark: true,
    );

    expect(dark.primaryFixedDim, light.primaryFixedDim);
    expect(dark.secondaryFixedDim, light.secondaryFixedDim);
  });
}
