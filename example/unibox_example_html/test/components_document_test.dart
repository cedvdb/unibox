import 'package:test/test.dart';
import 'package:unibox_example_html/document.dart';

/// Holds the components page to the document a reader without Flutter is served.
///
/// The page exists to be compared with the app that draws the same tree with Flutter's own
/// widgets, so the document has to say what the tree says: every component's words, and the
/// landmark each control states.
void main() {
  final String html = buildComponentsDocument().write();

  test('carries the words of every component on the page', () {
    expect(html, contains('Filled'));
    expect(html, contains('Two rooms'));
    expect(html, contains('Day'));
    expect(html, contains('Garden'));
  });

  test(
    'writes a chosen segment as a pressed control, the way the tree asks',
    () {
      // The segmented button states the role and the choice; a document that dropped either would
      // draw a pill a reader cannot tell apart from three labels.
      expect(html, contains('aria-pressed="true"'));
    },
  );

  test('says which page it is, and carries the stylesheet in the head', () {
    expect(html, contains('unibox-page'));
    expect(html, contains('<style>'));
  });
}
