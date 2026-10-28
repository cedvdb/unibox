import 'dart:convert';

import 'package:jaspr/server.dart';
import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_jaspr/site/iframe_node.dart';
import 'package:unibox_example_jaspr/site/site_document.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// Pins the page trees the site is made of.
///
/// They are node trees, so `validateTree` is the first check a page has to pass —
/// the site is built with the library it documents, and a page that no renderer can
/// honour would be an embarrassing demonstration.
void main() {
  setUpAll(Jaspr.initializeApp);

  test('the front page states one claim and points at the comparison', () {
    final UINode landing = buildLanding();

    expect(validateTree(landing, theme: MaterialPalette.lightTheme), isEmpty);
    expect(_texts(landing), contains('Describe a screen once.'));
    expect(_texts(landing), contains('Compare both renderings'));
    // The bar carries the catalogue and the comparison. The page itself offers the
    // one place where its claim can be checked — the showcase — and otherwise asks
    // for nothing.
    expect(_links(landing), <String>['showcase/']);
  });

  test('a page names the build it was rendered from', () async {
    // A tab opened before a deploy draws the same markup as the deployed page, so a
    // layout the new build has fixed still looks broken in it. The stamp is the fact
    // that separates the two, and it costs a reader one request to read.
    expect(
      await _render(
        buildSiteDocument(page: SitePage.material, build: 'abc1234'),
      ),
      contains('name="unibox-build" content="abc1234"'),
    );
    // A build that cannot name itself writes no stamp rather than an empty one.
    expect(
      await _render(buildSiteDocument(page: SitePage.material)),
      isNot(contains('unibox-build')),
    );
  });

  test('the gallery is a valid tree that shows the Material package', () {
    final UINode gallery = buildMaterialGallery();

    expect(validateTree(gallery, theme: MaterialPalette.lightTheme), isEmpty);
    expect(_texts(gallery), contains('Material 3'));
    expect(_texts(gallery), contains('Sphinx of black quartz'));
    expect(_texts(gallery), contains('Ada Lovelace'));
    // A simple dialog of its own, not the app's sign-up form, and no link to the
    // comparison: the gallery is the Material page, the showcase has its own.
    expect(
      _flatten(gallery).whereType<DialogDemo>(),
      hasLength(1),
      reason: 'the page opens a dialog of its own',
    );
    expect(_texts(gallery), isNot(contains('Open the sign-up dialog')));
    expect(_texts(gallery), isNot(contains('Compare both renderings')));
  });

  test('the card leaves ink from the rows that look tappable', () {
    // A tile is an ink well, and a well only listens when it is given something to
    // do: a row with no callback draws a button that answers nothing, which is what
    // the card did before it passed one.
    final List<MaterialInkWell> wells = _flatten(buildMaterialGallery())
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

  test('the showcase puts the two renderings side by side', () {
    final UINode showcase = buildShowcase(
      frame: ({required String src, required String title}) =>
          IframeNode(src: src, title: title),
    );

    expect(validateTree(showcase, theme: MaterialPalette.lightTheme), isEmpty);
    expect(_embeds(showcase), hasLength(2));
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

/// Every link destination under [node].
Iterable<String> _links(UINode node) sync* {
  if (node is LinkNode) {
    yield node.url;
  }

  for (final UINode child in _children(node)) {
    yield* _links(child);
  }
}

/// Every embed under [node]: the frames of the showcase.
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

/// [document] as the bytes a browser receives.
Future<String> _render(Document document) async =>
    utf8.decode((await renderComponent(document)).body);
