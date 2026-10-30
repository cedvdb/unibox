import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';

/// What a chip becomes in a document.
///
/// The close of an input chip is a control with no text of its own — a cross — so its
/// name exists only in `aria-label`. A row of applied filters therefore reads as eleven
/// identical "Remove" buttons unless the caller names each one, and a name that is not
/// written into the element is a name a screen reader never hears.
void main() {
  String render(MaterialChip chip) =>
      toHtml(chip, theme: MaterialPalette.lightTheme);

  MaterialChip chip({String? removeSemanticsLabel}) => MaterialChip(
    label: const core.TextNode('Garden'),
    trailing: const core.TextNode('×'),
    onRemove: () {},
    removeSemanticsLabel: removeSemanticsLabel,
  );

  group('a chip with a close', () {
    test('writes the name of the chip into the cross', () {
      expect(
        render(chip(removeSemanticsLabel: 'Remove Garden')),
        contains('aria-label="Remove Garden"'),
      );
    });

    test('says what the cross means when the name is left out', () {
      expect(render(chip()), contains('aria-label="Remove"'));
    });
  });
}
