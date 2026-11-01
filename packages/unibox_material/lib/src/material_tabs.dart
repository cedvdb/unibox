import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';
import 'material_tab_bar.dart';

/// The state of [MaterialTabs]: which tab is chosen.
final class MaterialTabsState {
  /// Creates a state with [selected] chosen.
  const MaterialTabsState({required this.selected, required this.count});

  /// The index of the chosen tab.
  final int selected;

  /// How many tabs there are, so a press outside them is refused.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is MaterialTabsState &&
      other.selected == selected &&
      other.count == count;

  @override
  int get hashCode => Object.hash(selected, count);

  @override
  String toString() => 'MaterialTabsState(selected: $selected, count: $count)';
}

/// The store of [MaterialTabs]: one index, and the rule that a press outside the set does
/// nothing.
final class MaterialTabsStore extends StateStore<MaterialTabsState> {
  /// Creates a store with [selected] chosen out of [count] tabs.
  MaterialTabsStore({required int selected, required int count})
    : super(MaterialTabsState(selected: selected, count: count));

  /// Chooses [index], or ignores it when there is no such tab.
  ///
  /// Ignoring is the whole guard: a press that arrives a frame after the tree lost a tab
  /// would otherwise draw nothing, and a component that can draw nothing is a bug in the
  /// component rather than in the caller.
  void select(int index) {
    if (index < 0 || index >= state.count) {
      return;
    }

    state = MaterialTabsState(selected: index, count: state.count);
  }

  /// Takes the tabs of the node drawn now, and moves the choice into them.
  ///
  /// A set of tabs can change under a store that was created for another one, and the node
  /// is the only thing that knows: the store was handed a count when it was made, and a
  /// count is not a fact about a tree that has been replaced. A choice past the last tab
  /// would draw a page that is no longer there, and a tab the component gained would refuse
  /// a press, so the state is brought back into the set before the view is built.
  ///
  /// Equal state publishes nothing, which is what makes it safe to call on every drawing of
  /// the component rather than only on a change.
  void reconcile({required int count}) {
    final int last = count > 0 ? count - 1 : 0;
    final int selected = state.selected > last ? last : state.selected;

    state = MaterialTabsState(selected: selected, count: count);
  }
}

/// Material 3 tabs, as a node: a [MaterialTabBar] and the page of the chosen tab.
///
/// ```dart
/// MaterialTabs(
///   tabs: const <MaterialTab>[
///     MaterialTab(label: TextNode('Overview')),
///     MaterialTab(label: TextNode('Listings')),
///   ],
///   pages: <UINode>[overview, listings],
/// )
/// ```
///
/// It is a [StatefulNode], so the choice lives in a store and both renderers mount it the
/// same way: Flutter subscribes and rebuilds, and a page drawn without a client runtime
/// starts on the tab the tree starts with. What the component adds is the pairing — a bar
/// that reports a press and exactly one page drawn under it — because in the model those are
/// two nodes and nothing but a store can join them.
///
/// **A set of tabs the component is redrawn with is the set it draws.** A store is created
/// once per place in the tree, so it outlives the node that made it: a component drawn over
/// one tab after two moves its choice into the tabs that are there, and a component drawn
/// over three lets the third be chosen. Both are facts about the node, which is why the
/// component is a `StatefulNode` with an `update` rather than a store that guesses.
///
/// **What it is not.** It does not page: a swipe between tabs needs a pager, and this component
/// draws one page at a time with no `PagerNode` under it. A tab press therefore swaps the page
/// rather than moving a view to it, which is honest about what a document can do and leaves the
/// pager to `PagerNode`, which `TabsDemo` in the example composes with a bar.
final class MaterialTabs
    extends StatefulNode<MaterialTabsState, MaterialTabsStore> {
  /// Creates tabs over [pages], one per [MaterialTab].
  ///
  /// [pages] and [tabs] must be the same length: a bar with more tabs than pages would
  /// offer a destination that draws nothing, so that is a programming error and fails here
  /// rather than in a reader's browser.
  factory MaterialTabs({
    required List<MaterialTab> tabs,
    required List<UINode> pages,
    int initialIndex = 0,
    MaterialPalette? palette,
    MaterialTabVariant variant = MaterialTabVariant.primary,
    Object? key,
  }) {
    if (tabs.length != pages.length) {
      throw ArgumentError.value(
        pages.length,
        'pages',
        'MaterialTabs draws one page per tab: ${tabs.length} tabs, '
            '${pages.length} pages',
      );
    }

    return MaterialTabs._(
      key: key,
      create: () =>
          MaterialTabsStore(selected: initialIndex, count: tabs.length),
      // A tab that is added or taken away is a fact about the node, and the store cannot see
      // one: the count it was made with is the only thing it knows, so it is told here.
      update: (MaterialTabsState state, MaterialTabsStore store) =>
          store.reconcile(count: tabs.length),
      view: (MaterialTabsState state, MaterialTabsStore store) => Box(
        direction: Axis.vertical,
        width: double.infinity,
        children: <UINode>[
          MaterialTabBar(
            tabs: tabs,
            selected: state.selected,
            variant: variant,
            palette: palette,
            onSelect: store.select,
          ),
          pages[state.selected],
        ],
      ),
    );
  }

  MaterialTabs._({
    required super.create,
    required super.view,
    super.update,
    super.key,
  });
}
