import 'package:test/test.dart';
import 'package:unibox_example_html/document.dart';

/// Holds the components page to the document a reader without Flutter is served.
///
/// The page exists to be compared with the app that draws the same tree with Flutter's own
/// widgets, so the document has to say what the tree says: every component's words, and the
/// `nav` landmark the bar carries.
void main() {
  final String html = buildComponentsDocument().write();

  test('carries the words of every component on the page', () {
    for (final String label in <String>[
      'Cards',
      'Buttons',
      'Chips',
      'Segments',
      'Typography',
      'Display large',
      'Headline medium',
      'Body medium',
      'Colour roles',
    ]) {
      expect(html, contains(label));
    }
  });

  test('writes each specimen as a named section', () {
    expect(RegExp('<section').allMatches(html).length, greaterThanOrEqualTo(6));
  });

  test('says which page it is, and carries the stylesheet in the head', () {
    expect(html, contains('unibox-page'));
    expect(html, contains('<style>'));
  });
  test('displays specimens rather than linking to other pages', () {
    expect(html, isNot(contains('<a ')));
    expect(html, contains('Display large'));
    expect(html, contains('Label small'));
  });
}
