import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_jaspr/unibox_jaspr.dart';

import 'support/harness.dart';

/// Every DOM element the tree rendered, as tags in document order.
///
/// The recorder is a document element next to the tree, so where it sits is the
/// fact under test and not only that it exists.
List<String> tagsInDocumentOrder() => <String>[
  for (final TestRenderElement element in elementsOf(
    find.byElementType(DomElement),
  ))
    element.tag,
];

void main() {
  group('a page that a runtime can take over', () {
    testComponents('carries the recorder above its tree', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          key: 'listings',
          overflow: core.Overflow.scroll,
          children: <core.UINode>[core.TextNode('Hi')],
        ),
      );

      final List<String> tags = tagsInDocumentOrder();
      final int script = tags.indexOf('script');
      final int tree = tags.indexOf('div');

      expect(tags.where((String tag) => tag == 'script'), hasLength(1));
      expect(script, lessThan(tree));
    });

    testComponents('records the elements a node keyed', (tester) async {
      pumpNode(tester, const core.Box(key: 'listings'));

      // The script reads the attribute the renderer writes, from the one place that
      // spells it, so the two halves of the handover cannot drift apart.
      expect(textOf(find.tag('script')), contains("'data-unibox-key'"));
    });

    testComponents('hands the record over on window, not on an element', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());

      // The takeover replaces the elements and the listeners with them, so a record
      // kept on one of them would be gone by the time the runtime asks for it.
      final String script = textOf(find.tag('script'));
      expect(script, contains('window.uniboxScroll'));
      expect(script, contains('take: function'));
    });

    testComponents('keeps the offset of a region, not the document', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());

      // A Flutter takeover paints into a canvas the size of the viewport, so the
      // browser's own scroll position is not something it can inherit: only the
      // regions inside the tree are.
      final String script = textOf(find.tag('script'));
      expect(script, contains('scrollLeft'));
      expect(script, contains('scrollTop'));
    });

    testComponents('compiles no script of its own', (tester) async {
      pumpNode(tester, const core.Box());

      // It is a document element and not a bundle: a takeover page is static HTML
      // with no client to extend, and a download in front of the bootstrap is the
      // one cost the handover cannot pay.
      expect(attributesOf(find.tag('script')), isNot(contains('src')));
      expect(textOf(find.tag('script')), isNotEmpty);
    });

    testComponents('is written raw, so the script is the script', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());

      final TestRenderText body = elementOf(find.tag('script')).children
          .whereType<TestRenderText>()
          .single;

      // `<script>` is a raw text element: escaped, `&&` would ship as `&amp;&amp;`
      // and the file would not run.
      expect(body.rawHtml, isTrue);
    });
  });

  group('the recorder', () {
    testComponents('takes no nonce until a policy asks for one', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());

      expect(attributesOf(find.tag('script')), isNot(contains('nonce')));
    });

    testComponents('takes the nonce of the page when given one', (
      tester,
    ) async {
      tester.pumpComponent(
        renderJaspr(const core.Box(), scriptNonce: 'r4nd0m'),
      );

      expect(attributesOf(find.tag('script'))['nonce'], 'r4nd0m');
    });

    testComponents('is left off a page that will never be taken over', (
      tester,
    ) async {
      tester.pumpComponent(renderJaspr(const core.Box(), recordScroll: false));

      // A page served to a crawler and to a reader with no application behind it
      // keeps the rule that a static page ships no script of its own.
      expect(find.tag('script'), findsNothing);
      expect(find.tag('style'), findsComponents);
    });

    testComponents('registers once, however often the page carries it', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());

      // A page that includes the recorder twice — a layout and a page that both want
      // it — must not stack two sets of listeners.
      expect(textOf(find.tag('script')), contains('if (window.uniboxScroll)'));
    });
  });
}
