import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A segmented button is a box around a well, and a well is a box around a layer.
///
/// The label therefore sits where the box's alignment says, not at the top of the
/// layer: the browser centres the layer in the pill, and Flutter put the label at the
/// top of it until the stack learned to read the pair. Two targets, one pill.
void main() {
  testWidgets('centres every label in its segment, like the browser', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(
              MaterialSegmentedButton(
                width: 216,
                showSelectedIcon: false,
                segments: const <MaterialSegment>[
                  MaterialSegment(label: core.TextNode('List')),
                  MaterialSegment(label: core.TextNode('Grid')),
                ],
                selected: 0,
                onSelect: (int index) {},
              ),
              theme: MaterialPalette.lightTheme,
            ),
          ),
        ),
      ),
    );

    final Rect control = tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FlutterBox && widget.box is MaterialSegmentedButton,
      ),
    );
    final Rect list = tester.getRect(find.text('List'));
    final Rect grid = tester.getRect(find.text('Grid'));

    expect(
      control.size,
      const Size(216, MaterialSegmentedButton.controlHeight),
    );

    // A 40 pixel pill with a 20 pixel label line: ten above and ten below, which is
    // where `justify-content: center` puts it on the web.
    expect(list.center.dy, closeTo(control.center.dy, 0.5));
    expect(grid.center.dy, closeTo(control.center.dy, 0.5));

    // Equal shares either side of the 1 pixel divider: (216 - 1) / 2 = 107.5 each.
    expect(list.center.dx, closeTo(control.left + 53.75, 0.5));
    expect(grid.center.dx, closeTo(control.left + 162.25, 0.5));
  });

  testWidgets('hugs its labels when it is given no width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(
              // The consumer's shape: a control with no width of its own, in a row
              // that scrolls along the axis the control would have filled. A segment
              // that asked for `double.infinity` here is a constraint with no bound
              // behind it, which Flutter refuses before it draws anything.
              core.Box(
                direction: core.Axis.horizontal,
                overflow: core.Overflow.scroll,
                children: <core.UINode>[
                  MaterialSegmentedButton(
                    showSelectedIcon: false,
                    segments: const <MaterialSegment>[
                      MaterialSegment(label: core.TextNode('List')),
                      MaterialSegment(label: core.TextNode('Grid')),
                    ],
                    selected: 0,
                    onSelect: (int index) {},
                  ),
                ],
              ),
              theme: MaterialPalette.lightTheme,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final Rect control = tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FlutterBox && widget.box is MaterialSegmentedButton,
      ),
    );
    final Rect list = tester.getRect(find.text('List'));
    final Rect grid = tester.getRect(find.text('Grid'));

    expect(control.height, MaterialSegmentedButton.controlHeight);

    // A pill of the labels rather than of the row: the control is exactly the two
    // labels, the 12 pixels of room each side of them and the 1 pixel rule between —
    // nothing was stretched to fill a width that was never there.
    expect(control.left, closeTo(list.left - 12, 0.5));
    expect(control.right, closeTo(grid.right + 12, 0.5));
    expect(list.center.dy, closeTo(control.center.dy, 0.5));
    expect(grid.center.dy, closeTo(control.center.dy, 0.5));

    // Each segment hugs its own label, so the divider sits between them rather than
    // half way through a share nobody asked for.
    expect(grid.left, greaterThan(list.right + 12));
  });
}
