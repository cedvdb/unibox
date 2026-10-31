import 'package:test/test.dart';
import 'package:unibox_example_html/document.dart';

/// What an example document owes a crawler, a reader and the application that takes it over.
void main() {
  group('an example document', () {
    test('states the language a reader and a crawler need', () {
      expect(buildExampleDocument().write(), contains('<html lang="en">'));
    });

    test('describes the page to a search engine', () {
      final String html = buildExampleDocument().write();

      expect(html, contains('<title>Apartments — Unibox</title>'));
      expect(
        html,
        contains('<meta name="description" content="Six apartments'),
      );
      expect(html, contains('<meta property="og:title"'));
    });

    test('writes the palette into the root, as custom properties', () {
      final String html = buildExampleDocument().write();

      expect(html, contains('--unibox-color-canvas:'));
      expect(html, contains('--unibox-color-accent:'));
    });

    test('points the tree at those properties instead of a value', () {
      expect(
        buildExampleDocument().write(),
        contains('background-color:var(--unibox-color-canvas)'),
      );
    });

    test('says it is a light page, and leaves the reader alone', () {
      // A statement, not a preference: the browser paints its scrollbars and its caret to match
      // the page. The example never follows the system, because it is drawn twice — a document
      // and a Flutter build — and two frames that disagree about the scheme break its one claim.
      final String document = buildExampleDocument().write();

      expect(document, contains('color-scheme:light'));
      expect(document, isNot(contains('prefers-color-scheme')));
    });

    test('gives the page box a height to fill', () {
      // `double.infinity` renders as `100%`, which needs something to resolve against.
      expect(
        buildExampleDocument().write(),
        contains('html, body { height: 100%'),
      );
    });

    test('removes the default body margin', () {
      expect(buildExampleDocument().write(), contains('margin: 0'));
    });

    test(
      'asks for the family both hosts ship, and declares its four weights',
      () {
        final String html = buildExampleDocument().write();

        expect(html, contains('font-family: UniboxText'));

        for (final String weight in <String>['400', '500', '600', '700']) {
          expect(html, contains('font-weight: $weight;'));
          expect(html, contains('roboto-$weight.woff2'));
        }
      },
    );

    test('renders the shared tree, with its text as text', () {
      final String html = buildExampleDocument().write();

      // The dialog's copy is not here: the form is only in the tree while it is open.
      expect(html, contains('Rue de Turenne 12'));
      expect(html, contains('data-unibox-node="text"'));
    });

    test('publishes the state the application starts in, with no dialog', () {
      // A dialog is not a page: nothing links to it and a crawler has nothing to index
      // under it, so the one document is the page the form opens over.
      final String html = buildExampleDocument().write();

      expect(html, isNot(contains('role="dialog"')));
      expect(html, contains('Rue de Turenne 12'));
    });

    test('marks the page title as a heading', () {
      // A crawler reads structure, not a font size.
      expect(buildExampleDocument().write(), contains('<h1'));
    });

    test('names the build it came from when it is told one', () {
      expect(
        buildExampleDocument(build: 'abc123').write(),
        contains('<meta name="unibox-build" content="abc123">'),
      );
      expect(buildExampleDocument().write(), isNot(contains('unibox-build')));
    });

    test('carries the client rendering, and starts no application', () {
      // The page a reader acts on is the page a crawler read: a document that runs itself. Nothing
      // here downloads Flutter, so an inspector sees markup and a press is answered by the client.
      final String html = buildExampleDocument().write();

      expect(html, contains('src="../main.client.js"'));
      expect(html, isNot(contains('unibox.boot')));
      expect(html, isNot(contains('flutter/app.js')));
    });

    test('says which tree it draws, so one bundle serves both pages', () {
      expect(
        buildExampleDocument().write(),
        contains('<meta name="unibox-page" content="example">'),
      );
    });
  });
}
