import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

/// Where a box that scrolls starts, when a page told it where a reader was.
void main() {
  Widget page(List<core.BoxScrollOffset> offsets, {required String key}) {
    return UniboxScrollScope(
      offsets: offsets,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: core.Box(
          key: key,
          overflow: core.Overflow.scroll,
          children: <core.UINode>[
            for (int i = 0; i < 100; i++) core.TextNode('Row $i'),
          ],
        ).toWidget(),
      ),
    );
  }

  testWidgets('a box that scrolls opens where the page recorded it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      page(const <core.BoxScrollOffset>[
        core.BoxScrollOffset(key: 'listings', dy: 240),
      ], key: 'listings'),
    );

    final Scrollable scrollable = tester.widget<Scrollable>(
      find.byType(Scrollable),
    );

    expect(scrollable.controller?.initialScrollOffset, 240);
  });

  testWidgets('a box with no record starts at the top', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(page(const <core.BoxScrollOffset>[], key: 'a'));

    expect(
      tester
          .widget<Scrollable>(find.byType(Scrollable))
          .controller
          ?.initialScrollOffset,
      0,
    );
  });

  testWidgets('a record for another key is not used', (
    WidgetTester tester,
  ) async {
    // The position belongs to the region it was recorded for: applying it to whichever box
    // happens to scroll would move the wrong list.
    await tester.pumpWidget(
      page(const <core.BoxScrollOffset>[
        core.BoxScrollOffset(key: 'listings', dy: 240),
      ], key: 'gallery'),
    );

    expect(
      tester
          .widget<Scrollable>(find.byType(Scrollable))
          .controller
          ?.initialScrollOffset,
      0,
    );
  });

  testWidgets('a box with no key cannot be found, so it starts at the top', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      UniboxScrollScope(
        offsets: const <core.BoxScrollOffset>[
          core.BoxScrollOffset(key: 'listings', dy: 240),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: const core.Box(
            overflow: core.Overflow.scroll,
            children: <core.UINode>[core.TextNode('Row')],
          ).toWidget(),
        ),
      ),
    );

    expect(
      tester
          .widget<Scrollable>(find.byType(Scrollable))
          .controller
          ?.initialScrollOffset,
      0,
    );
  });

  testWidgets(
    'a region keyed the way the example keys it starts where the page said',
    (WidgetTester tester) async {
      // The two halves only meet if the key in the tree is the key in the record: the document
      // writes `data-unibox-key`, and this is that value.
      await tester.pumpWidget(
        page(const <core.BoxScrollOffset>[
          core.BoxScrollOffset(key: 'listings', dy: 320),
        ], key: 'listings'),
      );

      expect(
        tester
            .widget<Scrollable>(find.byType(Scrollable))
            .controller
            ?.initialScrollOffset,
        320,
      );
    },
  );

  testWidgets('a rebuild does not move the reader back', (
    WidgetTester tester,
  ) async {
    // The record is an *initial* offset, read once: after that the region belongs to the
    // reader, and a rebuild that reset it would fight them.
    await tester.pumpWidget(
      page(const <core.BoxScrollOffset>[
        core.BoxScrollOffset(key: 'listings', dy: 240),
      ], key: 'listings'),
    );
    final ScrollController controller = tester
        .widget<Scrollable>(find.byType(Scrollable))
        .controller!;

    controller.jumpTo(40);
    await tester.pump();
    await tester.pumpWidget(
      page(const <core.BoxScrollOffset>[
        core.BoxScrollOffset(key: 'listings', dy: 240),
      ], key: 'listings'),
    );

    expect(controller.offset, 40);
  });

  _pageTests();
}

void _pageTests() {
  // A pager states *which* page it shows, and the renderer moves it when that changes.
  Widget pager(int page) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 120,
        height: 80,
        child: renderFlutter(
          core.Box(
            width: 120,
            height: 80,
            direction: core.Axis.horizontal,
            overflow: core.Overflow.scroll,
            snap: core.ScrollSnap.page,
            page: page,
            children: <core.UINode>[
              for (int index = 0; index < 3; index++)
                core.Box(
                  key: 'page-$index',
                  width: 120,
                  height: 80,
                  children: <core.UINode>[core.TextNode('$index')],
                ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('a pager slides to the page the tree names', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(pager(0));
    final ScrollController controller = tester
        .widget<Scrollable>(find.byType(Scrollable))
        .controller!;

    expect(controller.offset, 0);

    await tester.pumpWidget(pager(2));
    await tester.pumpAndSettle();

    // The extent of a page is the viewport's, and the box is one page wide.
    expect(controller.offset, 240);
  });

  testWidgets('a rebuild with the same page leaves the reader alone', (
    WidgetTester tester,
  ) async {
    // A page is a position, not a command: a publish that states the page it already shows must not
    // pull a reader's swipe back.
    await tester.pumpWidget(pager(1));
    await tester.pumpAndSettle();
    final ScrollController controller = tester
        .widget<Scrollable>(find.byType(Scrollable))
        .controller!;

    controller.jumpTo(150);
    await tester.pump();
    await tester.pumpWidget(pager(1));
    // One frame: the rebuild applied and nothing else. Settling would let the page physics snap to
    // the nearest page, which is the box doing its job rather than the rebuild moving the reader.
    await tester.pump();

    expect(controller.offset, 150);
  });
}
