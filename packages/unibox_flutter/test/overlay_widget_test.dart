import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

/// The number of times an overlay asked to be dismissed.
int dismissals = 0;

void _dismiss() => dismissals++;

/// Renders [tree] inside a Material app, which provides the root overlay.
Future<void> pumpOverlay(
  WidgetTester tester,
  core.UINode tree, {
  FocusNode? outside,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: Column(
          children: <Widget>[
            if (outside != null)
              Focus(
                focusNode: outside,
                autofocus: true,
                child: const SizedBox(width: 10, height: 10),
              ),
            renderFlutter(tree),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

core.UINode overlay({
  core.OverlayAlignment alignment = core.OverlayAlignment.center,
  bool barrierDismissible = true,
  bool withDismiss = true,
  core.BoxColor barrierColor = core.OverlayNode.defaultBarrierColor,
  String text = 'Modal body',
}) => core.OverlayNode(
  alignment: alignment,
  barrierDismissible: barrierDismissible,
  barrierColor: barrierColor,
  onDismiss: withDismiss ? _dismiss : null,
  child: core.Box(children: <core.UINode>[core.TextNode(text)]),
);

/// An overlay whose content is taller than the window the test pumps it in.
core.UINode tall() => core.OverlayNode(
  onDismiss: _dismiss,
  child: const core.Box(
    width: 280,
    height: 900,
    backgroundColor: core.BoxColor.black,
  ),
);

void main() {
  setUp(() => dismissals = 0);

  group('FlutterOverlay', () {
    testWidgets('shows its content above a barrier of its own colour', (
      tester,
    ) async {
      await pumpOverlay(tester, overlay());

      expect(find.text('Modal body'), findsOneWidget);
      expect(
        tester
            .widgetList<ModalBarrier>(find.byType(ModalBarrier))
            .any((ModalBarrier b) => b.color == const Color(0x52000000)),
        isTrue,
      );
    });

    testWidgets('dismisses on Escape', (tester) async {
      await pumpOverlay(tester, overlay());

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(dismissals, 1);
    });

    testWidgets('dismisses when the barrier is pressed', (tester) async {
      await pumpOverlay(tester, overlay());

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();

      expect(dismissals, 1);
    });

    testWidgets('keeps an inert barrier when it is not dismissible', (
      tester,
    ) async {
      await pumpOverlay(tester, overlay(barrierDismissible: false));

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();

      expect(dismissals, 0);
      expect(find.text('Modal body'), findsOneWidget);
    });

    testWidgets('has nothing to dismiss without onDismiss', (tester) async {
      await pumpOverlay(tester, overlay(withDismiss: false));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();

      expect(find.text('Modal body'), findsOneWidget);
    });

    testWidgets('does not dismiss when the content is pressed', (tester) async {
      await pumpOverlay(tester, overlay());

      await tester.tap(find.text('Modal body'));
      await tester.pump();

      expect(dismissals, 0);
    });

    testWidgets('places the content where the node asks', (tester) async {
      await pumpOverlay(tester, overlay(alignment: core.OverlayAlignment.top));
      expect(tester.getCenter(find.text('Modal body')).dy, lessThan(300));

      await pumpOverlay(
        tester,
        overlay(alignment: core.OverlayAlignment.bottom),
      );
      expect(tester.getCenter(find.text('Modal body')).dy, greaterThan(300));

      await pumpOverlay(tester, overlay());
      expect(tester.getCenter(find.text('Modal body')).dy, closeTo(300, 1));
    });

    testWidgets('scrolls content taller than the window instead of growing', (
      tester,
    ) async {
      // The drift this pins. A dialog is centred in a box the size of the window, and an
      // item taller than the box it is centred in used to grow past it: the same card came
      // out as tall as its content here and as tall as the window on the web, so the two
      // renderings disagreed about the height of one node. The layer bounds the content and
      // the scroll reaches the rest, which is what `overflow: auto` does on the CSS side.
      await pumpOverlay(tester, tall());

      expect(
        tester.getSize(find.byType(SingleChildScrollView)).height,
        600,
        reason:
            'the room is the window, and the content cannot be taller than it',
      );
      expect(
        tester.getTopLeft(find.byType(FlutterBox)).dy,
        0,
        reason:
            'the top of a dialog too tall for the window is on screen: centring it past '
            'the start of its room would hide the part no scroll can reach',
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pump();

      expect(tester.getTopLeft(find.byType(FlutterBox)).dy, lessThan(0));
    });

    testWidgets('keeps the barrier reachable beside a long dialog', (
      tester,
    ) async {
      // The scrim rides inside the scroll view, because a scroll view that covered the
      // layer would take the press itself. What is left beside a dialog is still the
      // barrier, whatever the content is.
      await pumpOverlay(tester, tall());

      await tester.tapAt(const Offset(5, 590));
      await tester.pump();

      expect(dismissals, 1);
    });

    testWidgets('moves focus in and back to where it was', (tester) async {
      final FocusNode outside = FocusNode();
      addTearDown(outside.dispose);

      await pumpOverlay(tester, overlay(), outside: outside);
      expect(outside.hasPrimaryFocus, isFalse);

      await pumpOverlay(
        tester,
        const core.Box(children: <core.UINode>[core.TextNode('Page')]),
        outside: outside,
      );

      expect(outside.hasPrimaryFocus, isTrue);
    });
  });
}
