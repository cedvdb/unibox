import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// A stack is a layer, so a box can wrap one and clip it. The web renderer draws
/// that shape already; the Flutter one used to refuse it, because a flex hands its
/// children an unbounded main axis and a stack cannot be laid out in one.
void main() {
  testWidgets('lays a stack out inside a box that clips it', (
    WidgetTester tester,
  ) async {
    await pumpNode(
      tester,
      core.Box(
        width: 200,
        height: 100,
        overflow: core.Overflow.hidden,
        borderRadius: 12,
        children: <core.UINode>[
          core.StackNode(
            // A layer states the rectangle it places its children in: the box bounds it,
            // and a browser would otherwise collapse the stack to nothing.
            width: double.infinity,
            height: double.infinity,
            children: <core.UINode>[
              core.PositionedNode(
                left: 10,
                top: 20,
                child: const core.Box(width: 30, height: 30),
              ),
            ],
          ),
        ],
      ),
    );

    // The layer takes the box's own size, which is what makes the clip mean
    // something: 200x100, with the child where it was placed.
    expect(tester.getSize(find.byType(Stack)), const Size(200, 100));
    expect(
      tester.getTopLeft(find.byType(Stack)),
      tester.getTopLeft(find.byKey(nodeKey)),
    );
    expect(
      tester.getTopLeft(find.byType(ClipRRect)),
      tester.getTopLeft(find.byKey(nodeKey)),
    );
    expect(tester.getSize(find.byType(ClipRRect)), const Size(200, 100));
  });

  /// A layer whose content is smaller than the box still sits where the box says.
  ///
  /// On the web the stack is the flex's one flow child, so the pair places the
  /// stack itself and its cell takes the size of what it holds. A stack that fills
  /// the box has to place its children instead, or a label the browser centres — the
  /// one inside a segmented button's pill, say — arrives at the top in Flutter.
  testWidgets('places a layer by the alignment of the box around it', (
    WidgetTester tester,
  ) async {
    await pumpNode(
      tester,
      core.Box(
        width: 200,
        height: 100,
        mainAlign: core.MainAlign.center,
        crossAlign: core.CrossAlign.center,
        children: <core.UINode>[
          core.StackNode(
            children: <core.UINode>[const core.Box(width: 30, height: 20)],
          ),
        ],
      ),
    );

    final Finder layer = find.byType(Stack);
    final Finder content = find.descendant(
      of: layer,
      matching: find.byType(FlutterBox),
    );

    // The layer keeps the box, and what it holds is what the pair centres:
    // (200 - 30) / 2 across and (100 - 20) / 2 down from the box's corner.
    final Offset corner = tester.getTopLeft(find.byKey(nodeKey));

    expect(tester.getSize(layer), const Size(200, 100));
    expect(tester.getTopLeft(content), corner + const Offset(85, 40));
  });

  testWidgets('reads the pair along the row of a horizontal box', (
    WidgetTester tester,
  ) async {
    await pumpNode(
      tester,
      core.Box(
        width: 200,
        height: 100,
        direction: core.Axis.horizontal,
        mainAlign: core.MainAlign.end,
        crossAlign: core.CrossAlign.center,
        children: <core.UINode>[
          core.StackNode(
            children: <core.UINode>[const core.Box(width: 30, height: 20)],
          ),
        ],
      ),
    );

    // A row lays the main axis across, so `end` is the right edge and the cross
    // axis is centred: 200 - 30 across, (100 - 20) / 2 down from the box's corner.
    expect(
      tester.getTopLeft(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(FlutterBox),
        ),
      ),
      tester.getTopLeft(find.byKey(nodeKey)) + const Offset(170, 40),
    );
  });
}
