import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// Every node of [root], depth first, with a stateful node's first frame drawn.
Iterable<UINode> _nodes(UINode root) sync* {
  yield root;

  if (root is StatefulNode<Object, Store<Object>>) {
    final Store<Object> store = root.createStore();
    yield* _nodes(root.viewFor(store.state, store));
    store.dispose();
  }

  for (final UINode child in root.children) {
    yield* _nodes(child);
  }
}

List<String> _texts(UINode root) =>
    _nodes(root)
        .whereType<TextNode>()
        .map((TextNode text) => text.text)
        .toList();

void main() {
  MaterialTabs tabs({int initialIndex = 0}) => MaterialTabs(
    initialIndex: initialIndex,
    tabs: const <MaterialTab>[
      MaterialTab(label: TextNode('Overview')),
      MaterialTab(label: TextNode('Listings')),
    ],
    pages: const <UINode>[TextNode('The overview'), TextNode('The listings')],
  );

  group('MaterialTabs', () {
    test('draws the bar, then the page of the chosen tab', () {
      expect(_texts(tabs()), containsAll(<String>['Overview', 'The overview']));
      expect(_texts(tabs()), isNot(contains('The listings')));

      expect(
        _texts(tabs(initialIndex: 1)),
        containsAll(<String>['Listings', 'The listings']),
      );
      expect(_texts(tabs(initialIndex: 1)), isNot(contains('The overview')));
    });

    test('swaps the page when a tab is pressed', () {
      // The whole component: one store, and a view that reads the index out of it — so a
      // publish is a different page, on whichever target mounted the node.
      final MaterialTabs node = tabs();
      final MaterialTabsStore store = node.create();

      expect(store.state.selected, 0);
      store.select(1);

      final List<String> drawn = _texts(node.viewFor(store.state, store));
      expect(drawn, contains('The listings'));
      expect(drawn, isNot(contains('The overview')));

      store.dispose();
    });

    test('ignores a press outside the set', () {
      // A press that lands after the tree lost a tab must not leave the component drawing
      // nothing: the guard lives in the store, so every renderer gets it.
      final MaterialTabsStore store = tabs().create();

      store.select(7);
      store.select(-1);
      expect(store.state.selected, 0);

      store.dispose();
    });

    test('refuses more tabs than pages', () {
      expect(
        () => MaterialTabs(
          tabs: const <MaterialTab>[
            MaterialTab(label: TextNode('One')),
            MaterialTab(label: TextNode('Two')),
          ],
          pages: const <UINode>[TextNode('Only one')],
        ),
        throwsArgumentError,
      );
    });
  });
}
