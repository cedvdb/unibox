import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// The scope a host application is expected to provide around its tree.
Widget scope(Widget child) =>
    FlutterLinkScope(open: (String url) {}, child: child);

void main() {
  group('LinkNode', () {
    testWidgets('renders its child', (tester) async {
      await pumpNode(
        tester,
        const core.LinkNode('https://unibox.dev', child: core.TextNode('Docs')),
        wrap: scope,
      );

      expect(find.text('Docs'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      int taps = 0;

      await pumpNode(
        tester,
        core.LinkNode(
          'https://unibox.dev',
          child: const core.TextNode('Docs'),
          onTap: () => taps++,
        ),
      );
      await tester.tap(find.text('Docs'));

      expect(taps, 1);
    });

    testWidgets('opens the destination through the enclosing scope', (
      tester,
    ) async {
      final List<String> opened = <String>[];

      await pumpNode(
        tester,
        const core.LinkNode(
          'https://unibox.dev/guide',
          child: core.TextNode('Guide'),
        ),
        wrap: (Widget child) => FlutterLinkScope(
          open: (String url) => opened.add(url),
          child: child,
        ),
      );
      await tester.tap(find.text('Guide'));

      expect(opened, <String>['https://unibox.dev/guide']);
    });

    testWidgets('lets onTap answer the press instead of the opener', (
      tester,
    ) async {
      final List<String> events = <String>[];

      await pumpNode(
        tester,
        core.LinkNode(
          'https://unibox.dev',
          child: const core.TextNode('Docs'),
          onTap: () => events.add('onTap'),
        ),
        wrap: (Widget child) => FlutterLinkScope(
          open: (String url) => events.add('open:$url'),
          child: child,
        ),
      );
      await tester.tap(find.text('Docs'));

      // A node that names a handler is handled by the tree: the opener stands for
      // "follow the link", and on the web the same rule cancels the navigation, so a
      // dialog the tree opens is not replaced by a page load. One press, one answer.
      expect(events, <String>['onTap']);
    });

    testWidgets('reports a link that can neither open nor call back', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.LinkNode('https://unibox.dev', child: core.TextNode('Docs')),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('shows a click cursor', (tester) async {
      await pumpNode(
        tester,
        const core.LinkNode('https://unibox.dev', child: core.TextNode('Docs')),
        wrap: scope,
      );

      final MouseRegion region = tester.widget<MouseRegion>(
        inNode(find.byType(MouseRegion)),
      );

      expect(region.cursor, SystemMouseCursors.click);
    });

    testWidgets('is exposed as a link to assistive technologies', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        const core.LinkNode('https://unibox.dev', child: core.TextNode('Docs')),
        wrap: scope,
      );

      expect(
        tester.getSemantics(find.text('Docs')),
        isSemantics(label: 'Docs', isLink: true),
      );

      handle.dispose();
    });

    testWidgets('is tappable inside a box', (tester) async {
      int taps = 0;

      await pumpNode(
        tester,
        core.Box(
          padding: const core.BoxSpacing.all(8),
          children: [
            core.LinkNode(
              'https://unibox.dev',
              child: const core.TextNode('Docs'),
              onTap: () => taps++,
            ),
          ],
        ),
      );
      await tester.tap(find.text('Docs'));

      expect(taps, 1);
    });
  });
}
