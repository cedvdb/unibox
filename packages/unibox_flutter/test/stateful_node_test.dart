import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// A store with no package behind it, so the renderer is tested on its own.
final class _Store implements core.Store<int> {
  _Store() : _value = 0;

  int _value;
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

  bool get hasListeners => _listeners.isNotEmpty;

  void increment() {
    _value++;
    for (final void Function() listener in List<void Function()>.of(
      _listeners,
    )) {
      listener();
    }
  }
}

core.UINode _counterView(int state, _Store store) => core.Box(
  onTap: store.increment,
  children: <core.UINode>[core.TextNode('Count: $state')],
);

/// The store the node factory made last, so a test can look at its lifecycle.
_Store? _lastStore;

_Store _createdStore() => _lastStore = _Store();

final class _CounterNode extends core.StatefulNode<int, _Store> {
  _CounterNode() : super(create: _createdStore, view: _counterView);
}

/// A store whose first state is a pending request that finishes later.
final class _RequestStore implements core.Store<String> {
  final Completer<String> _answer = Completer<String>();
  final List<void Function()> _listeners = <void Function()>[];

  String _state = 'pending';

  @override
  String get state => _state;

  @override
  void addListener(void Function() listener) => _listeners.add(listener);

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  @override
  void onMount() {
    _answer.future.then((String value) {
      _state = value;
      for (final void Function() listener in List<void Function()>.of(
        _listeners,
      )) {
        listener();
      }
    });
  }

  @override
  void onUnmount() {}

  @override
  void dispose() {}

  void answer(String value) => _answer.complete(value);
}

core.UINode _requestView(String state, _RequestStore store) =>
    core.TextNode(state);

_RequestStore? _lastRequest;

_RequestStore _createdRequest() => _lastRequest = _RequestStore();

final class _RequestNode extends core.StatefulNode<String, _RequestStore> {
  _RequestNode() : super(create: _createdRequest, view: _requestView);
}

void main() {
  pressReplayTests();

  group('FlutterStateful', () {
    testWidgets('draws the view of the state the store starts with', (
      tester,
    ) async {
      await pumpNode(tester, _CounterNode());

      expect(find.text('Count: 0'), findsOneWidget);
    });

    testWidgets('rebuilds the view when the store publishes a state', (
      tester,
    ) async {
      await pumpNode(tester, _CounterNode());

      await tester.tap(find.text('Count: 0'));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('mounts the store once and disposes it on unmount', (
      tester,
    ) async {
      await pumpNode(tester, _CounterNode());
      final _Store store = _lastStore!;

      expect(store.mounts, 1);
      expect(store.hasListeners, isTrue);
      expect(store.unmounts, 0);

      await tester.pumpWidget(const SizedBox());

      expect(store.unmounts, 1);
      expect(store.disposed, isTrue);
      expect(store.hasListeners, isFalse);
    });

    testWidgets('keeps the state when an equal node rebuilds', (tester) async {
      await pumpNode(tester, _CounterNode());
      await tester.tap(find.text('Count: 0'));
      await tester.pump();

      await pumpNode(tester, _CounterNode());

      expect(find.text('Count: 1'), findsOneWidget);
      expect(_lastStore!.mounts, 1);
    });

    testWidgets('replaces the pending tree when the request answers', (
      tester,
    ) async {
      await pumpNode(tester, _RequestNode());

      expect(find.text('pending'), findsOneWidget);

      _lastRequest!.answer('ready');
      await tester.pump();
      await tester.pump();

      expect(find.text('ready'), findsOneWidget);
      expect(find.text('pending'), findsNothing);
    });
  });
}

void pressReplayTests() {
  testWidgets('answers a recorded press once, where the callback exists', (
    WidgetTester tester,
  ) async {
    // The store is created when the widget mounts, so the callback belongs to the view it draws
    // and not to a copy of the tree a host might have built.
    var pressed = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FlutterStateful(
          node: _PressNode(onTap: () => pressed++),
          presses: const <core.BoxPress>[core.BoxPress(key: 'cta')],
        ),
      ),
    );

    expect(pressed, 1);

    // A rebuild is not a second press.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FlutterStateful(
          node: _PressNode(onTap: () => pressed++),
          presses: const <core.BoxPress>[core.BoxPress(key: 'cta')],
        ),
      ),
    );

    expect(pressed, 1);
  });
}

/// A page whose view is one readable control.
final class _PressNode extends core.StatefulNode<int, _Store> {
  _PressNode({required void Function() onTap})
    : super(
        create: _Store.new,
        view: (int _, _) {
          return core.Box(
            key: 'cta',
            onTap: onTap,
            children: const <core.UINode>[core.TextNode('Press')],
          );
        },
      );
}
