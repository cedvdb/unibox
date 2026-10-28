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
}
