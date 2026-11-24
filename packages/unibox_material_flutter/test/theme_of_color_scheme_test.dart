import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_material/unibox_material.dart' as material;
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

/// A role a design system adds to Material's own.
enum BrandRole { star }

void main() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
  );

  test('answers every role the model names with the scheme it was given', () {
    final core.UniboxTheme theme = uniboxThemeOf(scheme);

    expect(
      theme.colors[material.MaterialColorRole.surface],
      core.BoxColor(scheme.surface.toARGB32()),
      reason: 'a tree drawn with this theme paints the page the app paints',
    );
    expect(
      theme.colors[material.MaterialColorRole.primary],
      core.BoxColor(scheme.primary.toARGB32()),
    );
    expect(theme.colorScheme, core.BoxColorScheme.light);

    // Every role the model can name is answered, or a tree that names one validates badly.
    for (final material.MaterialColorRole role
        in material.MaterialColorRole.values) {
      expect(theme.colors[role], isNotNull, reason: 'no answer for $role');
    }
  });

  test('maps brightness, so a dark scheme is a dark page', () {
    final ColorScheme dark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    );

    expect(uniboxThemeOf(dark).colorScheme, core.BoxColorScheme.dark);
  });

  test('carries the roles a design system adds', () {
    const core.BoxColor star = core.BoxColor(0xFFFFB68D);
    final core.UniboxTheme theme = uniboxThemeOf(
      scheme,
      also: <Enum, core.BoxColor>{BrandRole.star: star},
    );

    expect(theme.colors[BrandRole.star], star);
  });

  test(
    'states a state layer as a shade of the content colour the palette names',
    () {
      final core.UniboxTheme theme = uniboxThemeOf(scheme);
      final core.BoxColor hover =
          theme.colors[material.MaterialColorRole.hoverLayer]!;
      final core.BoxColor pressed =
          theme.colors[material.MaterialColorRole.pressedLayer]!;

      // Material's numbers over the scheme's own `onSurface`, which is what `MaterialPalette`
      // states too: a theme read from a scheme and a theme grown from a seed have to answer the
      // same layer, or one declaration is painted two ways. A hover was black at four percent
      // here once — a scheme has no field for a layer, so it was written as a rule and the two
      // rules disagreed.
      final int onSurface = scheme.onSurface.toARGB32();
      expect(hover.value, (20 << 24) | (onSurface & 0xFFFFFF));
      expect(pressed.value, (26 << 24) | (onSurface & 0xFFFFFF));
    },
  );
}
