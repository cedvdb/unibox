import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_testing/unibox_testing.dart';

/// The presentation this renderer gave the root overlay, read out of the widgets
/// it built.
OverlayAppearance appearanceOf(WidgetTester tester) {
  // The route below the page has a barrier of its own, with no colour; the
  // overlay's barrier is the one the node paints.
  final ModalBarrier barrier = tester.widget<ModalBarrier>(
    find.byWidgetPredicate(
      (Widget widget) => widget is ModalBarrier && widget.color != null,
    ),
  );
  // The nearest `Align` above the content is the one the node placed it with.
  final Align align = tester.widget<Align>(
    find.ancestor(of: find.text('Overlay'), matching: find.byType(Align)).first,
  );
  // A content that does not fit is reached by scrolling, which is what the layer does
  // with the room it has: the scroll view is between the layer and the content.
  final bool scrolls = find
      .ancestor(
        of: find.text('Overlay'),
        matching: find.byType(SingleChildScrollView),
      )
      .evaluate()
      .isNotEmpty;

  return OverlayAppearance(
    barrierColor: core.BoxColor(barrier.color!.toARGB32()),
    alignment: switch (align.alignment) {
      Alignment.topCenter => core.OverlayAlignment.top,
      Alignment.bottomCenter => core.OverlayAlignment.bottom,
      _ => core.OverlayAlignment.center,
    },
    scrolls: scrolls,
  );
}

void main() {
  testWidgets('every overlay case is presented as expected', (tester) async {
    for (final OverlayCase overlayCase in overlayCases) {
      await tester.pumpWidget(
        MaterialApp(home: Material(child: renderFlutter(overlayCase.node))),
      );
      await tester.pump();

      expect(
        appearanceOf(tester).differencesFrom(overlayCase.expected),
        isEmpty,
        reason: overlayCase.description,
      );
    }
  });
}
