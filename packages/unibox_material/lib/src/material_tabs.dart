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
/// **What it is not.** It does not page: a swipe between tabs needs a controlled scroll
/// position, which the model does not state yet (`Box.onScroll` reports an offset; nothing
/// sets one). A tab press therefore swaps the page rather than sliding to it, which is honest
/// about what a document can do and leaves the pager in [`Box.snap`].
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

  MaterialTabs._({required super.create, required super.view, super.key});
}
