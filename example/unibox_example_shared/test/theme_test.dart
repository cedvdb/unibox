import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

void main() {
  test(
    'both hosts resolve the declaration roles from their supplied palette',
    () {
      for (final seed in ExampleSeed.values) {
        final palette = ExamplePalette.materialFor(seed);
        final theme = ExamplePalette.themeFor(seed);
        expect(
          theme.resolve(const BoxColor.role(MaterialColorRole.primary)),
          palette.primary,
        );
        expect(
          theme.resolve(const BoxColor.role(MaterialColorRole.surface)),
          palette.surface,
        );
      }
      expect(
        ExamplePalette.materialFor(ExampleSeed.blue).primary,
        isNot(ExamplePalette.materialFor(ExampleSeed.rose).primary),
      );
    },
  );
}
