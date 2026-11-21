import 'package:test/test.dart';
import 'package:unibox_material/unibox_material.dart';

/// Holds the model's density to Flutter's own answer.
///
/// `VisualDensity.adaptivePlatformDensity` is `standard` on touch and `compact` on a desk, and
/// a step is four logical pixels, so a 40 pixel button is 32 there. This is that rule in the
/// model, where both renderers can read it.
void main() {
  test('draws touch platforms at the standard density', () {
    for (final MaterialPlatform platform in <MaterialPlatform>[
      MaterialPlatform.android,
      MaterialPlatform.ios,
      MaterialPlatform.fuchsia,
    ]) {
      expect(MaterialDensity.forPlatform(platform), MaterialDensity.standard);
    }
  });

  test('draws pointer platforms compact', () {
    for (final MaterialPlatform platform in <MaterialPlatform>[
      MaterialPlatform.macos,
      MaterialPlatform.windows,
      MaterialPlatform.linux,
    ]) {
      expect(MaterialDensity.forPlatform(platform), MaterialDensity.compact);
    }
  });

  test('takes eight pixels off a forty pixel control when compact', () {
    expect(MaterialDensity.standard.adjust(40), 40);
    expect(MaterialDensity.compact.adjust(40), 32);
    // Two steps of four pixels, which is what Flutter's compact density is.
    expect(MaterialDensity.compact.vertical, -2);
  });
}
