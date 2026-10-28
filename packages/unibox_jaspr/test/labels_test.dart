import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// A node a package would ship without naming itself: an inspector reads the name of
/// the node it extends, because a type name does not survive a compiled build.
final class PromoCard extends core.Box {
  const PromoCard({super.children});
}

/// A node that names itself, which is what a package does so an inspector reads
/// `sale-banner` rather than `box`.
final class SaleBanner extends core.Box {
  const SaleBanner({super.children});

  @override
  String? get debugLabel => 'sale-banner';
}

void main() {
  group('an element a node drew', () {
    testComponents('carries the name of its node', (tester) async {
      pumpNode(
        tester,
        const core.Box(children: <core.UINode>[core.TextNode('Hi')]),
      );

      expect(attributesOf(find.tag('div'))['data-unibox-node'], 'box');
      expect(attributesOf(find.tag('span'))['data-unibox-node'], 'text');
    });

    testComponents('is named by its node, not by the tag', (tester) async {
      pumpNode(tester, const core.TextNode('Hi', headingLevel: 1));

      expect(attributesOf(find.tag('h1'))['data-unibox-node'], 'text');
    });

    testComponents('is named for a grid, an image, a link and a field', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          children: <core.UINode>[
            core.GridNode(
              minItemWidth: 200,
              children: <core.UINode>[core.TextNode('Hi')],
            ),
            core.ImageNode('a.png', alt: 'A'),
            core.LinkNode('/x', child: core.TextNode('Go')),
            core.TextInputNode(),
          ],
        ),
      );

      expect(attributesOf(find.tag('img'))['data-unibox-node'], 'image');
      expect(attributesOf(find.tag('a'))['data-unibox-node'], 'link');
      expect(attributesOf(find.tag('input'))['data-unibox-node'], 'text-input');

      final List<String?> grids = <String?>[
        for (final TestRenderElement element in elementsOf(find.tag('div')))
          (element.attributes ?? const <String, String>{})['data-unibox-node'],
      ];

      // The page box and the grid it holds; a grid's children are its cells, not
      // wrappers of the renderer's.
      expect(grids, <String?>['box', 'grid']);
    });

    testComponents('is left off the wrapper a renderer invents', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.StackNode(
          children: <core.UINode>[
            core.Box(children: <core.UINode>[core.TextNode('Hi')]),
          ],
        ),
      );

      final List<String?> labels = <String?>[
        for (final TestRenderElement element in elementsOf(find.tag('div')))
          (element.attributes ?? const <String, String>{})['data-unibox-node'],
      ];

      // A stack's cell wrapper is the renderer's, not a node's, so it has no
      // name; the stack and the box it holds do.
      expect(labels, <String?>['stack', null, 'box']);
    });

    testComponents('is named after the type of a node', (tester) async {
      pumpNode(tester, const PromoCard());

      expect(attributesOf(find.tag('div'))['data-unibox-node'], 'box');
    });

    testComponents('reads the name a node gives itself', (tester) async {
      pumpNode(tester, const SaleBanner());

      expect(attributesOf(find.tag('div'))['data-unibox-node'], 'sale-banner');
    });
  });

  group('a name is not a look', () {
    testComponents('leaves the class and the stylesheet to the styles', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());
      final String? plainClass = classesOf(find.tag('div'));
      final String plainCss = allCss();

      pumpNode(tester, const PromoCard());

      // Two node types with the same look share one rule: the name says what an
      // element is, and the class says what it looks like.
      expect(classesOf(find.tag('div')), plainClass);
      expect(allCss(), plainCss);
      expect(attributesOf(find.tag('div'))['data-unibox-node'], 'box');
    });
  });
}
