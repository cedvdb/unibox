import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// The close of a filter chip is a 18 pixel target of its own inside the pill.
///
/// It is a `MaterialInkWell` with no children of its own but the glyph, so where the
/// glyph lands is the alignment of that well — and the well is a box around a layer.
/// The browser centres it; Flutter put it in the top start corner until the stack
/// learned to read the box's pair.
void main() {
  testWidgets('centres the close glyph in its target', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(
              MaterialChip(
                label: const TextNode('Two rooms'),
                selected: true,
                trailing: const TextNode('×', fontSize: 10),
                onRemove: () {},
                onTap: () {},
              ),
              theme: MaterialPalette.lightTheme,
            ),
          ),
        ),
      ),
    );

    final Rect target = tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FlutterBox &&
            widget.box.width == 18 &&
            widget.box.height == 18,
      ),
    );
    final Rect close = tester.getRect(find.text('×'));

    expect(target.size, const Size(18, 18));
    expect(close.center.dx, closeTo(target.center.dx, 0.5));
    expect(close.center.dy, closeTo(target.center.dy, 0.5));
  });

  testWidgets('announces the close as the chip it removes', (
    WidgetTester tester,
  ) async {
    // `aria-label` on the web, a label in the semantics tree here: one token, two
    // targets. A row of applied filters used to read as the same "Remove" eleven times,
    // which a reader cannot tell apart.
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(
              MaterialChip(
                label: const TextNode('Garden'),
                trailing: const TextNode('×', fontSize: 10),
                onRemove: () {},
                removeSemanticsLabel: 'Remove Garden',
              ),
              theme: MaterialPalette.lightTheme,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Remove Garden'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove'), findsNothing);

    handle.dispose();
  });
}
