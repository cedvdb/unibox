import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';

/// What an icon button becomes in a document.
///
/// A control with no text has one name and one number: `aria-label` is what a reader
/// hears, and the badge is a picture of a count rather than a second thing to read —
/// which is `aria-hidden` in the markup and not a matter of taste.
void main() {
  // A glyph as a Material Symbols font carries it: one character, and one that is a
  // picture of the control's name rather than a second name.
  final core.UINode glyph = MaterialIcon.codePoint(0xe9b2);

  String render(MaterialIconButton button) =>
      toHtml(button, theme: MaterialPalette.lightTheme);

  MaterialIconButton button({
    MaterialIconButtonVariant variant = MaterialIconButtonVariant.standard,
    int? badgeCount,
    String? label = 'Filters',
  }) => MaterialIconButton(
    icon: glyph,
    label: label,
    variant: variant,
    badgeCount: badgeCount,
    onTap: () {},
  );

  group('an icon button', () {
    test('is a button named by its label', () {
      final String html = render(button());

      expect(html, contains('role="button"'));
      expect(html, contains('aria-label="Filters"'));
      // The glyph is a picture of the name; it is not a second name.
      expect(html, contains('aria-hidden="true"'));
    });

    test('leaves the reading order when it has no name', () {
      expect(render(button(label: null)), contains('aria-hidden="true"'));
      expect(render(button(label: null)), isNot(contains('aria-label=')));
    });

    test('paints the four shapes from roles', () {
      expect(
        render(button(variant: MaterialIconButtonVariant.filled)),
        contains('background-color:var(--unibox-color-primary)'),
      );
      expect(
        render(button(variant: MaterialIconButtonVariant.tonal)),
        contains('background-color:var(--unibox-color-secondary-container)'),
      );
      expect(
        render(button(variant: MaterialIconButtonVariant.outlined)),
        contains('border-color:var(--unibox-color-outline)'),
      );
      expect(
        render(button()),
        isNot(contains('border-color:var(--unibox-color-outline)')),
        reason: 'the standard shape has no line',
      );
    });

    test('puts the count in a pill of its own, out of the reading order', () {
      final String html = render(button(badgeCount: 3));

      expect(html, contains('background-color:var(--unibox-color-error)'));
      expect(html, contains('>3</span>'));
      // The pill is painted over the square rather than beside it, which is a layer.
      expect(html, contains('position:absolute'));
      expect(html, contains('-webkit-line-clamp:1'));
    });

    test('draws no badge for a count of nothing', () {
      for (final MaterialIconButton plain in <MaterialIconButton>[
        button(),
        button(badgeCount: 0),
      ]) {
        expect(render(plain), isNot(contains('position:absolute')));
        expect(render(plain), isNot(contains('>0</span>')));
      }
    });
  });
}
