import 'package:unibox_core/unibox_core.dart' as core;

import 'behaviour.dart';

/// The store of the counter the table draws: one number, and the two ways to move it.
final class _CountStore extends core.StateStore<int> {
  _CountStore() : super(0);

  /// Adds one to the count.
  void raise() => state = state + 1;

  /// Puts the count back to nought.
  void reset() => state = 0;
}

core.UINode _countView(int state, _CountStore store) => core.Box(
  direction: core.Axis.vertical,
  children: <core.UINode>[
    core.Box(
      key: 'raise',
      onTap: store.raise,
      children: <core.UINode>[core.TextNode('Add')],
    ),
    core.TextNode('$state', key: 'count'),
    core.Box(
      key: 'reset',
      onTap: store.reset,
      children: const <core.UINode>[core.TextNode('Reset')],
    ),
  ],
);

/// A component of the table's own: a count, and the presses that move it.
final class _Counter extends core.StatefulNode<int, _CountStore> {
  _Counter() : super(create: _CountStore.new, view: _countView);
}

/// A store that copied a parameter from the node that created it.
///
/// It is the shape a component takes when it has to know a number the tree states — how many
/// tabs there are, how much room a bar has — and the store is created before the node it is
/// drawn by: the number is read once, and a node drawn again is the only thing that can say it
/// changed.
final class _CeilingStore extends core.StateStore<int> {
  _CeilingStore() : super(0);

  /// The number this store counts to.
  int ceiling = 3;

  /// Adds one to the count, up to the ceiling the store believes in.
  void raise() {
    if (state < ceiling) {
      state = state + 1;
    }
  }

  /// Takes the ceiling of the node drawn now, and lowers a count that is above it.
  void setCeiling(int next) {
    ceiling = next;

    if (state > ceiling) {
      state = ceiling;
    }
  }
}

core.UINode _ceilingView(int state, _CeilingStore store) => core.Box(
  key: 'raise',
  onTap: store.raise,
  children: <core.UINode>[
    core.TextNode('$state of ${store.ceiling}', key: 'count'),
  ],
);

/// The component with a parameter its store copied, and the hook that repairs it.
final class _Ceiling extends core.StatefulNode<int, _CeilingStore> {
  _Ceiling(int ceiling)
    : super(
        create: _CeilingStore.new,
        view: _ceilingView,
        update: (int state, _CeilingStore store) => store.setCeiling(ceiling),
      );
}

/// The behaviour every renderer is checked against.
///
/// One case per fact a state has to reach the page: a press publishes and the page is the tree
/// of the new state, and a component drawn again is reconciled with the parameters of the node
/// that drew it. Both are things the appearance tables cannot see, because they describe one
/// drawing of a tree and a step changes it.
///
/// The table is not `const`, unlike the appearance ones: a `StatefulNode` carries the closures
/// that make it a component, and a closure is not a constant.
final List<BehaviourCase> behaviourCases = <BehaviourCase>[
  BehaviourCase(
    description: 'draws the tree of the state a press published',
    tree: _Counter(),
    steps: <BehaviourStep>[
      BehaviourStep.press('raise', <Object, String>{'count': '1'}),
      BehaviourStep.press('raise', <Object, String>{'count': '2'}),
      BehaviourStep.press('reset', <Object, String>{'count': '0'}),
    ],
  ),
  BehaviourCase(
    description: 'reconciles a store with the node drawn in its place',
    tree: _Ceiling(3),
    steps: <BehaviourStep>[
      BehaviourStep.press('raise', <Object, String>{'count': '1 of 3'}),
      BehaviourStep.press('raise', <Object, String>{'count': '2 of 3'}),
      // The same slot, a component whose parameter changed: the store keeps its count of two,
      // so a page that shows one is a store that was told about the ceiling it draws under.
      BehaviourStep.redraw(_Ceiling(1), <Object, String>{'count': '1 of 1'}),
    ],
  ),
];
