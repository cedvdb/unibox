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

    test('takes away a child the tree no longer describes', () {
      final core.UINode tree = const core.Box(
        children: <core.UINode>[core.TextNode('kept')],
      );
      final web.HTMLDivElement element = host()
        ..innerHTML = servedMarkup(tree).toJS;
      // The server wrote a stale sibling, as a cached page would.
      element.children
          .item(0)!
          .append(web.document.createElement('span')..textContent = 'stale');

      final DomView view = DomView.adopt(tree, element.children.item(0)!);

      expect(view.element.querySelectorAll('span').length, 1);
      expect(view.element.textContent, 'kept');

      view.dispose();
    });

    test('reads the stylesheet the document wrote instead of adding one', () {
      final core.UINode tree = const core.Box(
        children: <core.UINode>[core.TextNode('Hello')],
      );
      final web.HTMLStyleElement style =
          web.document.createElement('style') as web.HTMLStyleElement
            ..setAttribute('data-unibox-css', '');
      web.document.head!.append(style);
      final int before = web.document.head!.children.length;

      final web.HTMLDivElement element = host()
        ..innerHTML = servedMarkup(tree).toJS;
      final DomView view = DomView.adopt(tree, element.children.item(0)!);

      expect(web.document.head!.children.length, before);
      expect(style.textContent, contains(':root{'));

      view.dispose();
    });
  });
}
