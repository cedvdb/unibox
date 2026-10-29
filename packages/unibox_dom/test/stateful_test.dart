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

    test('keeps the pressed element alive while the press is publishing', () {
      // The bug this exists for: a press that publishes (an ink drop, a spinner) used to re-render
      // the page between `pointerdown` and `click`, so the browser delivered the click to an element
      // that no longer existed and nothing happened. A boundary is patched, never replaced.
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Press(), element);
      final web.Element root = at(element, 'root');

      root.dispatchEvent(
        web.PointerEvent('pointerdown', web.PointerEventInit(bubbles: true)),
      );

      // The press published: a drop is in front of the label now.
      expect(element.querySelectorAll('[data-unibox-key="drop0"]').length, 1);
      expect(identical(at(element, 'root'), root), isTrue);

      root.dispatchEvent(
        web.MouseEvent('click', web.MouseEventInit(bubbles: true)),
      );

      expect(textAt(element, 'label'), 'presses 1');

      view.dispose();
    });

    test('measures a press from the box, not from what it hit', () {
      // A press lands on whatever is under the pointer — usually a label inside the control — and
      // `offsetX` is measured from that label's edge. A ripple built from it starts at the top of
      // the control instead of under the finger, which is exactly what a segmented button showed.
      final List<core.BoxTapEvent> events = <core.BoxTapEvent>[];
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.Box(
          width: 200,
          height: 100,
          padding: core.BoxSpacing.all(20),
          onTapDown: events.add,
          children: <core.UINode>[const core.TextNode('Label')],
        ),
        element,
      );

      final web.Element box = element.children.item(0)!;
      final web.Element label = box.querySelector('span')!;
      final web.DOMRect rect = box.getBoundingClientRect();

      // The point is over the label, 50 across and 30 down from the box's own corner.
      label.dispatchEvent(
        web.PointerEvent(
          'pointerdown',
          web.PointerEventInit(
            bubbles: true,
            clientX: (rect.left + 50).round(),
            clientY: (rect.top + 30).round(),
          ),
        ),
      );

      expect(events, hasLength(1));
      expect(events.single.position.x, closeTo(50, 0.5));
      expect(events.single.position.y, closeTo(30, 0.5));

      view.dispose();
    });

    test('reports a hover, and ends it when the pointer leaves', () {
      // The material navigation bar lights the pill of the destination under the pointer, and the
      // pointer is over the share while the pill is a layer below it — so the hover is state, and a
      // renderer that binds no `onHover` leaves that light dead.
      final List<bool> hovers = <bool>[];
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.Box(width: 100, height: 48, onHover: hovers.add),
        element,
      );

      final web.Element box = element.children.item(0)!;
      box.dispatchEvent(web.PointerEvent('pointerenter'));
      box.dispatchEvent(web.PointerEvent('pointerleave'));

      expect(hovers, <bool>[true, false]);

      view.dispose();
    });

    test('activates a control from the keyboard', () {
      // A box with a role is in the tab order, so it has to answer the keys a button answers:
      // `Enter` on the way down and `Space` on the way up, the way Flutter's renderer does.
      int taps = 0;
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.Box(
          semantics: const core.BoxSemantics(role: core.BoxRole.button),
          onTap: () => taps++,
          children: <core.UINode>[const core.TextNode('Save')],
        ),
        element,
      );
      final web.Element box = element.children.item(0)!;

      box.dispatchEvent(
        web.KeyboardEvent('keydown', web.KeyboardEventInit(key: 'Enter')),
      );
      expect(taps, 1);

      box.dispatchEvent(
        web.KeyboardEvent('keydown', web.KeyboardEventInit(key: ' ')),
      );
      expect(taps, 1, reason: 'Space fires on the way up');

      box.dispatchEvent(
        web.KeyboardEvent('keyup', web.KeyboardEventInit(key: ' ')),
      );
      expect(taps, 2);

      view.dispose();
    });

    test('reports the focus a field gains and loses', () {
      final List<bool> focus = <bool>[];
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.TextInputNode(onFocusChanged: focus.add, key: 'field'),
        element,
      );
      final web.HTMLElement field = at(element, 'field') as web.HTMLElement;

      field.focus();
      field.blur();

      expect(focus, <bool>[true, false]);

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

/// A component that publishes *during* a press, the way the ink well does: a drop appears before
/// the press ends, and the drop has to take its place without the pressed element being rebuilt.
final class PressStore extends core.StateStore<int> {
  PressStore() : super(0);

  int drops = 0;

  void down() {
    drops++;
    state = state + 100;
  }

  void press() => state = state + 1;
}

final class Press extends core.StatefulNode<int, PressStore> {
  Press()
    : super(
        create: PressStore.new,
        view: (int state, PressStore store) => core.Box(
          key: 'root',
          direction: core.Axis.vertical,
          onTapDown: (core.BoxTapEvent event) => store.down(),
          onTap: store.press,
          children: <core.UINode>[
            // A layer the press adds in front of everything, which is what shifts the content of
            // an ink well: an element inserted before another must not rebuild it.
            for (int i = 0; i < state ~/ 100; i++)
              core.Box(key: 'drop$i', children: const <core.UINode>[]),
            core.TextNode('presses ${state % 100}', key: 'label'),
          ],
        ),
      );
}
