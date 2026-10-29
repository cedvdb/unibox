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
List<Box> _tabBoxes(MaterialTabBar bar) =>
    ((bar.children.single as StackNode).children.first as Box).children
        .cast<Box>()
        .toList();

/// The well of [tab], which is the tab.
MaterialInkWell _wellOf(Box tab) => tab.children.single as MaterialInkWell;

/// The one indicator of [bar], laid over the row's bottom edge.
PositionedNode _indicatorOf(MaterialTabBar bar) =>
    (bar.children.single as StackNode).children.last as PositionedNode;

void main() {
  /// The underline [tab] carries, or `null` when it carries none.
  ///
  /// It is the positioned child pinned to both edges of the stack the label sizes; an ink
  /// drop is positioned too, but by an offset from one corner rather than across two.
  PositionedNode? pinnedLineOf(Box tab) {
    final MaterialInkWell well = _wellOf(tab);
    final Store<MaterialInkState> store = well.createStore();
    final List<PositionedNode> lines = _nodes(well.viewFor(store.state, store))
        .whereType<PositionedNode>()
        .where((PositionedNode node) => node.left == 0 && node.right == 0)
        .toList();
    store.dispose();

    return lines.isEmpty ? null : lines.single;
  }

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

    test('draws every tab, and one indicator a share wide, moved to the chosen one', () {
      final MaterialTabBar tabs = bar(selected: 1);

      expect(_texts(tabs), <String>['Overview', 'Listings', 'Reviews']);

      // One element for the whole bar rather than one per tab: a share of the width, moved by a
      // multiple of *its own* width, which is a whole tab per step and needs nobody to measure one.
      final Box indicator = _indicatorOf(tabs).child as Box;

      expect(indicator.widthFraction, closeTo(1 / 3, 1e-9));
      expect(indicator.transform?.fractionX, 1);
      expect(indicator.height, MaterialTabBar.indicatorHeight);
      expect(indicator.backgroundColor, isNotNull);
      expect(
        indicator.transition?.parts.single.properties,
        <BoxProperty>{BoxProperty.transform},
        reason:
            'the transform is what slides, and a transition is what eases it',
      );
    });

    test('reports which tab was pressed', () {
      // The well holds the callback, and the bar is what knows the index: a press on the
      // third tab arrives as `2`.
      final List<int> presses = <int>[];
      final MaterialTabBar tabs = bar(presses: presses);
      final Box third = _tabBoxes(tabs)[2];
      final MaterialInkWell well = _wellOf(third);
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
        final MaterialInkWell well = _wellOf(tab);
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

    test('underlines a secondary tab, and lays it across its label', () {
      final MaterialTabBar tabs = bar(
        selected: 1,
        variant: MaterialTabVariant.secondary,
      );

      // A share of the bar cannot land under a tab whose width is its label's, so a
      // secondary bar has no overlay at all: each tab carries its own underline.
      expect((tabs.children.single as StackNode).children.length, 1);

      for (final (int index, Box tab) in _tabBoxes(tabs).indexed) {
        final PositionedNode line = pinnedLineOf(tab)!;

        // Pinned to both edges and to the bottom of the stack its own label sizes: the
        // width is whatever the label came out as, which nobody had to measure.
        expect(line.left, 0);
        expect(line.right, 0);
        expect(line.bottom, 0);
        expect(line.alignment, isNull);

        final Box painted = line.child as Box;

        expect(painted.height, MaterialTabBar.indicatorHeight);
        expect(painted.backgroundColor, isNotNull);
        // Only the chosen tab's underline is drawn, and the other two fade out where they
        // are rather than leaving nothing to fade in.
        expect(
          painted.opacity,
          index == 1 ? 1 : 0,
          reason: 'the chosen tab is the underlined one',
        );
        expect(
          painted.transition?.parts.single.properties,
          <BoxProperty>{BoxProperty.opacity},
          reason:
              'a label width apart is a measurement, so the underline fades',
        );
      }
    });

    test('gives a primary tab no underline of its own', () {
      for (final Box tab in _tabBoxes(bar())) {
        expect(
          pinnedLineOf(tab),
          isNull,
          reason: 'a primary tab is a share of the bar, and the bar moves one indicator',
        );
      }

      // And the bar keeps the one indicator it moves instead.
      expect(_indicatorOf(bar()).alignment, BoxAlignment.bottomCenter);
    });
  });
}
