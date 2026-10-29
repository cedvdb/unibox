import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

/// A frame that draws nothing: the page is readable without a host.
UINode _frame({required String src, required String title}) =>
    Box(key: src, children: <UINode>[TextNode(title)]);

/// A frame that draws nothing and says nothing, so the only words read back are the
/// page's own.
UINode _emptyFrame({required String src, required String title}) => const Box();

/// Every node of [root], depth first.
///
/// A `StatefulNode` has no children of its own — it draws the tree of a store — so
/// what it draws for the state a fresh store starts in stands in for it. That is the
/// state a server renders, which is what the page is being read as here.
Iterable<UINode> _flatten(UINode root) sync* {
  yield root;

  if (root is StatefulNode<Object, Store<Object>>) {
    final Store<Object> store = root.createStore();
    final UINode view = root.viewFor(store.state, store);
    store.dispose();
    yield* _flatten(view);
    return;
  }

  for (final UINode child in root.children) {
    yield* _flatten(child);
  }
}

/// The `level|text` of every heading, which is the outline of the page.
Iterable<String> _headings(UINode page) sync* {
  for (final UINode node in _flatten(page)) {
    if (node is TextNode && node.headingLevel != null) {
      yield '${node.headingLevel}|${node.text}';
    }
  }
}

void main() {
  group('buildSitePage', () {
    test('is one page with one h1 and a band under it', () {
      final UINode page = buildSitePage(frame: _frame);
      final List<String> headings = _headings(page).toList();

      // The hero makes the claim, so its line is the one h1; each band is an h2 and
      // each block of the catalogue an h3, which is the outline a crawler and a
      // screen reader build the document from.
      expect(
        headings.where((String heading) => heading.startsWith('1|')),
        <String>['1|Describe a screen once.'],
      );
      expect(
        headings,
        containsAll(<String>[
          '2|The same tree, drawn twice',
          '2|Material 3, as values and nodes',
          '3|Type scale',
          '3|Navigation bar',
          '3|Dialog',
        ]),
      );
      // The catalogue carries the palette picker, so the page names the example's
      // roles as well as Material's: one theme, both vocabularies.
      expect(
        validateTree(page, theme: ExamplePalette.themeFor(ExampleSeed.blue)),
        isEmpty,
      );
    });

    test('frames the same screen in both renderings', () {
      final UINode page = buildSitePage(frame: _frame);
      final List<Object?> frames = <Object?>[
        for (final UINode node in _flatten(page))
          if (node.key != null) node.key,
      ];

      // The stub frame keys itself with its source, so the page names the two
      // documents the comparison shows: the web rendering and the Flutter build —
      // each told which palette to draw, because a frame is a document of its own.
      expect(
        frames,
        containsAll(<Object?>[
          'web/listings/?seed=blue',
          'flutter/listings/?seed=blue',
        ]),
      );
    });

    test('draws the frames in the palette the catalogue picked', () {
      final UINode page = buildSitePage(frame: _frame, seed: ExampleSeed.rose);
      final List<Object?> sources = <Object?>[
        for (final UINode node in _flatten(page))
          if (node.key != null) node.key,
      ];

      expect(
        sources,
        containsAll(<Object?>[
          'web/listings/?seed=rose',
          'flutter/listings/?seed=rose',
        ]),
      );
    });

    test(
      'offers the source, and shows the example instead of linking to it',
      () {
        final UINode page = buildSitePage(frame: _frame);
        final List<LinkNode> links = <LinkNode>[
          for (final UINode node in _flatten(page))
            if (node is LinkNode) node,
        ];

        expect(
          links.map((LinkNode link) => link.url),
          containsAll(<String>[repositoryUrl, '$repositoryUrl#readme']),
        );

        // Nothing on this page opens the example: it is drawn in the two frames and
        // that is the only way it is seen from here.
        expect(
          links.where(
            (LinkNode link) =>
                link.url.startsWith('web/') || link.url.startsWith('flutter/'),
          ),
          isEmpty,
        );
      },
    );

    test('leads with the components, then the scale, then the palette', () {
      final List<String> blocks = _headings(buildSitePage(frame: _frame))
          .where((String heading) => heading.startsWith('3|'))
          .map((String heading) => heading.substring(2))
          .toList();

      // The order is the request, not an accident: a page is built out of
      // components, and the scale and the palette are what those components name.
      expect(blocks, <String>[
        'Buttons',
        'Chips',
        'Segments',
        'Text fields',
        'Cards and tiles',
        'Navigation bar',
        'Dialog',
        'Type scale',
        'Colour roles',
        'Shapes',
      ]);
    });

    test('describes the page as a document', () {
      final UINode page = buildSitePage(frame: _frame);
      final List<BoxElement> landmarks = <BoxElement>[
        for (final UINode node in _flatten(page))
          if (node is Box &&
              node.semantics != null &&
              node.semantics!.element.isLandmark)
            node.semantics!.element,
      ];

      // A reader can jump to the header, the content and the footer, and the bands
      // sit inside the content rather than beside it. The navigation landmark is the
      // navigation bar demo inside the catalogue, which is a real `nav` too.
      expect(
        landmarks,
        containsAll(<BoxElement>[
          BoxElement.header,
          BoxElement.main,
          BoxElement.footer,
        ]),
      );
      expect(landmarks.first, BoxElement.header);
      expect(landmarks.last, BoxElement.footer);
    });

    test('says what the page is, in the hero', () {
      final List<String> texts = <String>[
        for (final UINode node in _flatten(buildSitePage(frame: _frame)))
          if (node is TextNode) node.text,
      ];

      expect(texts, contains('Describe a screen once.'));
      // The claim is drawn as well as written: both renderings are on the page.
      expect(texts, contains('HTML and CSS — the document'));
      expect(texts, contains('Flutter — the same tree'));
      // Neither rendering is a call to action: the page has no way into the example.
      expect(texts, isNot(contains('Open the example')));
      expect(texts, isNot(contains('The Flutter build')));
    });

    test('names each rendering once, and shows it rather than a picture of it', () {
      final List<String> texts = <String>[
        for (final UINode node in _flatten(buildSitePage(frame: _emptyFrame)))
          if (node is TextNode) node.text,
      ];

      // The claim used to end in two stub cards captioned with the same two names, and
      // the band below it framed the real thing under those names again — the page told
      // a reader the point twice, once as a diagram and once for real. The frames are
      // the claim's answer, in the claim's band, so each name is written once.
      expect(
        texts.where((String text) => text == 'HTML and CSS — the document'),
        hasLength(1),
      );
      expect(
        texts.where((String text) => text == 'Flutter — the same tree'),
        hasLength(1),
      );
      expect(texts, isNot(contains('Sunny flat, 62 m²')));
    });
  });
}
