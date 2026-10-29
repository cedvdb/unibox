import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// Every node of [root], depth first, with a stateful node's first frame drawn.
///
/// The tab labels live inside their ink wells, and a `StatefulNode` has no children until a
/// renderer mounts it — so a plain walk of the tree stops at the well and sees nothing.
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

/// The boxes a bar lays out, one per tab.
List<Box> _tabBoxes(MaterialTabBar bar) => bar.children.cast<Box>().toList();

void main() {
  group('MaterialTabBar', () {
    MaterialTabBar bar({
      int selected = 0,
      List<int>? presses,
      MaterialTabVariant variant = MaterialTabVariant.primary,
    }) {
      return MaterialTabBar(
        tabs: const <MaterialTab>[
          MaterialTab(label: TextNode('Overview')),
          MaterialTab(label: TextNode('Listings')),
          MaterialTab(label: TextNode('Reviews')),
        ],
        selected: selected,
        variant: variant,
        onSelect: presses?.add,
      );
    }

    test('draws every tab, and the indicator under the chosen one only', () {
      final MaterialTabBar tabs = bar(selected: 1);

      expect(_texts(tabs), <String>['Overview', 'Listings', 'Reviews']);

      // The indicator is the last box of a tab, and an unchosen tab draws it without a
      // colour — which is how it draws nothing, with no rule hiding a layer.
      final List<Box> indicators = <Box>[
        for (final Box tab in _tabBoxes(tabs)) tab.children.last as Box,
      ];

      expect(indicators, hasLength(3));
      expect(indicators.map((Box box) => box.backgroundColor), <BoxColor?>[
        null,
        const BoxColor(0xFF8C4A5D),
        null,
      ]);
      expect(
        indicators.every(
          (Box box) => box.height == MaterialTabBar.indicatorHeight,
        ),
        isTrue,
      );
    });

    test('reports which tab was pressed', () {
      // The well holds the callback, and the bar is what knows the index: a press on the
      // third tab arrives as `2`.
      final List<int> presses = <int>[];
      final MaterialTabBar tabs = bar(presses: presses);
      final Box third = _tabBoxes(tabs)[2];
      final MaterialInkWell well = third.children.first as MaterialInkWell;
      final Store<MaterialInkState> store = well.createStore();
      final Box painted = _nodes(well.viewFor(store.state, store))
          .whereType<Box>()
          .first;

      expect(painted.onTap, isNotNull);
      painted.onTap!();
      expect(presses, <int>[2]);

      store.dispose();
    });

    test('distributes a primary bar and packs a secondary one', () {
      final List<Box> secondary = _tabBoxes(
        bar(variant: MaterialTabVariant.secondary),
      );

      expect(
        _tabBoxes(bar()).every((Box tab) => tab.flex == 1),
        isTrue,
        reason: 'a primary tab shares the width',
      );
      expect(
        secondary.every((Box tab) => tab.flex == null),
        isTrue,
        reason: 'a secondary tab is as wide as its label',
      );
    });

    test('is a tab of a tablist for a screen reader, one of them chosen', () {
      // A tab is not a button: a reader is told which of a set is chosen, which a button cannot say.
      final MaterialTabBar tabs = bar(selected: 1);

      expect(tabs.semantics?.role, BoxRole.tablist);
      final List<bool?> selected = <bool?>[];

      for (final Box tab in _tabBoxes(tabs)) {
        final MaterialInkWell well = tab.children.first as MaterialInkWell;
        final Store<MaterialInkState> store = well.createStore();
        for (final Box box in _nodes(
          well.viewFor(store.state, store),
        ).whereType<Box>()) {
          if (box.semantics?.selected != null) {
            expect(box.semantics!.role, BoxRole.tab);
            selected.add(box.semantics!.selected);
          }
        }
        store.dispose();
      }

      expect(selected, <bool?>[false, true, false]);
    });
  });
}
