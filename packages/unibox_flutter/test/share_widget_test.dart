import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// Renders [node] on a window of [size] logical pixels, so a share of the viewport has
/// something to resolve against.
Future<void> pumpOn(WidgetTester tester, core.UINode node, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpNode(tester, node);
}

Size sizeOf(WidgetTester tester, Object key) =>
    tester.getSize(find.byKey(ValueKey<Object>(key)));

void main() {
  group('a share of the viewport', () {
    testWidgets('is as tall as the window, less the room it is told to lose', (
      tester,
    ) async {
      // The map panel: the screen minus a 48 pixel header and a 144 pixel toolbar, which the
      // parent it is drawn in has no height to share.
      await pumpOn(
        tester,
        const core.Box(
          key: 'panel',
          heightFraction: core.BoxFraction.viewport(1, minus: 192),
        ),
        const Size(800, 600),
      );

      expect(sizeOf(tester, 'panel').height, 408);
    });

    testWidgets('follows the window when it changes', (tester) async {
      await pumpOn(
        tester,
        const core.Box(
          key: 'panel',
          heightFraction: core.BoxFraction.viewport(0.5),
        ),
        const Size(800, 600),
      );

      expect(sizeOf(tester, 'panel').height, 300);

      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      expect(
        sizeOf(tester, 'panel').height,
        450,
        reason:
            'a share of the window is read from the window, not from a parent',
      );
    });

    testWidgets('is a length of nothing on a window shorter than the inset', (
      tester,
    ) async {
      // `max(0px, calc(100dvh - 900px))` on the web: a negative length is not a size, and both
      // targets floor it rather than letting one of them draw a box that is not there.
      await pumpOn(
        tester,
        const core.Box(
          key: 'panel',
          heightFraction: core.BoxFraction.viewport(1, minus: 900),
        ),
        const Size(800, 600),
      );

      expect(sizeOf(tester, 'panel').height, 0);
    });

    testWidgets('mixes with a share of the parent on the other axis', (
      tester,
    ) async {
      // One axis measured against the window and the other against the box around it: the
      // parent's share is the one the layout pass has to answer, and the window's is not.
      await pumpOn(
        tester,
        const core.StackNode(
          width: 400,
          height: 400,
          children: <core.UINode>[
            core.Box(
              key: 'panel',
              widthFraction: core.BoxFraction.parent(0.5),
              heightFraction: core.BoxFraction.viewport(1, minus: 300),
            ),
          ],
        ),
        const Size(800, 600),
      );

      expect(sizeOf(tester, 'panel'), const Size(200, 300));
    });
  });

  group('a share of the parent', () {
    testWidgets('is the share it states of the box that offers it', (
      tester,
    ) async {
      await pumpOn(
        tester,
        const core.StackNode(
          width: 400,
          height: 400,
          children: <core.UINode>[
            core.Box(
              key: 'half',
              widthFraction: core.BoxFraction.parent(0.5),
              heightFraction: core.BoxFraction.parent(0.25),
            ),
          ],
        ),
        const Size(800, 600),
      );

      expect(sizeOf(tester, 'half'), const Size(200, 100));
    });
  });
}
