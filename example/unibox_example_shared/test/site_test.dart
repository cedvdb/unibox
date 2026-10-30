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
        <String>['1|Flutter UI. Searchable HTML.'],
      );
      expect(
        headings,
        containsAll(<String>[
          '2|HTML and CSS',
          '2|Flutter',
          '2|Make Flutter Web pages indexable',
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

    test('puts the indexable band under the claim, and the catalogue last', () {
      // The order is the reason to adopt the library, then the parts the claim is made
      // of, then the design system all of it is drawn with. The catalogue is what the
      // page closes on.
      final List<String> bands = _headings(buildSitePage(frame: _frame))
          .where((String heading) => heading.startsWith('2|'))
          .toList();

      expect(bands, <String>[
        '2|HTML and CSS',
        '2|Flutter',
        '2|Make Flutter Web pages indexable',
        '2|Just boxes',
        '2|Material 3, as values and nodes',
      ]);
    });

    test(
      'shows the markup a crawler is served, and what Flutter does next',
      () {
        // The band exists for the reader who arrives from a search engine: the same screen
        // written as a tree and served as markup, then the two facts that make it usable —
        // the app takes the page over, and only the pages that have to be found change.
        final List<String> words = <String>[
          for (final UINode node in _flatten(buildSitePage(frame: _emptyFrame)))
            if (node is TextNode) node.text,
        ];

        expect(words, contains('<h1>Apartments in Amsterdam</h1>'));
        expect(words, contains('<a href="apartments/amsterdam">'));
        expect(words, contains('class names elided'));
        expect(
          words,
          containsAll(<String>[
            'Flutter still takes the page over',
            'Adopted one page at a time',
          ]),
        );
      },
    );

    test('names the two calls the taken apart card is for', () {
      // The band's claim is that a screen is containers; its evidence is the list of
      // nodes, and the two calls under it are the whole of what a tree is for — one
      // builds the widgets, one writes the document.
      final List<String> words = _flatten(buildSitePage(frame: _frame))
          .whereType<TextNode>()
          .map((TextNode text) => text.text)
          .toList();

      expect(
        words,
        containsAll(<String>[
          'Just boxes',
          'the same tree, two calls',
          'node.toWidget()',
          'node.toHtml()',
        ]),
      );
    });

    test('keys the two arrows of the diagram, so the site can move them', () {
      // The page draws the diagram; the stylesheet names the arrows by their keys, because a
      // key is what a tree already carries and a class is not in the model.
      final List<TextNode> arrows = _flatten(buildSitePage(frame: _frame))
          .whereType<TextNode>()
          .where((TextNode text) => text.key != null)
          .toList();

      expect(arrows.map((TextNode arrow) => arrow.key), <Object?>[
        'hero-flow-html',
        'hero-flow-flutter',
      ]);
      expect(arrows.every((TextNode arrow) => arrow.text == '↓'), isTrue);
    });

    test('offers the palettes in the header, beside the name', () {
      // Six dots next to the wordmark: a palette is the whole page, so it is chosen where
      // the page begins rather than above the catalogue that explains it.
      final List<UINode> page = _flatten(buildSitePage(frame: _frame)).toList();
      final List<LinkNode> swatches = page
          .whereType<LinkNode>()
          .where((LinkNode link) => link.url.startsWith('?seed='))
          .toList();

      expect(swatches, hasLength(ExampleSeed.values.length));
      expect(
        _flatten(
          page.firstWhere(
            (UINode node) =>
                node is Box && node.semantics?.element == BoxElement.header,
          ),
        ).whereType<TextNode>().map((TextNode text) => text.text),
        contains('Unibox'),
      );

      final Box rose =
          swatches.firstWhere((LinkNode link) => link.url == '?seed=rose').child
              as Box;

      expect(rose.border?.width, 2, reason: 'the palette in force is ringed');
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
          'web/listings/?seed=rose',
          'web/takeover/?seed=rose',
        ]),
      );
    });

    test('draws the tree, then the two things it becomes', () {
      // One chip where the tree is, then a branch per target, each with the live rendering
      // it produces underneath it. The order is the diagram's, and a reader who reads the
      // chip, the arrow and the name has understood the library.
      final List<String> hero = <String>[
        for (final UINode node in _flatten(
          buildSitePage(frame: _frame).children.whereType<Box>().elementAt(1),
        ))
          if (node is TextNode) node.text,
      ];

      expect(hero, contains('Flutter UI. Searchable HTML.'));
      expect(hero, contains('Unibox'));
      expect(hero, contains('HTML and CSS'));
      expect(hero, contains('Flutter'));

      // The claim, then the tree, then the branches: the diagram answers the headline.
      expect(
        hero.indexOf('Flutter UI. Searchable HTML.'),
        lessThan(hero.indexOf('Unibox')),
      );
      expect(hero.indexOf('Unibox'), lessThan(hero.indexOf('HTML and CSS')));
      expect(hero.indexOf('HTML and CSS'), lessThan(hero.indexOf('Flutter')));
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
          'web/takeover/?seed=rose',
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
        'Tabs',
        'Secondary tabs',
        'Pages',
        'Dialog',
        'Type scale',
        'Colour roles',
        'Shapes',
      ]);
    });

    test(
      'draws the nodes the rest of the page never shows, and names them',
      () {
        // The hero frames a tree and the catalogue draws components; four nodes were never
        // drawn as themselves, so the band under the hero is where a reader meets them — and
        // the list beside the card is what names them, because a picture has no words.
        final List<UINode> page = _flatten(buildSitePage(frame: _frame))
            .toList();
        final Set<String> words = page
            .whereType<TextNode>()
            .map((TextNode text) => text.text)
            .toSet();

        expect(
          page.whereType<TextInputNode>().where(
            (TextInputNode input) => input.placeholder == 'Search the listings',
          ),
          hasLength(1),
        );
        expect(page.whereType<StackNode>(), isNotEmpty);
        expect(page.whereType<PositionedNode>(), isNotEmpty);
        expect(page.whereType<ImageNode>(), isNotEmpty);
        expect(
          words,
          containsAll(<String>[
            'ImageNode',
            'StackNode',
            'PositionedNode',
            'TextInputNode',
          ]),
        );
      },
    );

    test('gives the picture words, so a reader who cannot see it is told', () {
      final ImageNode picture = _flatten(buildVocabularySection())
          .whereType<ImageNode>()
          .single;

      expect(picture.src, endsWith('.jpg'));
      expect(picture.alt, isNotEmpty);
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

      expect(texts, contains('Flutter UI. Searchable HTML.'));
      // The claim is drawn as well as written: both renderings are on the page.
      expect(texts, contains('HTML and CSS'));
      expect(texts, contains('Flutter'));
      // Neither rendering is a call to action: the page has no way into the example.
      expect(texts, isNot(contains('Open the example')));
      expect(texts, isNot(contains('The Flutter build')));
    });

    test('shows each rendering rather than a picture of it, and names it once', () {
      final List<String> texts = <String>[
        for (final UINode node in _flatten(buildSitePage(frame: _emptyFrame)))
          if (node is TextNode) node.text,
      ];

      // The claim used to end in two stub cards captioned with the same two names, and
      // the band below it framed the real thing under those names again — the page told
      // a reader the point twice, once as a diagram and once for real. The frames are
      // the claim's answer, in the claim's band, so each name is written once.
      expect(
        texts.where((String text) => text == 'HTML and CSS'),
        hasLength(1),
      );
      expect(texts.where((String text) => text == 'Flutter'), hasLength(1));
      expect(texts, isNot(contains('Sunny flat, 62 m²')));
    });
  });
}
