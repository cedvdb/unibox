import 'package:test/test.dart';
import 'package:unibox_example_html/site/site_document.dart';

/// What the site owes a reader and a crawler.
///
/// It is one page drawn with the library it documents: the claim, the comparison and the
/// catalogue are bands of one tree, and the comparison frames the example below it.
void main() {
  group('the site document', () {
    test('is one page, with one title and one description', () {
      final String html = buildSiteDocument().write();

      expect(
        html,
        contains(
          '<title>Unibox — SEO-friendly Flutter Web without duplicating your UI</title>',
        ),
      );
      expect(
        html,
        contains(
          '<meta name="description" content="Flutter SEO without a second UI',
        ),
      );
      expect(html, contains('<html lang="en">'));
    });

    test('is written as one outline a crawler can read', () {
      final String html = buildSiteDocument().write();

      // Real headings, not a heading drawn as a bold span.
      expect(html, contains('<h1'));
      expect(html, contains('<h2'));
      expect(html, contains('<main'));
    });

    test('draws the vocabulary as a picture and as the list of it', () {
      final String html = buildSiteDocument().write();

      // The second band: one card, drawn from the nodes the page had not shown, the
      // same card taken apart as text — which is the argument of the whole site — and
      // the two calls that list is for.
      expect(html, contains('Just boxes'));
      expect(html, contains('alt="A living room'));
      expect(html, contains('placeholder="Search the listings"'));
      expect(html, contains('PositionedNode'));
      expect(html, contains('node.toWidget()'));
      expect(html, contains('node.toHtml()'));
    });

    test(
      'shows the markup a crawler is served, as text rather than a picture',
      () {
        final String html = buildSiteDocument().write();

        // The band's evidence is a document quoted in the page, so the tags arrive escaped:
        // a crawler indexing this site reads the same words a reader does, which is the
        // claim the band is making in the first place.
        expect(html, contains('Make Flutter Web pages indexable'));
        expect(html, contains('&lt;h1&gt;Apartments in Amsterdam&lt;/h1&gt;'));
        expect(html, contains('class names elided'));
        expect(html, contains('Adopted one page at a time'));
      },
    );

    test('writes the structure as elements, not as a page of divs', () {
      final String html = buildSiteDocument().write();

      // Every band is a `section`, and so is every block of the catalogue — which is
      // what makes the two counts agree: four bands, then one section per `h3`.
      expect(
        '<section'.allMatches(html).length,
        4 + '<h3'.allMatches(html).length,
      );
      // The node list of the vocabulary is a list, the listing card an article, and each
      // code sample a figure whose caption names it.
      expect(html, contains('<ul'));
      expect(html, contains('<li'));
      expect(html, contains('<article'));
      expect(html, contains('<figure'));
      expect(html, contains('<figcaption'));
    });

    test('moves the two arrows, three passes and then still', () {
      // The arrows are the one part of the page whose reason is motion, and the motion is the
      // site's: a key is the hook it names them by, so no class is invented for a look only
      // this page has. Three passes rather than a loop, and nothing at all for a reader who
      // asked their system for less motion.
      final String html = buildSiteDocument().write();

      expect(html, contains('@keyframes unibox-flow'));
      expect(html, contains('[data-unibox-key="hero-flow-html"]'));
      expect(html, contains('[data-unibox-key="hero-flow-flutter"]'));
      expect(html, contains('prefers-reduced-motion: reduce'));
      expect(html, contains('animation: unibox-flow'));
    });

    test('frames the same screen in both branches of the diagram', () {
      final String html = buildSiteDocument().write();

      expect('<iframe'.allMatches(html), hasLength(2));
      // Each frame is labelled with the branch it belongs to, which is what a screen
      // reader announces in place of the branch heading.
      expect(html, contains('title="Flutter"'));
      expect(html, contains('title="HTML and CSS"'));
      expect(html, contains('src="web/listings/'));
      expect(html, contains('src="web/takeover/'));
    });

    test('gives each frame the box the tree drew, and no grip', () {
      // A comparison is between two windows of one size: a reader who drags one narrower is no
      // longer comparing like with like. The frame fills its box and offers nothing else.
      final RegExpMatch frame = RegExp(r'<iframe[^>]*>')
          .firstMatch(buildSiteDocument().write())!;

      // The frame, not the stylesheet: a text input states `resize: none` there, and that is a
      // different element's business.
      expect(frame.group(0), contains('width:100%;height:100%'));
      expect(frame.group(0), isNot(contains('resize')));
    });

    test(
      'does not let the wrapper this renderer invents take part in the layout',
      () {
        // The embed is written in a `div`, and that `div` is the renderer's: `display: contents`
        // makes the frame a child of the box the tree drew, so its `height: 100%` resolves
        // against that box instead of against a wrapper of unknown height.
        expect(buildSiteDocument().write(), contains('display:contents'));
      },
    );

    test('installs the palette its roles are named from', () {
      expect(buildSiteDocument().write(), contains('--unibox-color-accent:'));
    });

    test('does not give the document the height of a viewport', () {
      // The page is longer than a window: it scrolls, and its bands paint down its length.
      expect(buildSiteDocument().write(), isNot(contains('height: 100%')));
    });

    test('names the build it came from when it is told one', () {
      expect(
        buildSiteDocument(build: 'abc123').write(),
        contains('<meta name="unibox-build" content="abc123">'),
      );
    });

    test('carries the recorders and no boot', () {
      // The site is a document with a catalogue to press things in; nothing here starts an
      // application over it.
      final String html = buildSiteDocument().write();

      expect(html, contains('unibox.takePressed'));
      expect(html, isNot(contains('unibox.boot')));
    });
  });
}
