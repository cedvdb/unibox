import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

Size sizeOf(WidgetTester tester, String key) =>
    tester.getSize(find.byKey(ValueKey<Object>(key)));

/// A box that scrolls down, so its child is laid out with no end on the vertical axis —
/// which is what a column on a scrolling page is.
core.Box scrollingColumn(List<core.UINode> children) => core.Box(
  key: 'viewport',
  width: 300,
  height: 400,
  overflow: core.Overflow.scroll,
  children: children,
);

void main() {
  group('a stretch inside a line with no end', () {
    testWidgets('makes the line as tall as its tallest child', (tester) async {
      // The results column beside a map panel: the row is inside a column that scrolls, so
      // nothing above it states a height, and CSS gives the row the height of its tallest
      // item — `align-items: stretch` against a content-sized line. Flutter used to refuse
      // the constraint outright.
      await pumpNode(
        tester,
        scrollingColumn(<core.UINode>[
          core.Box(
            key: 'row',
            direction: core.Axis.horizontal,
            crossAlign: core.CrossAlign.stretch,
            gap: 8,
            children: const <core.UINode>[
              core.Box(key: 'cards', width: 100, height: 300),
              core.Box(key: 'map', width: 100),
            ],
          ),
        ]),
      );

      expect(sizeOf(tester, 'row').height, 300);
      expect(
        sizeOf(tester, 'map').height,
        300,
        reason: 'a child that states no height fills the line it is stretched across',
      );
    });

    testWidgets('leaves a child that states its own height alone', (
      tester,
    ) async {
      // What `align-items: stretch` does to an item whose cross size is not `auto`: nothing.
      await pumpNode(
        tester,
        scrollingColumn(<core.UINode>[
          core.Box(
            key: 'row',
            direction: core.Axis.horizontal,
            crossAlign: core.CrossAlign.stretch,
            children: const <core.UINode>[
              core.Box(key: 'cards', width: 100, height: 300),
              core.Box(key: 'badge', width: 40, height: 120),
            ],
          ),
        ]),
      );

      expect(sizeOf(tester, 'row').height, 300);
      expect(sizeOf(tester, 'badge').height, 120);
    });

    testWidgets('still fills a line that was given an end', (tester) async {
      // The common case, and the one that always worked: a row in a box that states its
      // height. It is laid out once — the measuring pass only happens when there is no end
      // to reach.
      await pumpNode(
        tester,
        const core.Box(
          width: 300,
          height: 200,
          direction: core.Axis.horizontal,
          crossAlign: core.CrossAlign.stretch,
          children: <core.UINode>[
            core.Box(key: 'fixed', width: 10, height: 80),
            core.Box(key: 'filled', width: 10),
          ],
        ),
      );

      expect(sizeOf(tester, 'fixed').height, 80);
      expect(sizeOf(tester, 'filled').height, 200);
    });
  });
}
