import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// A store written by hand, with no package behind it.
final class _Counter implements Store<int> {
  _Counter([this._value = 0]);

  final int _value;
  final List<void Function()> _listeners = <void Function()>[];

  int mounts = 0;
  int unmounts = 0;
  bool disposed = false;

  @override
  int get state => _value;

  @override
  void addListener(void Function() listener) => _listeners.add(listener);

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  @override
  void onMount() => mounts++;

  @override
  void onUnmount() => unmounts++;

  @override
  void dispose() {
    disposed = true;
    _listeners.clear();
  }
}

UINode _counterView(int state, _Counter store) => TextNode('$state');

/// The spelling an application uses: a node of its own over a store of its own.
final class _CounterNode extends StatefulNode<int, _Counter> {
  _CounterNode() : super(create: _Counter.new, view: _counterView);
}

/// A store that copies a parameter, which is the fact `update` exists for: the ceiling it
/// counts to is a number it read when it was created, and a store cannot look at a node.
final class _CeilingStore extends StateStore<int> {
  _CeilingStore() : super(0);

  /// The number this store counts to.
  int ceiling = 3;

  /// Raises the count, up to the ceiling the store believes in.
  void raise() {
    if (state < ceiling) {
      state = state + 1;
    }
  }

  /// Takes the ceiling of the node drawn now, and lowers a count that is above it.
  void setCeiling(int next) {
    ceiling = next < 0 ? 0 : next;

    if (state > ceiling) {
      state = ceiling;
    }
  }
}

UINode _ceilingView(int state, _CeilingStore store) =>
    TextNode('$state of ${store.ceiling}');

/// A component with a parameter its store copied, and the hook that repairs it.
///
/// The parameter lives in the closure rather than in a field: a constructor initialiser
/// list cannot reach `this`, and a node that reconciles only needs the value at the
/// moment it is called.
final class _CeilingNode extends StatefulNode<int, _CeilingStore> {
  _CeilingNode(int ceiling)
    : super(
        create: _CeilingStore.new,
        view: _ceilingView,
        update: (int state, _CeilingStore store) => store.setCeiling(ceiling),
      );
}

void main() {
  group('StatefulNode', () {
    test('creates the store when the renderer asks for it', () {
      final node = _CounterNode();

      final Store<int> first = node.createStore();
      final Store<int> second = node.createStore();

      expect(first, isA<_Counter>());
      expect(first.state, 0);
      expect(identical(first, second), isFalse);
    });

    test('draws the view of the state it is given', () {
      final node = _CounterNode();
      final _Counter store = node.createStore() as _Counter;

      final UINode view = node.viewFor(3, store);

      expect(view, isA<TextNode>());
      expect((view as TextNode).text, '3');
    });

    test('hands the typed store to the view', () {
      final node = _CounterNode();
      final Store<int> store = node.createStore();
      Object? seen;

      node.viewFor(1, store);

      // The view is written against _Counter, not against Store, so a missing
      // cast would fail here rather than in a renderer.
      expect(() => seen = store, returnsNormally);
      expect(seen, isA<_Counter>());
    });

    test('has no children of its own, because the view builds them', () {
      expect(_CounterNode().children, isEmpty);
    });

    test('validates like any other node', () {
      final tree = Box(children: <UINode>[_CounterNode()]);

      expect(validateTree(tree), isEmpty);
    });

    test('is reachable through the erased type a renderer uses', () {
      final StatefulNode<Object, Store<Object>> node = _CounterNode();

      expect(node.createStore().state, 0);
      expect(node.viewFor(2, node.createStore()), isA<TextNode>());
    });

    test('keeps the key of the node it is given', () {
      final node = StatefulNode<int, _Counter>(
        key: 'counter',
        create: _Counter.new,
        view: _counterView,
      );

      expect(node.key, 'counter');
    });

    test(
      'reconciles a store with the parameters of the node that replaced it',
      () {
        // Two drawings of one component in one place: the store survives the second, so
        // what it copied from the first is the only thing that can go stale.
        final _CeilingStore store =
            _CeilingNode(3).createStore() as _CeilingStore;
        store
          ..raise()
          ..raise();

        expect(store.state, 2);

        final _CeilingNode one = _CeilingNode(1);
        one.updateFor(store.state, store);

        expect(store.state, 1, reason: 'the count is above the new ceiling');
        expect(store.ceiling, 1);
        expect((one.viewFor(store.state, store) as TextNode).text, '1 of 1');
      },
    );

    test(
      'publishes nothing when the parameters it reconciles did not change',
      () {
        final _CeilingStore store =
            _CeilingNode(3).createStore() as _CeilingStore;
        int notifications = 0;
        store.addListener(() => notifications++);

        _CeilingNode(3).updateFor(store.state, store);

        expect(
          notifications,
          0,
          reason: 'a renderer cannot tell, so it calls it anyway',
        );
      },
    );

    test('does nothing for a node that states no update', () {
      final _CounterNode node = _CounterNode();
      final _Counter store = node.createStore() as _Counter;

      expect(() => node.updateFor(store.state, store), returnsNormally);
      expect(store.state, 0);
    });
  });
}
