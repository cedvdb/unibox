import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// A frame that draws nothing: the page is readable without a host.
UINode _frame({required String src, required String title}) =>
    Box(key: src, children: <UINode>[TextNode(title)]);

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
      expect(validateTree(page, theme: MaterialPalette.lightTheme), isEmpty);
    });

    test('frames the same screen in both renderings', () {
      final UINode page = buildSitePage(frame: _frame);
      final List<Object?> frames = <Object?>[
        for (final UINode node in _flatten(page))
          if (node.key != null) node.key,
      ];

      // The stub frame keys itself with its source, so the page names the two
      // documents the comparison shows: the Jaspr rendering and the Flutter build.
      expect(
        frames,
        containsAll(<Object?>['web/listings/', 'flutter/listings/']),
      );
    });

    test('offers the example and the source', () {
      final UINode page = buildSitePage(frame: _frame);
      final List<String> links = <String>[
        for (final UINode node in _flatten(page))
          if (node is LinkNode) node.url,
      ];

      expect(
        links,
        containsAll(<String>[
          'web/listings/',
          'flutter/listings/',
          repositoryUrl,
          '$repositoryUrl#readme',
        ]),
      );
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
      expect(texts, contains('Open the example'));
      expect(texts, contains('The Flutter build'));
      // The claim is drawn as well as written: one tree, two renderings of a card.
      expect(texts, contains('Jaspr — HTML and CSS'));
      expect(texts, contains('Flutter — the same tree'));
    });
  });
}
