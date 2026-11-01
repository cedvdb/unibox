import 'package:unibox_core/unibox_core.dart' as core;

/// What a reader does to a page, and the text the page has to show afterwards.
///
/// Appearance is a fact about one drawing; a state is the other half of the contract, because
/// what a store publishes is a tree only a renderer can see. A step therefore names an
/// *intent* — a press, or the component drawn again with other parameters — and the text that
/// has to be on the page once it has been answered, by key.
///
/// One constructor fills [key] and the other fills [node], so exactly one of them is set.
final class BehaviourStep {
  /// A step that presses the node carrying [key], and expects [expected] afterwards.
  const BehaviourStep.press(Object this.key, this.expected) : node = null;

  /// A step that draws [node] where the component was, and expects [expected] afterwards.
  ///
  /// The node is what a parent's view returns the next time it is planned: the same type and
  /// key, so the same store, with the parameters that changed.
  const BehaviourStep.redraw(core.UINode this.node, this.expected) : key = null;

  /// The key of the node to press, or `null` when the step draws the component again.
  final Object? key;

  /// The node that replaces the component, or `null` when the step presses one.
  final core.UINode? node;

  /// The text that has to be at each key once the step has been answered.
  final Map<Object, String> expected;

  /// What the step does, for a difference that has to say where it happened.
  String get description =>
      key == null ? 'redrawing the component' : 'pressing "$key"';
}

/// A component, the steps a reader takes against it, and the text each one produces.
///
/// A case is one `StatefulNode` at the root: the run creates its store, so every step is a
/// publish and the tree after it is the tree a renderer would draw.
final class BehaviourCase {
  /// Creates a case named [description] over [tree], which [steps] are played against.
  const BehaviourCase({
    required this.description,
    required this.tree,
    required this.steps,
  });

  /// What the case describes, phrased as the test that checks it.
  final String description;

  /// The component as it is drawn first.
  final core.UINode tree;

  /// The steps, in the order a reader takes them.
  final List<BehaviourStep> steps;

  @override
  String toString() => 'BehaviourCase($description)';
}

/// Every way [behaviourCase] disagrees with what a renderer did with it.
///
/// The renderer supplies its own three moves, so the same case is checked against a widget tree
/// and against a page: [draw] puts a tree where the component is, [press] presses the node a key
/// names, and [textAt] reads the text at a key, or `null` when there is none.
///
/// It returns differences rather than failing, so the suite that runs it decides what a
/// disagreement means — the same shape as the appearance tables it sits beside.
Future<List<String>> behaviourDifferences(
  BehaviourCase behaviourCase, {
  required Future<void> Function(core.UINode tree) draw,
  required Future<void> Function(Object key) press,
  required String? Function(Object key) textAt,
}) async {
  final List<String> differences = <String>[];

  await draw(behaviourCase.tree);

  for (final BehaviourStep step in behaviourCase.steps) {
    if (step.key case final Object key) {
      await press(key);
    } else if (step.node case final core.UINode node) {
      await draw(node);
    }

    step.expected.forEach((Object key, String expected) {
      final String? actual = textAt(key);

      if (actual != expected) {
        differences.add(
          '${behaviourCase.description}: ${step.description} — $key says '
          '${actual == null ? 'nothing' : '"$actual"'}, expected "$expected"',
        );
      }
    });
  }

  return differences;
}

/// [behaviourCase] played against a store of its own, with no renderer at all.
///
/// A store is pure Dart, so the tree after a press is the tree a renderer would draw, and a
/// component's behaviour is checkable in a plain `dart test`. This is the reference the two
/// renderer suites are held beside: what it returns is what the table asks for.
Future<List<String>> playBehaviour(BehaviourCase behaviourCase) {
  final BehaviourRun run = BehaviourRun(behaviourCase);

  return behaviourDifferences(
    behaviourCase,
    draw: (core.UINode tree) async => run.draw(tree),
    press: (Object key) async => run.press(key),
    textAt: run.textAt,
  );
}

/// One component mounted headlessly: a store, the tree of its state, and the moves a renderer
/// makes on it.
///
/// It is the smallest honest renderer — create a store where the node is first drawn, hand it
/// to [core.StatefulNode.updateFor] when another node is drawn there, and read the view — which
/// is what makes a page testable without a browser or a widget tree.
final class BehaviourRun {
  /// Mounts the component of [behaviourCase].
  BehaviourRun(this.behaviourCase);

  /// The case being played.
  final BehaviourCase behaviourCase;

  core.StatefulNode<Object, core.Store<Object>>? _node;
  core.Store<Object>? _store;

  /// The tree of the state the store holds now.
  core.UINode get tree => _node!.viewFor(_store!.state, _store!);

  /// Draws [tree] where the component is, the way a renderer does.
  ///
  /// The first tree creates the store; every one after it is the same place in the tree, so
  /// the store is kept and reconciled with the parameters of the node drawn now.
  void draw(core.UINode tree) {
    if (tree
        case final core.StatefulNode<Object, core.Store<Object>> stateful) {
      if (_store case final core.Store<Object> store) {
        _node = stateful;
        stateful.updateFor(store.state, store);

        return;
      }

      _node = stateful;
      _store = stateful.createStore()..onMount();

      return;
    }

    throw ArgumentError.value(
      tree,
      'tree',
      'A behaviour case is a StatefulNode: there is no store to play the steps against',
    );
  }

  /// Presses the box [key] names, as the tree draws it now.
  void press(Object key) {
    final core.TapCallback? onTap = switch (_find(key)) {
      final core.Box box when box.enabled => box.onTap,
      _ => null,
    };

    if (onTap == null) {
      throw StateError(
        'No pressable box carries the key $key in "${behaviourCase.description}".',
      );
    }

    onTap();
  }

  /// The text of the node [key] names, or `null` when the tree holds none.
  String? textAt(Object key) {
    final core.UINode? node = _find(key);

    return node is core.TextNode ? node.text : null;
  }

  /// Releases the store, the way a renderer handing the node over does.
  void dispose() {
    _store?.dispose();
    _store = null;
    _node = null;
  }

  /// The node [key] names, drawn from [tree] down, or `null` when there is none.
  ///
  /// A `StatefulNode` inside the view has no children until a renderer mounts it, so a case
  /// describes one component and what it draws, and never the stores of its children.
  core.UINode? _find(Object key) {
    core.UINode? walk(core.UINode node) {
      if (node.key == key) {
        return node;
      }

      for (final core.UINode child in node.children) {
        if (walk(child) case final core.UINode found) {
          return found;
        }
      }

      return null;
    }

    return walk(tree);
  }
}
