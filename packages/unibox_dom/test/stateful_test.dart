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

    test('keeps a store with the element it drew, beside a stateful frame', () {
      // The catalogue's shape: buttons, and then a segmented button — a stateful frame holding
      // three ink wells, whose store is the frame's. A store is kept for the node at an *address*,
      // and a boundary repaint has to compute the addresses the pass that drew it used: when it
      // did not, the frame's repaint adopted the stores of the controls beside it, and the ripple
      // of a press on *Outlined* was drawn inside the third segment, *Month*.
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.Box(
          children: <core.UINode>[
            Mark('filled'),
            Mark('tonal'),
            Mark('outlined'),
            Marks(),
          ],
        ),
        element,
      );

      // Choosing a segment republishes the frame, which re-plans the three wells inside it.
      press(at(element, 'marks'));

      // The press after it lands on a control of its own.
      MarkStore.of('outlined').press();

      expect(
        element.querySelector('[data-unibox-key="mark-month"]'),
        isNotNull,
        reason: 'the third segment is still drawn by its own element',
      );
      expect(textAt(element, 'mark-month'), 'month 0');
      expect(textAt(element, 'mark-outlined'), 'outlined 1');

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

      // A headless runner's window is not focused, and Chrome dispatches no focus event for an element
      // in a document that is not: the binding is what this pins, so the events are dispatched when
      // the browser did not send them.
      if (focus.isEmpty) {
        field.dispatchEvent(web.Event('focus'));
        field.dispatchEvent(web.Event('blur'));
      }

      expect(focus, <bool>[true, false]);

      view.dispose();
    });

    test('dismisses an overlay on its barrier, and not on the dialog', () {
      // A dialog in the tree is a dialog a reader can see; the one press that closes it is a press
      // on the shade behind it. Without this a client can open a dialog and never be let out of it.
      int dismissals = 0;
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(
        core.OverlayNode(
          onDismiss: () => dismissals++,
          child: const core.Box(
            width: 100,
            height: 100,
            key: 'dialog',
            children: <core.UINode>[core.TextNode('Save?')],
          ),
        ),
        element,
      );

      at(element, 'dialog').dispatchEvent(
        web.MouseEvent('click', web.MouseEventInit(bubbles: true)),
      );
      expect(dismissals, 0);

      element
          .querySelector('[data-unibox-barrier]')!
          .dispatchEvent(
            web.MouseEvent('click', web.MouseEventInit(bubbles: true)),
          );

      expect(dismissals, 1);

      view.dispose();
    });

    test('clears a field when the store says the value changed', () {
      // The attribute of a field is its default and its property is what a reader sees, so a store
      // that resets a form has to reach the property: otherwise the box says empty and the page
      // still shows the old text.
      final web.HTMLDivElement element = host();
      final Form node = Form();
      final DomView view = DomView.mount(node, element);
      final web.HTMLInputElement field =
          at(element, 'field') as web.HTMLInputElement;

      field.value = 'ada';
      field.dispatchEvent(web.Event('input', web.EventInit(bubbles: true)));
      expect(field.value, 'ada');

      final FormStore store = FormStore.last!;
      store.clear();

      expect(field.value, '');

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

  group('the stylesheet a view writes', () {
    test('is left alone by a publish that adds no look', () {
      // A ripple publishes sixty times a second, and between two publishes of one tree no class
      // has changed. Serialising the sheet would make the browser re-parse every rule on the
      // page, so the sentinel is how a test sees that nothing was written at all.
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Counter(), element);
      final web.Element style = web.document.head!.querySelector(
        'style[data-unibox-css]',
      )!;

      style.textContent = '/* sentinel */';
      press(at(element, 'increment'));

      expect(textAt(element, 'label'), 'count 1');
      expect(style.textContent, '/* sentinel */');

      view.dispose();
      style.remove();
    });

    test('is written when a publish brings a look the page does not have', () {
      // The other half of the rule: a state whose look is new needs a rule, or the page holds an
      // element with a class nothing describes. What a browser paints from is the CSSOM, and
      // that is where a rule a publish brings appears: `textContent` is the text the element was
      // *given*, and inserting a rule does not change it.
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Tint(), element);
      final web.HTMLStyleElement style =
          web.document.head!.querySelector('style[data-unibox-css]')!
              as web.HTMLStyleElement;

      expect(style.sheet!.cssRules.length, 2);

      press(at(element, 'tint'));

      expect(style.sheet!.cssRules.length, 3);
      expect(
        style.sheet!.cssRules.item(2)!.cssText,
        contains('rgb(0, 255, 0)'),
      );

      view.dispose();
      style.remove();
    });

    test(
      'appends the rule a publish brings, instead of writing the sheet again',
      () {
        // A rule inserted is one rule parsed; a sheet assigned to `textContent` is every rule the
        // page holds, parsed again — 38 ms against nothing on a sheet of 300 KB. The rule objects
        // of the sheet surviving is how a test sees the difference: a rewrite throws the whole
        // CSSOM away and builds it again.
        final web.HTMLDivElement element = host();
        final DomView view = DomView.mount(Tint(), element);
        final web.HTMLStyleElement style =
            web.document.head!.querySelector('style[data-unibox-css]')!
                as web.HTMLStyleElement;
        final web.CSSStyleSheet sheet = style.sheet!;
        final web.CSSRule root = sheet.cssRules.item(0)!;

        press(at(element, 'tint'));

        expect(identical(sheet.cssRules.item(0), root), isTrue);
        expect(sheet.cssRules.length, 3);

        view.dispose();
        style.remove();
      },
    );

    test('writes the sheet whole again when the page no longer holds it', () {
      // A host, or a second view, can replace a sheet's text under the view that wrote it.
      // Appending to a sheet that lost its rules would leave elements wearing classes nothing
      // describes, so a sheet that is not the one this view wrote is written from the top.
      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(Tint(), element);
      final web.HTMLStyleElement style =
          web.document.head!.querySelector('style[data-unibox-css]')!
              as web.HTMLStyleElement;

      style.textContent = '/* sentinel */';

      press(at(element, 'tint'));

      expect(style.textContent, isNot(contains('sentinel')));
      expect(style.textContent, contains(':root{'));
      expect(style.textContent, startsWith(':root{'));

      view.dispose();
      style.remove();
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

/// The marks one control has left, the way an ink well keeps the drops it is drawing.
final class MarkStore extends core.StateStore<int> {
  /// Creates the store of the mark called [id].
  MarkStore(this.id) : super(0) {
    byId[id] = this;
  }

  /// The store each mark drew, so a test can press one without hunting for its element.
  static final Map<String, MarkStore> byId = <String, MarkStore>{};

  /// The name the control is drawn and found by.
  final String id;

  /// The store of the control called [id].
  static MarkStore of(String id) => byId[id]!;

  /// Leaves one more mark.
  void press() => state = state + 1;
}

/// A control that leaves a mark when it is pressed: the shape of an ink well.
final class Mark extends core.StatefulNode<int, MarkStore> {
  /// Creates the control called [id].
  factory Mark(String id) => Mark._(id, () => MarkStore(id));

  Mark._(this.id, MarkStore Function() create)
    : super(create: create, view: _markView);

  /// The name this control is drawn and found by.
  final String id;
}

/// One control's marks, in front of the label that counts them.
core.UINode _markView(int marks, MarkStore store) => core.Box(
  children: <core.UINode>[
    for (int i = 0; i < marks; i++) core.Box(key: '${store.id}-mark$i'),
    core.TextNode('${store.id} $marks', key: 'mark-${store.id}'),
  ],
);

/// The chosen segment of a [Marks]: its state, and the press that asks for another.
final class MarksStore extends core.StateStore<int> {
  /// Creates the frame with its first segment chosen.
  MarksStore() : super(0);

  /// Chooses the next segment.
  void choose() => state = state + 1;
}

/// Three controls in one stateful frame, the way a segmented button holds three ink wells: a press
/// asks the frame for another choice, and the frame re-plans what it holds.
final class Marks extends core.StatefulNode<int, MarksStore> {
  /// Creates the frame, with its first segment chosen.
  Marks()
    : super(
        create: MarksStore.new,
        view: (int chosen, MarksStore store) => core.Box(
          key: 'marks',
          onTap: store.choose,
          children: <core.UINode>[Mark('day'), Mark('week'), Mark('month')],
        ),
      );
}

/// A field a store owns: it can be typed into, and cleared from elsewhere.
final class FormStore extends core.StateStore<String> {
  FormStore() : super('') {
    last = this;
  }

  /// The store the view created, for a test that has to reach into it.
  static FormStore? last;

  void set(String value) => state = value;

  void clear() => state = '';
}

final class Form extends core.StatefulNode<String, FormStore> {
  Form()
    : super(
        create: FormStore.new,
        view: (String value, FormStore store) => core.TextInputNode(
          key: 'field',
          value: value,
          onChanged: store.set,
        ),
      );
}

/// A box that turns green when it is pressed, so a publish can bring a look the page has not
/// drawn yet: the shape of anything whose state is a colour of its own.
final class Tint extends core.StatefulNode<bool, TintStore> {
  /// Creates the box, off.
  Tint()
    : super(
        create: TintStore.new,
        view: (bool on, TintStore store) => core.Box(
          key: 'tint',
          backgroundColor: on ? const core.BoxColor(0xFF00FF00) : null,
          onTap: store.toggle,
          children: <core.UINode>[const core.TextNode('tint')],
        ),
      );
}

/// Whether the box of a [Tint] is coloured.
final class TintStore extends core.StateStore<bool> {
  /// Creates the store, off.
  TintStore() : super(false);

  /// Colours the box, or stops colouring it.
  void toggle() => state = !state;
}
