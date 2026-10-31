import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

void main() {
  group('renderFlutter validation', () {
    testWidgets('renders a well formed tree', (tester) async {
      await pumpNode(
        tester,
        const core.Box(children: <core.UINode>[core.TextNode('Hello')]),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('throws for a link nested in a link', (tester) async {
      const core.Box node = core.LinkNode(
        'https://a.dev',
        children: <core.UINode>[
          core.LinkNode(
            'https://b.dev',
            children: <core.UINode>[core.TextNode('inner')],
          ),
        ],
      );

      expect(() => renderFlutter(node), throwsStateError);
    });

    testWidgets('warns about a positioned node outside a stack', (
      tester,
    ) async {
      final List<String> messages = <String>[];
      final original = debugPrint;

      debugPrint = (message, {wrapWidth}) {
        messages.add(message ?? '');
      };
      try {
        await pumpNode(
          tester,
          const core.Box(
            children: <core.UINode>[
              core.PositionedNode(top: 4, child: core.TextNode('badge')),
            ],
          ),
        );
      } finally {
        debugPrint = original;
      }

      expect(messages, hasLength(1));
      expect(messages.single, startsWith('Unibox warning:'));
      expect(messages.single, contains('PositionedNode'));
    });
  });
}
