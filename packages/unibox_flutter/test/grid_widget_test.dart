import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// A grid with the example's rule and one keyed card per [items].
core.GridNode grid({int items = 6}) {
  return core.GridNode(
    minItemWidth: 280,
    maxColumns: 3,
    gap: 16,
    children: <core.UINode>[
      for (int index = 0; index < items; index++)
        core.Box(key: index, height: 40),
    ],
  );
}

Rect card(WidgetTester tester, int index) {
  return tester.getRect(find.byKey(ValueKey<Object>(index)));
}

Future<void> pumpAt(WidgetTester tester, core.UINode node, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpNode(tester, node);
}

void main() {
  group('GridNode layout', () {
    testWidgets('reflows 1, 2 and 3 columns with one gutter', (tester) async {
      // The same numbers the CSS arithmetic gives, and the 250 row is narrower
      // than a column: the grid clamps to one column of the full width.
      for (final (double width, int columns, double cell) sample
          in <(double, int, double)>[
            (250, 1, 250),
            (375, 1, 375),
            (600, 2, 292),
            (900, 3, 289.3333),
            (1280, 3, 416),
          ]) {
        await pumpAt(tester, grid(), sample.$1);

        final Rect first = card(tester, 0);
        final int inFirstRow = <int>[
          0,
          1,
          2,
        ].where((int index) => card(tester, index).top == first.top).length;

        expect(
          first.width,
          closeTo(sample.$3, 0.01),
          reason: 'width ${sample.$1}',
        );
        expect(inFirstRow, sample.$2, reason: 'width ${sample.$1}');

        if (sample.$2 > 1) {
          expect(
            card(tester, 1).left - first.right,
            closeTo(16, 0.01),
            reason: 'gutter at width ${sample.$1}',
          );
        }
      }
    });

    testWidgets('leaves the empty tracks of a short last row', (tester) async {
      // Four cards on a three-track grid: the second row holds one card and two
      // empty tracks, so the card keeps its width instead of stretching over
      // them, which is what `auto-fill` does in CSS.
      await pumpAt(tester, grid(items: 4), 900);

      final double cell = card(tester, 0).width;
      final Rect fourth = card(tester, 3);

      expect(fourth.left, closeTo(0, 0.01));
      expect(fourth.width, closeTo(cell, 0.01));
      expect(fourth.top, closeTo(card(tester, 0).bottom + 16, 0.01));
    });

    testWidgets('lays out as one column at its minimum without a width', (
      tester,
    ) async {
      // A grid in a row that lets its children be as wide as they like has no
      // width to divide, and `columnsFor` answers one column of minItemWidth.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: <Widget>[renderFlutter(grid())]),
        ),
      );

      expect(card(tester, 0).width, 280);
      expect(card(tester, 1).top, greaterThan(card(tester, 0).top));
    });

    testWidgets('lays a spanning card across the tracks it names', (
      tester,
    ) async {
      await pumpAt(
        tester,
        core.GridNode(
          minItemWidth: 280,
          maxColumns: 3,
          gap: 16,
          children: <core.UINode>[
            core.Box(key: 0, height: 40),
            core.Box(key: 1, height: 40, gridSpan: 2),
            core.Box(key: 2, height: 40),
          ],
        ),
        900,
      );

      final double cell = card(tester, 0).width;
      final Rect banner = card(tester, 1);

      // Two tracks and the gutter between them, in the row the first card is on.
      expect(banner.width, closeTo(2 * cell + 16, 0.01));
      expect(banner.left, closeTo(cell + 16, 0.01));
      expect(banner.top, closeTo(card(tester, 0).top, 0.01));
    });

    testWidgets('starts a new row when a span does not fit', (tester) async {
      await pumpAt(
        tester,
        core.GridNode(
          minItemWidth: 280,
          maxColumns: 2,
          gap: 16,
          children: <core.UINode>[
            core.Box(key: 0, height: 40),
            core.Box(key: 1, height: 40, gridSpan: 2),
            core.Box(key: 2, height: 40),
          ],
        ),
        600,
      );

      final Rect first = card(tester, 0);
      final Rect banner = card(tester, 1);

      // One track is left in the first row and the banner needs two, so it takes
      // the whole of the next one — which is what `auto-flow: row` does, and why
      // the track it did not fill stays empty rather than being stretched.
      expect(banner.top, closeTo(first.bottom + 16, 0.01));
      expect(banner.width, closeTo(first.width * 2 + 16, 0.01));
      expect(card(tester, 2).top, greaterThan(banner.bottom));
    });

    testWidgets('keeps a zero gap out of the layout', (tester) async {
      await pumpAt(
        tester,
        core.GridNode(
          minItemWidth: 100,
          gap: 0,
          children: <core.UINode>[
            for (int index = 0; index < 3; index++)
              core.Box(key: index, height: 10),
          ],
        ),
        300,
      );

      expect(card(tester, 0).width, 100);
      expect(card(tester, 1).left, 100);
      expect(card(tester, 2).left, 200);
    });
  });
}
