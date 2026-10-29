import 'package:test/test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_example_html/document.dart';

/// What an example document owes a crawler, a reader and the application that takes it over.
void main() {
  group('an example document', () {
    test('states the language a reader and a crawler need', () {
      expect(buildExampleDocument(), contains('<html lang="en">'));
    });

    test('describes the page to a search engine', () {
      final String html = buildExampleDocument(page: ExamplePage.apartments);

      expect(html, contains('<title>Apartments — Unibox</title>'));
      expect(
        html,
        contains('<meta name="description" content="Six apartments'),
      );
      expect(html, contains('<meta property="og:title"'));
    });

    test('gives each state of the example its own words', () {
      // Two documents that share a title look like one page twice to a search engine.
      expect(
        buildExampleDocument(page: ExamplePage.signup),
        contains('<title>Join Unibox — sign up</title>'),
      );
    });

    test('writes the palette into the root, as custom properties', () {
      final String html = buildExampleDocument();

      expect(html, contains('--unibox-color-canvas:'));
      expect(html, contains('--unibox-color-accent:'));
    });

    test('points the tree at those properties instead of a value', () {
      expect(
        buildExampleDocument(),
        contains('background-color:var(--unibox-color-canvas)'),
      );
    });

    test('lets a dark browser outrank the tree', () {
      // A host keeps the last word: the tree says "the canvas role", and this block says what
      // that role is worth in a dark browser.
      expect(buildExampleDocument(), contains('(prefers-color-scheme: dark)'));
    });

    test('gives the page box a height to fill', () {
      // `double.infinity` renders as `100%`, which needs something to resolve against.
      expect(buildExampleDocument(), contains('html, body { height: 100%'));
    });

    test('removes the default body margin', () {
      expect(buildExampleDocument(), contains('margin: 0'));
    });

    test(
      'asks for the family both hosts ship, and declares its four weights',
      () {
        final String html = buildExampleDocument();

        expect(html, contains('font-family: UniboxText'));

        for (final String weight in <String>['400', '500', '600', '700']) {
          expect(html, contains('font-weight: $weight;'));
          expect(html, contains('roboto-$weight.ttf'));
        }
      },
    );

    test('renders the shared tree, with its text as text', () {
      final String html = buildExampleDocument(page: ExamplePage.signup);

      expect(html, contains('One description, two renderers.'));
      expect(html, contains('data-unibox-node="text"'));
    });

    test('starts with the sign-up dialog over the listings', () {
      // Being open is state, and a static document has nothing to click: the document that
      // exists to show the dialog says so.
      expect(
        buildExampleDocument(page: ExamplePage.signup),
        contains('role="dialog"'),
      );
      expect(
        buildExampleDocument(page: ExamplePage.apartments),
        isNot(contains('role="dialog"')),
      );
    });

    test('marks the page title as a heading', () {
      // A crawler reads structure, not a font size.
      expect(buildExampleDocument(), contains('<h1'));
    });

    test('names the build it came from when it is told one', () {
      expect(
        buildExampleDocument(build: 'abc123'),
        contains('<meta name="unibox-build" content="abc123">'),
      );
      expect(buildExampleDocument(), isNot(contains('unibox-build')));
    });

    test(
      'downloads the bundle while the reader reads, and boots it on intent',
      () {
        final String html = buildExampleDocument();

        expect(html, contains('rel="prefetch" href="../../flutter/app.js"'));
        expect(html, contains('unibox.boot'));
      },
    );

    test('records what the reader did, so the application can pick it up', () {
      final String html = buildExampleDocument();

      expect(html, contains('unibox.takePressed'));
      expect(html, contains('unibox.takeScroll'));
    });
  });
}
