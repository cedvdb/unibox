import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A screen whose app bar collapses is a store over a body that reports its scroll, so the check
/// belongs on a real widget: the model can say the height is a number, and only a scroll can say
/// whether the number ever changes.
void main() {
  testWidgets('gives the app bar its height back as the body scrolls', (
    WidgetTester tester,
  ) async {
    // The demo states Material's roles, so it is drawn in the example's palette, which is the
    // theme that answers for them.
    await tester.pumpWidget(
      MaterialApp(
        home: UniboxThemeScope(
          theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 460,
                child: renderFlutter(CollapsingAppBarDemo()),
              ),
            ),
          ),
        ),
      ),
    );

    /// The bar is the pinned box the title is drawn in: the band, not the box padding it.
    Finder bar() => find.ancestor(
      of: find.text('Apartments'),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is FlutterBox && widget.box.pin != null,
      ),
    );
    Size barSize() => tester.getSize(bar());
    double barTop() => tester.getTopLeft(bar()).dy;

    expect(barSize().height, MaterialLargeAppBar.largeHeight);
    final double top = barTop();

    // A pull of more than the range the collapse runs over: the bar is as small as it goes.
    await tester.drag(find.text('Garden loft'), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(
      barSize().height,
      lessThan(MaterialLargeAppBar.largeHeight),
      reason: 'the height the store drives is the height the bar is drawn at',
    );
    expect(barSize().height, MaterialAppBar.topHeight);
    expect(
      barTop(),
      top,
      reason: 'a bar that pins stays at the top of the box that scrolls it',
    );
    // And it is still there to press: what is left of the bar keeps the surface it had.
    expect(find.text('Apartments'), findsOneWidget);
  });
}
