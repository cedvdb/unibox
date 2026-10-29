@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

/// A page a reader can act on: a count, a press that raises it, and a field beside them.
final class CounterStore extends core.StateStore<int> {
  CounterStore() : super(0) {
    last = this;
  }

  /// The store the view created, so a test can read the lifecycle of the instance the page holds
  /// rather than of one it made itself.
  static CounterStore? last;

  int mounts = 0;
  int unmounts = 0;

  void increment() => state = state + 1;

  @override
  void onMount() => mounts++;

  @override
  void onUnmount() => unmounts++;
}

final class Counter extends core.StatefulNode<int, CounterStore> {
  Counter({super.key})
    : super(
        create: CounterStore.new,
        view: (int count, CounterStore store) => core.Box(
          key: 'counter',
          direction: core.Axis.vertical,
          children: <core.UINode>[
            core.Box(
              key: 'increment',
              onTap: store.increment,
              children: <core.UINode>[core.TextNode('add')],
            ),
            core.TextNode('count $count', key: 'label'),
            core.TextInputNode(
              key: 'field',
              value: 'v$count',
              onChanged: (String text) {},
            ),
          ],
        ),
      );
}

web.HTMLDivElement host() {
  final web.HTMLDivElement element =
      web.document.createElement('div') as web.HTMLDivElement;
  web.document.body!.append(element);

  return element;
}

void press(web.Element element) => element.dispatchEvent(
  web.MouseEvent('click', web.MouseEventInit(bubbles: true)),
);

String? textAt(web.Element root, String key) =>
    root.querySelector('[data-unibox-key="$key"]')!.textContent;

web.Element at(web.Element root, String key) =>
    root.querySelector('[data-unibox-key="$key"]')!;

void main() {
  group('a stateful node', () {
    test('draws its first state, and its view of the next one', () {
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Counter(), element);

      expect(textAt(element, 'label'), 'count 0');

      press(at(element, 'increment'));

      expect(textAt(element, 'label'), 'count 1');

      view.dispose();
    });

    test('keeps the element of what did not change', () {
      // The reconciler and the store together: a publish patches the page instead of painting it
      // again, which is what a caret, a focus and a running animation depend on.
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Counter(), element);
      final web.Element label = at(element, 'label');

      press(at(element, 'increment'));

      expect(identical(at(element, 'label'), label), isTrue);

      view.dispose();
    });

    test('keeps the focus in a field across a publish', () {
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Counter(), element);
      final web.HTMLElement field = at(element, 'field') as web.HTMLElement;
      field.focus();
      expect(web.document.activeElement, field);

      press(at(element, 'increment'));

      expect(identical(at(element, 'field'), field), isTrue);
      expect(web.document.activeElement, field);

      view.dispose();
    });

    test(
      'calls onMount once, and onUnmount when the tree lets the node go',
      () {
        final web.HTMLDivElement element = host();
        final DomView view = DomView.mount(Counter(), element);
        final CounterStore store = CounterStore.last!;

        expect(store.mounts, 1);
        expect(store.unmounts, 0);

        view.render(const core.TextNode('gone'));

        expect(element.textContent, 'gone');
        expect(store.unmounts, 1);

        view.dispose();
      },
    );

    test('runs a callback that arrives with a new closure', () {
      // A re-render hands the element new closures; a listener left behind would call the state the
      // page has already left, so the old one is taken off before the new one goes on.
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Counter(), element);

      press(at(element, 'increment'));
      press(at(element, 'increment'));

      expect(textAt(element, 'label'), 'count 2');

      view.dispose();
    });

    test('answers a press on a box with the pointer it came from', () {
      final List<core.BoxTapEvent> events = <core.BoxTapEvent>[];
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.Box(width: 200, height: 100, onTapDown: events.add),
        element,
      );

      element
          .querySelector('div')!
          .dispatchEvent(
            web.PointerEvent(
              'pointerdown',
              web.PointerEventInit(bubbles: true, pointerType: 'touch'),
            ),
          );

      expect(events, hasLength(1));
      expect(events.single.pointer, core.BoxPointerKind.touch);

      view.dispose();
    });

    test('follows a link only when the tree says what a press means', () {
      bool followed = false;
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.LinkNode(
          '/listings',
          onTap: () => followed = true,
          child: const core.TextNode('Listings'),
        ),
        element,
      );

      final web.Event event = web.MouseEvent(
        'click',
        web.MouseEventInit(bubbles: true, cancelable: true),
      );
      element.querySelector('a')!.dispatchEvent(event);

      expect(followed, isTrue);
      expect(event.defaultPrevented, isTrue);

      view.dispose();
    });
  });
}
