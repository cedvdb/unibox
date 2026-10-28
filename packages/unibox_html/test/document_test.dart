import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('a document', () {
    test('states the encoding before anything a browser has to guess', () {
      // A browser that has to guess the encoding may reparse the whole document.
      expect(
        toDocument(const core.TextNode('Hi')),
        startsWith(
          '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">',
        ),
      );
    });

    test('states the language a reader and a crawler need', () {
      expect(
        toDocument(const core.TextNode('Hi'), lang: 'nl'),
        contains('<html lang="nl">'),
      );
    });

    test('carries the title a result links and a tab shows', () {
      expect(
        toDocument(const core.TextNode('Hi'), title: 'Apartments'),
        contains('<title>Apartments</title>'),
      );
    });

    test('cannot be broken by the text it is given', () {
      // A title comes from data as often as from code.
      final String html = toDocument(
        const core.TextNode('Hi'),
        title: '</title><script>alert(1)</script>',
        description: '" onload="alert(1)',
      );

      expect(html, isNot(contains('<script>alert(1)</script>')));
      expect(html, contains('&lt;/title&gt;'));
      expect(html, contains('&quot; onload=&quot;'));
    });

    test('points at itself, so a duplicate is not a competitor', () {
      expect(
        toDocument(
          const core.TextNode('Hi'),
          canonical: 'https://example.com/apartments/',
        ),
        contains(
          '<link rel="canonical" href="https://example.com/apartments/">',
        ),
      );
    });

    test('carries what a link preview shows', () {
      // The other half of being found: a preview with no description shows a url.
      final String html = toDocument(
        const core.TextNode('Hi'),
        title: 'Apartments',
        description: 'Six flats.',
      );

      expect(html, contains('<meta property="og:title" content="Apartments">'));
      expect(
        html,
        contains('<meta property="og:description" content="Six flats.">'),
      );
    });

    test('takes metadata a host needs and the model does not know', () {
      expect(
        toDocument(
          const core.TextNode('Hi'),
          meta: <String, String>{'robots': 'noindex'},
        ),
        contains('<meta name="robots" content="noindex">'),
      );
    });

    test('puts the stylesheet in the head, so nothing flashes unstyled', () {
      final String html = toDocument(const core.Box());
      final int style = html.indexOf('<style>');
      final int body = html.indexOf('<body>');

      expect(style, isNot(-1));
      expect(style, lessThan(body));
    });

    test('carries markup the host owns and the model does not describe', () {
      // The `@font-face` rules of the asset it ships, a dark-mode block, structured data:
      // written verbatim, which is why a host passes text and never reader data.
      final String html = toDocument(
        const core.TextNode('Hi'),
        head: <String>[
          '<style>@font-face{font-family:UniboxText;src:url(a.ttf)}</style>',
        ],
      );

      expect(html, contains('@font-face{'));
      expect(
        html.indexOf('@font-face'),
        lessThan(html.indexOf('<body>')),
        reason: 'a font face has to arrive before the text that uses it',
      );
    });

    test('carries the scripts the host needs, deferred', () {
      final String html = toDocument(
        const core.TextNode('Hi'),
        scripts: const <DocumentScript>[DocumentScript(src: '/app.js')],
      );

      expect(html, contains('<script src="/app.js" defer></script>'));
    });

    test('takes a nonce for a policy that refuses inline script', () {
      final String html = toDocument(
        const core.TextNode('Hi'),
        scripts: const <DocumentScript>[
          DocumentScript.inline(body: 'go()', nonce: 'r4nd0m'),
        ],
      );

      expect(html, contains('<script nonce="r4nd0m">go()</script>'));
    });

    test('cannot be pointed anywhere a script would run', () {
      expect(
        toDocument(const core.TextNode('Hi'), canonical: 'javascript:alert(1)'),
        contains('href="#"'),
      );
    });

    test('is the tree in the body, exactly as a fragment renders it', () {
      final String html = toDocument(const core.TextNode('Hi'));

      expect(html, contains('<body><span'));
      expect(html, contains('>Hi</span></body>'));
    });
  });
}
