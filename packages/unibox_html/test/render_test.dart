import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('a text', () {
    test('is a span, so it flows inline like a Flutter Text in a Row', () {
      expect(toHtml(const core.TextNode('Hi')), contains('<span'));
      expect(toHtml(const core.TextNode('Hi')), contains('>Hi</span>'));
    });

    test('is a heading at the level it states', () {
      // A crawler reads structure, not a font size.
      expect(
        toHtml(const core.TextNode('Flats', headingLevel: 1)),
        contains('<h1'),
      );
      expect(
        toHtml(const core.TextNode('Flats', headingLevel: 3)),
        contains('<h3'),
      );
    });

    test('cannot smuggle markup into the page', () {
      expect(
        toHtml(const core.TextNode('<script>alert(1)</script>')),
        contains('&lt;script&gt;'),
      );
    });

    test('carries the name of its node, and its key when it has one', () {
      final String html = toHtml(const core.TextNode('Hi', key: 'greeting'));

      expect(html, contains('data-unibox-node="text"'));
      expect(html, contains('data-unibox-key="greeting"'));
    });
  });

  group('a box', () {
    test('is a flex container with one class for its look', () {
      final String html = toHtml(const core.Box());

      expect(html, contains('<div'));
      expect(html, contains('class="unibox-box-'));
      expect(html, contains('data-unibox-node="box"'));
    });

    test('writes the look once, so six elements cost one rule', () {
      final String html = toHtml(
        const core.Box(
          children: <core.UINode>[
            core.Box(backgroundColor: core.BoxColor.white),
            core.Box(backgroundColor: core.BoxColor.white),
          ],
        ),
      );
      final Iterable<RegExpMatch> classes = RegExp(r'unibox-box-[0-9a-f]{8}')
          .allMatches(html);

      // The two white boxes share a class; the root has its own.
      expect(
        classes.map((RegExpMatch match) => match[0]).toSet(),
        hasLength(2),
      );
    });

    test('renders the element its semantics name', () {
      expect(
        toHtml(
          const core.Box(
            semantics: core.BoxSemantics(element: core.BoxElement.main),
          ),
        ),
        contains('<main'),
      );
    });

    test('writes the role the box asks for, keeping the element it names', () {
      // A `<nav>` is a navigation landmark by itself; `role="link"` is the box saying
      // something else about it.
      final String html = toHtml(
        const core.Box(
          semantics: core.BoxSemantics(
            element: core.BoxElement.nav,
            role: core.BoxRole.link,
          ),
        ),
      );

      expect(html, contains('<nav'));
      expect(html, contains('role="link"'));
    });

    test('announces a disabled box and keeps its layout', () {
      final String html = toHtml(
        const core.Box(
          enabled: false,
          onTap: noop,
          semantics: core.BoxSemantics(role: core.BoxRole.button),
        ),
      );

      expect(html, contains('aria-disabled="true"'));
      expect(html, isNot(contains('tabindex')));
    });

    test('writes the state rules of its look', () {
      final String html = toHtml(
        const core.Box(hoverStyle: core.BoxStyle(opacity: 0.9)),
      );

      // A hover only applies where a pointer can hover, so a phone cannot get stuck in
      // a hovered look after a tap.
      expect(html, contains('@media (hover: hover)'));
      expect(html, contains(':hover'));
    });

    test('reports a width threshold it cannot draw yet', () {
      expect(
        () => toHtml(const core.Box(visibleFrom: 600)),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('an image', () {
    test('reserves its box before the picture arrives', () {
      // The difference between a page that settles and one that shifts.
      final String html = toHtml(
        const core.ImageNode('a.png', alt: 'A flat', width: 200, height: 100),
      );

      expect(html, contains('width="200"'));
      expect(html, contains('height="100"'));
      expect(html, contains('alt="A flat"'));
    });

    test('writes the loading hints the node states', () {
      final String html = toHtml(
        const core.ImageNode(
          'a.png',
          alt: 'A flat',
          loading: core.ImageLoading.lazy,
          fetchPriority: core.ImageFetchPriority.high,
        ),
      );

      expect(html, contains('loading="lazy"'));
      expect(html, contains('fetchpriority="high"'));
    });

    test('says nothing a browser would have done anyway', () {
      // `eager` and `auto` are the defaults, and a document states what it wants.
      final String html = toHtml(const core.ImageNode('a.png', alt: 'A flat'));

      expect(html, isNot(contains('loading=')));
      expect(html, isNot(contains('fetchpriority=')));
    });

    test('cannot point at a script', () {
      expect(
        toHtml(const core.ImageNode('javascript:alert(1)', alt: 'A')),
        contains('src="#"'),
      );
    });
  });

  group('a link', () {
    test('is an anchor a crawler follows, with real text inside it', () {
      final String html = toHtml(
        const core.LinkNode('/listings', child: core.TextNode('Listings')),
      );

      expect(html, contains('<a'));
      expect(html, contains('href="/listings"'));
      expect(html, contains('>Listings</span>'));
    });

    test('hands no opener to the page it opens in a new tab', () {
      final String html = toHtml(
        const core.LinkNode(
          'https://example.com',
          newTab: true,
          child: core.TextNode('Elsewhere'),
        ),
      );

      expect(html, contains('target="_blank"'));
      expect(html, contains('rel="noopener noreferrer"'));
    });

    test('inherits the look of the text around it', () {
      // A browser paints every link blue and underlined, which the Flutter renderer
      // cannot draw.
      final String html = toHtml(
        const core.LinkNode('/x', child: core.TextNode('Go')),
      );

      expect(html, contains('color:inherit'));
      expect(html, contains('text-decoration:none'));
    });
  });

  group('a node this renderer cannot draw', () {
    test('is reported instead of skipped', () {
      // A tree built for another target fails loudly rather than shipping a page with a
      // piece missing.
      expect(
        () => toHtml(const core.StackNode()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('the sheet', () {
    test('starts from the typography of the model', () {
      final String html = toHtml(const core.Box());

      expect(html, startsWith('<style>'));
      expect(html, contains(':root{'));
      expect(html, contains('font-size:16px'));
    });
  });
}

/// A callback a box can carry; a document writes no listener for it.
void noop() {}
