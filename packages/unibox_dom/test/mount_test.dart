@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:web/web.dart' as web;

/// Where a view is drawn in the test page.
web.HTMLDivElement host() {
  final web.HTMLDivElement element =
      web.document.createElement('div') as web.HTMLDivElement;
  web.document.body!.append(element);

  return element;
}

void main() {
  group('a mounted tree', () {
    test('is the markup the string renderer writes', () {
      // The claim both renderers rest on: which element a node becomes, in what order its
      // attributes are written, and which class it wears are decided once, in the plan — so a
      // client can take a page a server wrote instead of painting over it.
      const core.UINode tree = core.Box(
        direction: core.Axis.vertical,
        gap: 8,
        padding: core.BoxSpacing.all(16),
        children: <core.UINode>[
          core.TextNode('Hello', headingLevel: 1),
          core.LinkNode(
            '/listings',
            children: <core.UINode>[core.TextNode('Listings')],
          ),
        ],
      );

      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(tree, element);

      final String fragment = toHtml(tree);
      final String markup = fragment.substring(
        fragment.indexOf('</style>') + 8,
      );

      expect(element.innerHTML, markup);

      view.dispose();
    });

    test('brings the stylesheet with it, and takes it away', () {
      final int before = web.document.head!.children.length;
      final DomView view = DomView.mount(
        const core.Box(children: <core.UINode>[core.TextNode('Hi')]),
        host(),
        theme: MaterialPalette.light.theme,
      );

      expect(web.document.head!.children.length, before + 1);
      // The `:root` block the string renderer writes for the same theme, down to the colours: a
      // class name and a custom property have to agree across the two, or a page cannot be adopted.
      expect(web.document.head!.innerHTML, contains('--unibox-color-primary:'));
      expect(web.document.head!.innerHTML, contains(':root{'));

      view.dispose();

      expect(web.document.head!.children.length, before);
    });

    test('draws every node type the document renderer draws', () {
      const core.UINode tree = core.Box(
        children: <core.UINode>[
          core.ImageNode('a.png', alt: 'A flat'),
          core.GridNode(
            minItemWidth: 200,
            children: <core.UINode>[core.TextNode('In a grid')],
          ),
          core.StackNode(children: <core.UINode>[core.TextNode('Over')]),
          core.TextInputNode(value: 'ada', key: 'email'),
        ],
      );

      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(tree, element);
      final String fragment = toHtml(tree);

      expect(
        element.innerHTML,
        fragment.substring(fragment.indexOf('</style>') + 8),
      );
      expect(
        element.querySelector('input')!.getAttribute('data-unibox-key'),
        'email',
      );

      view.dispose();
    });

    test('takes a browser\'s own heading look apart', () {
      // What a heading is *drawn* as, not what its class says: a user agent gives `h1`-`h6` a
      // `1.5em` size and `0.83em` margins of its own, and the model has no place for either.
      // Measured here because only a browser can say whether the reset arrived — the tree
      // states 22 pixels, and a `<h2>` that inherits nothing from it computes 33.
      const core.UINode tree = core.Box(
        textStyle: core.BoxTextStyle(fontSize: 22),
        children: <core.UINode>[
          // A plain text of the same typography, planned first: it used to mint the class
          // the heading wore, and the heading then kept the user agent's look.
          core.TextNode('Apartments'),
          core.TextNode('Join Unibox', headingLevel: 2),
        ],
      );

      final web.HTMLDivElement element = host();
      final DomView view = DomView.mount(tree, element);
      final web.CSSStyleDeclaration style = web.window.getComputedStyle(
        element.querySelector('h2')!,
      );

      expect(style.fontSize, '22px');
      expect(style.marginTop, '0px');
      expect(style.marginBottom, '0px');

      view.dispose();
    });
  });
}
