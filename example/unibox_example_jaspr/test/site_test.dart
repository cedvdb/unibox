import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_jaspr/site/iframe_node.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// Pins the site the host publishes.
///
/// The page is a node tree, so `validateTree` is the first check it has to pass — the
/// site is built with the library it documents, and a page no renderer can honour
/// would be an embarrassing demonstration. The two frames are the one thing the tree
/// cannot describe, so the host's stand-in is what this file checks them through.
void main() {
  /// The page as the export draws it: with an `<iframe>` in each panel.
  UINode sitePage() => buildSitePage(
    frame: ({required String src, required String title}) =>
        IframeNode(src: src, title: title, resizable: true),
  );

  test('the site is one valid page that frames the example twice', () {
    final UINode page = sitePage();

    // The catalogue carries the palette picker, so the page names the example's
    // roles as well as Material's and is drawn with the theme that answers both.
    expect(
      validateTree(page, theme: ExamplePalette.themeFor(ExampleSeed.blue)),
      isEmpty,
    );

    final List<IframeNode> frames = _flatten(page)
        .whereType<IframeNode>()
        .toList();

    expect(frames, hasLength(2));
    // Each frame is a document of its own, so the palette travels in its address:
    // the page around it is drawn in the seed the catalogue picked.
    expect(frames.map((IframeNode node) => node.src), <String>[
      'web/listings/?seed=blue',
      'flutter/listings/?seed=blue',
    ], reason: 'the comparison shows the Jaspr page and the Flutter build');
    expect(frames.map((IframeNode node) => node.title), <String>[
      'Jaspr — HTML and CSS',
      'Flutter — the same tree',
    ]);
  });

  test('the catalogue is a band of the page, not a page of its own', () {
    final UINode page = sitePage();

    expect(_texts(page), contains('Material 3, as values and nodes'));
    expect(_texts(page), contains('Sphinx of black quartz'));
    expect(_texts(page), contains('Ada Lovelace'));
    expect(_texts(page), contains('Listings'));
    // An h1 belongs to the hero, so the catalogue cannot have one.
    expect(
      _flatten(page)
          .whereType<TextNode>()
          .where((TextNode node) => node.headingLevel == 1),
      hasLength(1),
    );
    // A dialog of its own, and nothing else that opens one.
    expect(_flatten(page).whereType<DialogDemo>(), hasLength(1));
  });

  test('the card leaves ink from the rows that look tappable', () {
    // A tile is an ink well, and a well only listens when it is given something to
    // do: a row with no callback draws a button that answers nothing, which is what
    // the card did before it passed one.
    final List<MaterialInkWell> wells = _flatten(buildMaterialSection())
        .whereType<MaterialInkWell>()
        .toList();

    MaterialInkWell rowWith(String text) {
      return wells.singleWhere((MaterialInkWell well) {
        final MaterialInkStore store = well.create();
        return _texts(well.view(store.state, store)).contains(text);
      });
    }

    for (final String text in <String>['Ada Lovelace', 'Charles Babbage']) {
      final MaterialInkWell well = rowWith(text);
      final MaterialInkStore store = well.create();

      expect(
        _flatten(well.view(store.state, store))
            .whereType<Box>()
            .where((Box box) => box.onTap != null),
        isNotEmpty,
        reason: 'the row under $text listens for a press',
      );
    }
  });

  test('the dialog demo opens a dialog of its own, and closes it', () {
    final DialogDemo demo = DialogDemo();
    final DialogDemoStore store = demo.create();

    final UINode closed = demo.viewFor(store.state, store);

    expect(_texts(closed), contains('Delete listing'));
    expect(_embeds(closed), isEmpty);

    store.open();

    final UINode open = demo.viewFor(store.state, store);

    expect(_texts(open), contains('Delete listing?'));
    expect(_texts(open), contains('The photos go with it.'));
    expect(
      _flatten(open).whereType<OverlayNode>(),
      hasLength(1),
      reason: 'the dialog is in the tree while the state says it is open',
    );

    store.close();

    expect(
      _flatten(demo.viewFor(store.state, store)).whereType<OverlayNode>(),
      isEmpty,
    );
  });
}

/// The children of [node], which for a `StatefulNode` are the tree it draws for the
/// state a fresh store starts in.
///
/// A component that owns state — the dialog demo, a `MaterialInkWell` — keeps its
/// tree in a view rather than in `children`, and the view is what a server renders.
/// Reading the page in a test means drawing the same tree.
Iterable<UINode> _children(UINode node) sync* {
  if (node is StatefulNode<Object, Store<Object>>) {
    final Store<Object> store = node.createStore();
    final UINode view = node.viewFor(store.state, store);
    store.dispose();
    yield view;
    return;
  }

  yield* node.children;
}

/// Every text under [node], which is how a page assertion reads.
Iterable<String> _texts(UINode node) sync* {
  if (node is TextNode) {
    yield node.text;
  }

  for (final UINode child in _children(node)) {
    yield* _texts(child);
  }
}

/// Every embed under [node]: the frames of the comparison.
Iterable<EmbedNode> _embeds(UINode node) sync* {
  if (node is EmbedNode) {
    yield node;
  }

  for (final UINode child in _children(node)) {
    yield* _embeds(child);
  }
}

/// Every node of [root], depth first, with the view of a `StatefulNode` in place of
/// the node itself.
Iterable<UINode> _flatten(UINode root) sync* {
  yield root;
  for (final UINode child in _children(root)) {
    yield* _flatten(child);
  }
}
