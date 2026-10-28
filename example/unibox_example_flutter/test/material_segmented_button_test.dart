import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart';
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
                  MaterialSegment(label: TextNode('List')),
                  MaterialSegment(label: TextNode('Grid')),
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
}
