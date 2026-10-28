import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_jaspr/site/iframe_node.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// Pins the page trees the site is made of.
///
/// They are node trees, so `validateTree` is the first check a page has to pass —
/// the site is built with the library it documents, and a page that no renderer can
/// honour would be an embarrassing demonstration.
void main() {
  test('the front page says what the library is and offers both ways in', () {
    final UINode landing = buildLanding();

    expect(validateTree(landing, theme: MaterialPalette.lightTheme), isEmpty);
    expect(_texts(landing), contains('Describe a screen once.'));
    expect(_links(landing), containsAll(<String>['material/', 'showcase/']));
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

/// Every text under [node], which is how a page assertion reads.
Iterable<String> _texts(UINode node) sync* {
  if (node is TextNode) {
    yield node.text;
  }

  for (final UINode child in node.children) {
    yield* _texts(child);
  }
}

/// Every link destination under [node].
Iterable<String> _links(UINode node) sync* {
  if (node is LinkNode) {
    yield node.url;
  }

  for (final UINode child in node.children) {
    yield* _links(child);
  }
}

/// Every embed under [node]: the frames of the showcase.
Iterable<EmbedNode> _embeds(UINode node) sync* {
  if (node is EmbedNode) {
    yield node;
  }

  for (final UINode child in node.children) {
    yield* _embeds(child);
  }
}

/// Every node of [root], depth first.
Iterable<UINode> _flatten(UINode root) sync* {
  yield root;
  for (final UINode child in root.children) {
    yield* _flatten(child);
  }
}
