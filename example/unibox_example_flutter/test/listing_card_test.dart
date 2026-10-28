import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A card's rows reach its edges.
///
/// The name and the badge sit at opposite ends of the first row, the summary and the
/// rent at opposite ends of the last one. That is `mainAlign: spaceBetween` in a box
/// that fills the card, which is the part a browser cannot work out by itself: a
/// `width: 100%` inside a column that hugs its content resolves to `auto`, so the rows
/// stopped half way across the card on the web until the card said that what it holds
/// stretches. This measures the result rather than the declaration.
void main() {
  testWidgets('a listing card puts the name and the rent at its edges', (
    WidgetTester tester,
  ) async {
    // A wide window, the way the harness pumps the app: the test font is wider
    // than the real one, and a card squeezed by it would overflow before the
    // measurement meant anything.
    tester.view.physicalSize = const Size(2400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: renderFlutter(
          buildApartmentsPage(),
          theme: MaterialPalette.lightTheme,
        ),
      ),
    );

    final Finder card = find
        .ancestor(
          of: find.text('Via Bellavista 12'),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is FlutterBox && widget.box is MaterialCard,
          ),
        )
        .first;

    Rect inside(String text) => tester.getRect(
      find.descendant(of: card, matching: find.text(text)).first,
    );

    final Rect cardRect = tester.getRect(card);
    final Rect badge = inside('New');
    final Rect price = inside('€1850');
    final Rect summary = inside('3 rooms · 84 m²');

    // The padding the card's content carries, so both rows end where the text does.
    const double inset = 14;
    final double right = cardRect.right - inset;
    final double left = cardRect.left + inset;

    expect(badge.right, moreOrLessEquals(right, epsilon: 1));
    expect(price.right, moreOrLessEquals(right, epsilon: 1));
    expect(summary.left, moreOrLessEquals(left, epsilon: 1));
    expect(
      summary.right,
      lessThan(price.left),
      reason: 'the two ends of the row are apart, not adjacent',
    );
  });
}
