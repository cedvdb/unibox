@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_html/unibox_html.dart';
import 'package:web/web.dart' as web;

/// A host in the document, because focus is the document's to give: an element outside it cannot
/// hold it, and that is the whole fact this file tests.
web.HTMLDivElement host() {
  final web.HTMLDivElement element =
      web.document.createElement('div') as web.HTMLDivElement;
  web.document.body!.append(element);

  return element;
}

/// A marker no renderer writes, so a test can tell a reused element from a new one.
void mark(web.Element element, String value) =>
    element.setAttribute('data-test-marker', value);

String? markerOf(web.Element element) =>
    element.getAttribute('data-test-marker');

core.UINode list(List<String> names, {bool keyed = true}) => core.Box(
  children: <core.UINode>[
    for (final String name in names)
      core.TextNode(name, key: keyed ? name : null),
  ],
);

void main() {
  group('a re-render', () {
    test('patches the element that is already there', () {
      // The whole point of the patcher: an element keeps its identity, and with it the focus, the
      // caret, the scroll and the listeners attached to it.
      final DomView view = DomView.mount(
        const core.Box(children: <core.UINode>[core.TextNode('one')]),
        host(),
      );
      final web.Element text = view.element.querySelector('span')!;
      mark(text, 'kept');

      view.render(
        const core.Box(children: <core.UINode>[core.TextNode('two')]),
      );

      final web.Element after = view.element.querySelector('span')!;
      expect(identical(after, text), isTrue);
      expect(markerOf(after), 'kept');
      expect(after.textContent, 'two');

      view.dispose();
    });

    test('moves a keyed child instead of building another', () {
      final DomView view = DomView.mount(list(<String>['a', 'b', 'c']), host());
      final web.HTMLCollection before = view.element.children;
      mark(before.item(0)!, 'first');
      mark(before.item(2)!, 'last');

      view.render(list(<String>['c', 'a', 'b']));

      final List<String> order = <String>[
        for (int i = 0; i < view.element.children.length; i++)
          view.element.children.item(i)!.textContent!,
      ];
      expect(order, <String>['c', 'a', 'b']);
      // The element that was last is now first, and it is the same element.
      expect(markerOf(view.element.children.item(0)!), 'last');
      expect(markerOf(view.element.children.item(1)!), 'first');

      view.dispose();
    });

    test('adds and removes what the tree does', () {
      final DomView view = DomView.mount(list(<String>['a', 'b']), host());

      view.render(list(<String>['a', 'b', 'c']));
      expect(view.element.children.length, 3);

      view.render(list(<String>['c']));
      expect(view.element.children.length, 1);
      expect(view.element.children.item(0)!.textContent, 'c');

      view.dispose();
    });

    test('takes away an attribute the new plan does not write', () {
      final DomView view = DomView.mount(
        const core.TextNode('hi', headingLevel: 1),
        host(),
      );
      expect(view.element.tagName.toLowerCase(), 'h1');

      view.render(const core.TextNode('hi'));

      // A different tag is a different element: the plan says so and the DOM follows.
      expect(view.element.tagName.toLowerCase(), 'span');
      expect(view.element.textContent, 'hi');

      view.dispose();
    });

    test('keeps what follows a child inserted at the front', () {
      // The ink drop case: a press publishes a layer that goes in front of the content, and the
      // content has to stay the element it was — a press whose element is rebuilt never becomes a
      // click, because a browser compares the element it saw pressed with the one it sees released.
      final DomView view = DomView.mount(
        const core.Box(children: <core.UINode>[core.TextNode('content')]),
        host(),
      );
      final web.Element content = view.element.querySelector('span')!;

      view.render(
        const core.Box(
          children: <core.UINode>[
            core.TextNode('drop'),
            core.TextNode('content'),
          ],
        ),
      );

      final List<web.Element> spans = <web.Element>[
        for (int i = 0; i < view.element.children.length; i++)
          view.element.children.item(i)!,
      ];
      expect(spans.map((web.Element e) => e.textContent), <String>[
        'drop',
        'content',
      ]);
      expect(identical(spans.last, content), isTrue);

      view.dispose();
    });

    test('keeps the markup an embed carries', () {
      // An embed is one element whose content is the host's markup. Reconciling children after
      // writing that markup read the frame as an unmatched child and removed it, which is how the
      // example's comparison lost both of its frames the moment the client adopted the page.
      final DomView view = DomView.mount(
        const HtmlEmbed('<iframe src="a"></iframe>'),
        host(),
      );

      expect(view.element.querySelector('iframe'), isNotNull);

      view.render(const HtmlEmbed('<iframe src="b"></iframe>'));

      expect(view.element.querySelector('iframe'), isNotNull);
      expect(view.element.querySelector('iframe')!.getAttribute('src'), 'b');

      view.dispose();
    });

    test('keeps a field, its value and its focus', () {
      final DomView view = DomView.mount(
        const core.TextInputNode(value: 'ada', key: 'email'),
        host(),
      );
      final web.HTMLElement field = view.element as web.HTMLElement;
      field.focus();

      view.render(
        const core.TextInputNode(value: 'ada lovelace', key: 'email'),
      );

      expect(identical(view.element, field), isTrue);
      expect(web.document.activeElement, field);

      view.dispose();
    });
  });
}
