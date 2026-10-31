import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

/// What a host adds to a scroll view, and what a box refuses to keep.
void main() {
  group('a box that scrolls', () {
    testWidgets('paints no overscroll glow, which is the host\'s chrome', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: renderFlutter(
                  const core.Box(
                    key: 'viewport',
                    height: 200,
                    overflow: core.Overflow.scroll,
                    children: <core.UINode>[core.Box(height: 400)],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // A Material application wraps every scroll view it did not build in a
      // `GlowingOverscrollIndicator`. A box states what it looks like, and a browser paints
      // nothing when a panel is pulled past its end, so this one is left out.
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);

      await tester.drag(
        find.byKey(const ValueKey<Object>('viewport')),
        const Offset(0, 120),
      );
      await tester.pump();

      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
