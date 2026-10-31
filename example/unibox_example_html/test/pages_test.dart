import 'package:test/test.dart';
import 'package:unibox_example_html/site/pages.dart';
import 'package:unibox_html/unibox_html.dart';

/// The site as a build sees it: pages beside the paths they are written to, and the sitemap
/// that lists them.
void main() {
  group('the site as pages', () {
    test('gives every page the address it is served at', () {
      final List<({String path, Document document})> pages = sitePages(
        url: 'https://example.com/unibox/',
      );
      final Map<String, String?> addresses = <String, String?>{
        for (final ({String path, Document document}) page in pages)
          page.path: page.document.head.canonical,
      };

      // The root for `index.html`, and the directory for a directory's `index.html`: a page is
      // served where its file is, without the file name.
      expect(addresses['index.html'], 'https://example.com/unibox/');
      expect(
        addresses['web/listings/index.html'],
        'https://example.com/unibox/web/listings/',
      );
      expect(
        addresses['web/takeover/index.html'],
        'https://example.com/unibox/web/takeover/',
      );
    });

    test('gives a root the slash it was written without', () {
      expect(
        sitePages(url: 'https://example.com/unibox')
            .first
            .document
            .head
            .canonical,
        'https://example.com/unibox/',
      );
    });

    test('states no address when the build does not know one', () {
      // A canonical url is not something a build can guess, so a local build states none.
      for (final ({String path, Document document}) page in sitePages()) {
        expect(page.document.head.canonical, isNull);
      }
    });

    test('lists in the sitemap the address each page calls its own', () {
      final List<({String path, Document document})> pages = sitePages(
        url: 'https://example.com/unibox/',
      );
      final String sitemap = sitemapOf(pages);

      for (final ({String path, Document document}) page in pages) {
        expect(sitemap, contains('<loc>${page.document.head.canonical}</loc>'));
      }

      // One entry per page: a page cannot be written without being listed.
      expect('<url>'.allMatches(sitemap).length, pages.length);
    });

    test('lists nothing when no page states an address', () {
      expect(sitemapOf(sitePages()), isNot(contains('<loc>')));
    });
  });
}
