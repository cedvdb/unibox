import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

void main() {
  group('LinkNode', () {
    testComponents('renders an anchor with the destination as href', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.LinkNode(
          'https://example.com',
          child: core.TextNode('Example'),
        ),
      );

      expect(find.tag('a'), findsOneComponent);
      expect(attributesOf(find.tag('a')), <String, String>{
        'href': 'https://example.com',
        'data-unibox-node': 'link',
      });
      expect(find.text('Example'), findsOneComponent);
    });

    testComponents('keeps relative destinations untouched', (tester) async {
      pumpNode(
        tester,
        const core.LinkNode('/docs', child: core.TextNode('Docs')),
      );

      expect(attributesOf(find.tag('a'))['href'], '/docs');
    });

    testComponents('cancels the user agent styling of a link', (tester) async {
      // The browser colours a link blue and underlines it. Flutter draws the
      // child of a link as it is, so leaving the user agent styles in place would
      // make the same tree look different on the two targets: the anchor takes
      // its colour from the box instead and adds no decoration of its own.
      pumpNode(
        tester,
        const core.LinkNode('/docs', child: core.TextNode('Docs')),
      );

      expect(stylesOf(find.tag('a')), <String, String>{
        'color': 'inherit',
        'text-decoration': 'none',
      });
    });

    testComponents('wraps any child node', (tester) async {
      pumpNode(
        tester,
        const core.LinkNode(
          '/docs',
          child: core.Box(
            direction: core.Axis.horizontal,
            gap: 8,
            children: [
              core.ImageNode('assets/logo.png', width: 24, height: 24),
              core.TextNode('Docs'),
            ],
          ),
        ),
      );

      expect(find.tag('a'), findsOneComponent);
      expect(find.tag('div'), findsOneComponent);
      expect(find.tag('img'), findsOneComponent);
      expect(find.tag('span'), findsOneComponent);
    });

    testComponents('opens the destination in a new tab', (tester) async {
      pumpNode(
        tester,
        const core.LinkNode(
          'https://example.com',
          newTab: true,
          child: core.TextNode('Example'),
        ),
      );

      expect(attributesOf(find.tag('a')), <String, String>{
        'rel': 'noopener noreferrer',
        'href': 'https://example.com',
        'target': '_blank',
        'data-unibox-node': 'link',
      });
    });

    testComponents('calls onTap when clicked and keeps the href', (
      tester,
    ) async {
      var taps = 0;
      pumpNode(
        tester,
        core.LinkNode(
          'https://example.com',
          onTap: () => taps++,
          child: const core.TextNode('Example'),
        ),
      );

      await tester.click(find.tag('a'));

      expect(taps, 1);
      expect(attributesOf(find.tag('a'))['href'], 'https://example.com');
    });

    testComponents('keeps a link without callbacks free of listeners', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.LinkNode('/docs', child: core.TextNode('Docs')),
      );

      expect(
        elementOf(find.tag('a')).events ?? const <String, Object>{},
        isEmpty,
      );
    });
  });
}
