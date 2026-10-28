import 'package:test/test.dart';
import 'package:unibox_example_site/site/site_document.dart';

/// What the site owes a reader and a crawler.
///
/// It is one page drawn with the library it documents: the claim, the comparison and the
/// catalogue are bands of one tree, and the comparison frames the example below it.
void main() {
  group('the site document', () {
    test('is one page, with one title and one description', () {
      final String html = buildSiteDocument();

      expect(html, contains('<title>Unibox — one tree, two renderers</title>'));
      expect(
        html,
        contains('<meta name="description" content="Describe a screen once'),
      );
      expect(html, contains('<html lang="en">'));
    });

    test('is written as one outline a crawler can read', () {
      final String html = buildSiteDocument();

      // Real headings, not a heading drawn as a bold span.
      expect(html, contains('<h1'));
      expect(html, contains('<h2'));
      expect(html, contains('<main'));
    });

    test('frames the same screen in both renderings', () {
      final String html = buildSiteDocument();

      expect('<iframe'.allMatches(html), hasLength(2));
      expect(html, contains('title="Flutter — the same tree"'));
      expect(html, contains('title="Jaspr — HTML and CSS"'));
    });

    test('lets a reader drag a frame narrower', () {
      // The page inside reflows to its own width, so the responsive behaviour is one gesture
      // away instead of one window resize — host chrome, which no node describes.
      expect(buildSiteDocument(), contains('resize:horizontal'));
    });

    test('installs the palette its roles are named from', () {
      expect(buildSiteDocument(), contains('--unibox-color-accent:'));
    });

    test('does not give the document the height of a viewport', () {
      // The page is longer than a window: it scrolls, and its bands paint down its length.
      expect(buildSiteDocument(), isNot(contains('height: 100%')));
    });

    test('names the build it came from when it is told one', () {
      expect(
        buildSiteDocument(build: 'abc123'),
        contains('<meta name="unibox-build" content="abc123">'),
      );
    });

    test('carries the recorders and no boot', () {
      // The site is a document with a catalogue to press things in; nothing here starts an
      // application over it.
      final String html = buildSiteDocument();

      expect(html, contains('unibox.takePressed'));
      expect(html, isNot(contains('unibox.boot')));
    });
  });
}
