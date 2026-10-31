import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// The [Stack] widget rendered by the harness.
Stack renderedStack(WidgetTester tester) =>
    tester.widget<Stack>(inNode(find.byType(Stack)));

/// The top left corner of the rendered stack in global coordinates.
Offset stackOrigin(WidgetTester tester) =>
    tester.getTopLeft(inNode(find.byType(Stack)));

void main() {
  group('StackNode', () {
    testWidgets('layers its children in paint order', (tester) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 100,
          children: [
            core.Box(
              width: 100,
              height: 100,
              backgroundColor: core.BoxColor.black,
            ),
            core.Box(
              width: 20,
              height: 20,
              backgroundColor: core.BoxColor.white,
            ),
          ],
        ),
      );

      expect(renderedStack(tester).children, hasLength(2));
      expect(inNode(find.byType(DecoratedBox)), findsNWidgets(2));
    });

    testWidgets('sizes the stack from its dimensions', (tester) async {
      await pumpNode(tester, const core.StackNode(width: 100, height: 60));

      expect(tester.getSize(inNode(find.byType(Stack))), const Size(100, 60));
    });

    testWidgets('sizes to its largest child without dimensions', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.StackNode(
          children: [
            core.Box(width: 40, height: 30),
            core.Box(width: 10, height: 70),
          ],
        ),
      );

      expect(tester.getSize(inNode(find.byType(Stack))), const Size(40, 70));
    });

    testWidgets('fills the available width for an infinite width', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.StackNode(width: double.infinity, height: 50),
      );

      expect(tester.getSize(inNode(find.byType(Stack))), const Size(800, 50));
    });

    testWidgets('does not clip its content', (tester) async {
      await pumpNode(tester, const core.StackNode(width: 10, height: 10));

      expect(renderedStack(tester).clipBehavior, Clip.none);
    });

    testWidgets('places a positioned child at its offsets', (tester) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 120,
          height: 120,
          children: [
            core.PositionedNode(
              top: 10,
              left: 20,
              child: core.Box(
                width: 30,
                height: 30,
                backgroundColor: core.BoxColor.black,
              ),
            ),
          ],
        ),
      );

      expect(
        tester.getTopLeft(inNode(find.byType(Positioned))),
        stackOrigin(tester) + const Offset(20, 10),
      );
      expect(
        tester.getSize(inNode(find.byType(Positioned))),
        const Size(30, 30),
      );
    });

    testWidgets('anchors a positioned child to the right and bottom', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 120,
          height: 100,
          children: [
            core.PositionedNode(
              right: 10,
              bottom: 5,
              child: core.Box(
                width: 20,
                height: 20,
                backgroundColor: core.BoxColor.black,
              ),
            ),
          ],
        ),
      );

      expect(
        tester.getTopLeft(inNode(find.byType(Positioned))),
        stackOrigin(tester) + const Offset(90, 75),
      );
    });

    testWidgets('stretches a positioned child across opposite edges', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 100,
          children: [
            core.PositionedNode(
              top: 10,
              left: 10,
              right: 10,
              bottom: 10,
              child: core.Box(backgroundColor: core.BoxColor.black),
            ),
          ],
        ),
      );

      expect(
        tester.getSize(inNode(find.byType(Positioned))),
        const Size(80, 80),
      );
    });

    testWidgets('keeps an unpositioned child in the top start corner', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 100,
          children: [
            core.PositionedNode(
              child: core.Box(
                width: 20,
                height: 20,
                backgroundColor: core.BoxColor.black,
              ),
            ),
          ],
        ),
      );

      expect(inNode(find.byType(Positioned)), findsNothing);
      expect(
        tester.getTopLeft(inNode(find.byType(DecoratedBox))),
        stackOrigin(tester),
      );
    });

    testWidgets('renders node children of the stack', (tester) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 120,
          height: 40,
          children: [
            core.Box(
              width: 120,
              height: 40,
              backgroundColor: core.BoxColor.black,
            ),
            core.PositionedNode(
              top: 4,
              left: 4,
              child: core.TextNode('Overlay'),
            ),
          ],
        ),
      );

      expect(find.text('Overlay'), findsOneWidget);
    });

    testWidgets('nests inside a box next to other children', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          gap: 8,
          children: [
            core.StackNode(
              width: 24,
              height: 24,
              children: [
                core.PositionedNode(
                  top: 2,
                  left: 2,
                  child: core.Box(
                    width: 8,
                    height: 8,
                    backgroundColor: core.BoxColor.black,
                  ),
                ),
              ],
            ),
            core.TextNode('Badge'),
          ],
        ),
      );

      expect(inNode(find.byType(Stack)), findsOneWidget);
      expect(find.text('Badge'), findsOneWidget);
    });
  });

  group('PositionedNode', () {
    testWidgets('renders its child when used outside a stack', (tester) async {
      await pumpNode(
        tester,
        const core.PositionedNode(
          top: 10,
          left: 10,
          child: core.TextNode('Loose'),
        ),
      );

      expect(find.text('Loose'), findsOneWidget);
      expect(find.byType(Positioned), findsNothing);
    });

    testWidgets('puts an aligned child at the bottom centre of the stack', (
      WidgetTester tester,
    ) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 300,
          height: 200,
          children: <core.UINode>[
            core.Box(width: double.infinity, height: double.infinity),
            core.PositionedNode(
              alignment: core.BoxAlignment.bottomCenter,
              child: core.Box(
                width: 120,
                height: 56,
                margin: core.BoxSpacing.all(16),
                children: <core.UINode>[core.TextNode('Open the map')],
              ),
            ),
          ],
        ),
      );

      final Rect stack = tester.getRect(find.byType(Stack));
      final Rect button = tester.getRect(
        find.ancestor(
          of: find.text('Open the map'),
          matching: find.byType(FlutterBox),
        ),
      );

      // Centred across, against the bottom edge: the margin belongs to the box the
      // test measures, so the edge it reaches is the stack's own.
      expect(button.center.dx, moreOrLessEquals(stack.center.dx, epsilon: 0.5));
      expect(button.bottom, moreOrLessEquals(stack.bottom, epsilon: 0.5));
      expect(
        button.top,
        lessThan(stack.bottom),
        reason: 'the child is at the bottom, not filling the stack',
      );
    });
    testWidgets('puts an aligned child at the reading end of a stack', (
      tester,
    ) async {
      // `centerEnd` names where the line ends and not the right edge: the browser's
      // `justify-content: end` follows the writing direction, so the app has to follow it
      // too, or a page translated into Arabic mirrors the row and not the control floating
      // over it.
      await pumpNode(tester, _alignedEndPatch(null));

      expect(
        _patchRect(tester).right,
        moreOrLessEquals(
          tester.getRect(find.byType(Stack)).right,
          epsilon: 0.5,
        ),
      );

      await pumpNode(tester, _alignedEndPatch(core.WritingDirection.rtl));

      expect(
        _patchRect(tester).left,
        moreOrLessEquals(tester.getRect(find.byType(Stack)).left, epsilon: 0.5),
      );
    });
  });
}

/// A layer with one patch aligned to the reading end of its middle row, written in
/// [writingDirection].
core.Box _alignedEndPatch(core.WritingDirection? writingDirection) => core.Box(
  writingDirection: writingDirection,
  width: 300,
  height: 200,
  children: <core.UINode>[
    const core.StackNode(
      children: <core.UINode>[
        core.Box(width: double.infinity, height: double.infinity),
        core.PositionedNode(
          alignment: core.BoxAlignment.centerEnd,
          child: core.Box(key: 'patch', width: 40, height: 40),
        ),
      ],
    ),
  ],
);

/// Where that patch landed.
Rect _patchRect(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey<Object>('patch')));
