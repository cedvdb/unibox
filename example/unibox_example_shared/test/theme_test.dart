import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// Keeps the example's two vocabularies apart.
///
/// The page names [ExampleColor] roles and draws components from
/// `unibox_material`, which name [MaterialColorRole]s of their own, so one theme
/// answers both. On the web a role is a custom property named after the enum
/// member: two members called `surface` would write `--unibox-color-surface`
/// twice, and the browser would keep the last while Flutter resolved each one —
/// the search field was the Material pink in the app and the example's white on the
/// page, which no token table can catch because both renderers were right about
/// their own colour.
void main() {
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
      MaterialPalette.light.surface,
      reason: 'a Material component keeps the colour its palette states',
    );
  });
}
