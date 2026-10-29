@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_html/unibox_html.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

/// The markup a server wrote for [tree], as it would arrive in a page.
String servedMarkup(core.UINode tree) {
  final String html = toHtml(tree);

  return html.substring(html.indexOf('</style>') + 8);
}

void main() {
  group('a client that adopts a page', () {
    test('keeps the elements the server wrote', () {
      // This is the whole point of one element plan: the page a crawler read and the page a reader
      // acts on are the same elements, so nothing is rebuilt and nothing flashes — and a reader's
      // scroll, focus and text selection survive the client arriving.
      int taps = 0;
      final core.UINode tree = core.Box(
        key: 'root',
        direction: core.Axis.vertical,
        onTap: () => taps++,
        children: <core.UINode>[const core.TextNode('Hello')],
      );
      final web.HTMLDivElement element = host()
        ..innerHTML = servedMarkup(tree).toJS;
      final web.Element before = element.children.item(0)!;

      final DomView view = DomView.adopt(tree, before);

      expect(identical(view.element, before), isTrue);
      expect(element.children.length, 1);

      // The behaviour arrives with the markup that was already there.
      before.dispatchEvent(
        web.MouseEvent('click', web.MouseEventInit(bubbles: true)),
      );
      expect(taps, 1);

      view.dispose();
    });

    test('leaves the page untouched when it came from the same build', () {
      // The saving, stated as a test: no attribute is written, no child is added or removed, no
      // stylesheet is rewritten. A reader who has scrolled, focused or selected text keeps all
      // three, because nothing local to their reading was touched.
      final core.UINode tree = const core.Box(
        key: 'root',
        children: <core.UINode>[core.TextNode('kept')],
      );
      final web.HTMLDivElement element = host()
        ..innerHTML = servedMarkup(tree).toJS;
      final web.Element root = element.children.item(0)!;
      // A mark nothing in the renderer writes: if it is still there, nothing was patched.
      root.setAttribute('data-test-untouched', 'yes');
      final int head = web.document.head!.children.length;

      final DomView view = DomView.adopt(tree, root);

      expect(root.getAttribute('data-test-untouched'), 'yes');
      expect(web.document.head!.children.length, head);
      expect(element.textContent, 'kept');

      view.dispose();
    });

    test('repairs a page that came from another build', () {
      // A cached document against a newer bundle: the labels may line up and the content may not,
      // so the client takes the slow path — plan, patch, rewrite — which is also what removes a
      // child the tree no longer describes.
      final meta = web.document.createElement('meta')
        ..setAttribute('name', 'unibox-build')
        ..setAttribute('content', 'another-build');
      web.document.head!.append(meta);

      final core.UINode tree = const core.Box(
        children: <core.UINode>[core.TextNode('kept')],
      );
      final web.HTMLDivElement element = host()
        ..innerHTML = servedMarkup(tree).toJS;
      element.children
          .item(0)!
          .append(web.document.createElement('span')..textContent = 'stale');

      final DomView view = DomView.adopt(tree, element.children.item(0)!);

      expect(view.element.querySelectorAll('span').length, 1);
      expect(view.element.textContent, 'kept');

      view.dispose();
      meta.remove();
    });

    test('still repaints a stateful node when its store publishes', () {
      // The fast path binds the callbacks of the view a store starts with. A press runs one, the
      // store publishes — and the page has to be drawn again. If the walk binds but leaves the
      // boundary with nothing to patch, the page is interactive and frozen at once.
      final web.HTMLDivElement element = host()
        ..innerHTML = servedMarkup(Tally()).toJS;
      final DomView view = DomView.adopt(Tally(), element.children.item(0)!);

      expect(element.textContent, contains('count 0'));

      element
          .querySelector('[data-unibox-key="add"]')!
          .dispatchEvent(
            web.MouseEvent('click', web.MouseEventInit(bubbles: true)),
          );

      expect(element.textContent, contains('count 1'));

      view.dispose();
    });

    test('keeps the stylesheet the document wrote, and adds none', () {
      final core.UINode tree = const core.Box(
        children: <core.UINode>[core.TextNode('Hello')],
      );
      final web.HTMLStyleElement style =
          web.document.createElement('style') as web.HTMLStyleElement
            ..setAttribute('data-unibox-css', '')
            ..textContent = ':root{} /* the document wrote this */';
      web.document.head!.append(style);
      final int before = web.document.head!.children.length;

      final web.HTMLDivElement element = host()
        ..innerHTML = servedMarkup(tree).toJS;
      final DomView view = DomView.adopt(tree, element.children.item(0)!);

      expect(web.document.head!.children.length, before);
      expect(style.textContent, contains('the document wrote this'));

      view.dispose();
      style.remove();
    });
  });
}

/// A counter, so an adoption can be asked whether a state change still repaints.
final class TallyStore extends core.StateStore<int> {
  TallyStore() : super(0);

  void increment() => state = state + 1;
}

final class Tally extends core.StatefulNode<int, TallyStore> {
  Tally()
    : super(
        create: TallyStore.new,
        view: (int count, TallyStore store) => core.Box(
          key: 'tally',
          direction: core.Axis.vertical,
          children: <core.UINode>[
            core.Box(
              key: 'add',
              onTap: store.increment,
              children: <core.UINode>[const core.TextNode('add')],
            ),
            core.TextNode('count $count', key: 'label'),
          ],
        ),
      );
}
