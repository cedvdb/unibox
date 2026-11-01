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

    test('moves the choice into the tabs it is redrawn with', () {
      // A store created over two tabs, and a node that draws one. The choice is past the last
      // tab, which is a page the tree no longer holds: left alone it indexed nothing.
      final MaterialTabsStore store = tabs(initialIndex: 1).create();
      final MaterialTabs single = MaterialTabs(
        tabs: const <MaterialTab>[MaterialTab(label: TextNode('Overview'))],
        pages: const <UINode>[TextNode('The overview')],
      );

      single.updateFor(store.state, store);

      expect(store.state.selected, 0);
      expect(store.state.count, 1);
      expect(
        _texts(single.viewFor(store.state, store)),
        contains('The overview'),
      );

      store.dispose();
    });

    test('lets a tab the component gained be chosen', () {
      // The other half: a bar that draws three tabs whose store believes there are two
      // refuses the press on the third, which reads as a control that does nothing.
      final MaterialTabsStore store = tabs().create();
      final MaterialTabs three = MaterialTabs(
        tabs: const <MaterialTab>[
          MaterialTab(label: TextNode('Overview')),
          MaterialTab(label: TextNode('Listings')),
          MaterialTab(label: TextNode('Details')),
        ],
        pages: const <UINode>[
          TextNode('The overview'),
          TextNode('The listings'),
          TextNode('The details'),
        ],
      );

      three.updateFor(store.state, store);
      store.select(2);

      expect(store.state.selected, 2);
      expect(
        _texts(three.viewFor(store.state, store)),
        contains('The details'),
      );

      store.dispose();
    });
  });
}
