import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// The catalogue is a tree, so it draws on both targets: the site is the one a reader sees, and
/// Flutter is the one an application gets. Nothing in the site's own tests makes the second true,
/// which is how a card that only laid out in a browser (a phone with a width inside a grid track,
/// a screen whose bar was as wide as its own words) stayed in the page, drawing nothing anywhere
/// but CSS.
void main() {
  testWidgets('draws the catalogue as widgets, at the width a page gives it', (
    WidgetTester tester,
  ) async {
    // A page, and tall enough for a catalogue: the sections lay out at their own heights, so the
    // test gives them the vertical room a document would scroll through.
    tester.view.physicalSize = const Size(1280, 24000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // The test font is an em square per glyph — five times wider than a real one — so a line of
        // text that fits a card in a browser overflows it here. Half scale brings the text back to
        // about the room it takes in a browser, and no box in the catalogue is sized by its text:
        // what is left is the layout the two targets share, which is what this test is for.
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(0.5)),
          child: child!,
        ),
        // A text field is a `TextField` under the tree, and one needs a `Material` above it: a
        // screen would give it a scaffold, so the test does too.
        home: Scaffold(
          body: SingleChildScrollView(
            child: renderFlutter(
              buildMaterialSection(),
              theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
            ),
          ),
        ),
      ),
    );

    // Nothing may be thrown: a tree Flutter cannot lay out — an unbounded flex, a share of nothing
    // — is exactly what a page that only ever rendered in CSS hides.
    expect(tester.takeException(), isNull);

    // Each screen fills the card it is drawn in: the width is the track's, not a number a component
    // could get wrong, and the height is the one the panel states.
    final List<Size> screens = <Size>[
      for (final Element element
          in find
              .byWidgetPredicate(
                (Widget widget) =>
                    widget is FlutterBox && widget.box is MaterialScaffold,
              )
              .evaluate())
        (element.renderObject! as RenderBox).size,
    ];

    expect(screens, hasLength(2));
    expect(screens.first.height, 420);
    expect(
      screens.first.width,
      screens.last.width,
      reason: 'two screens in one grid have one column width',
    );
    expect(
      screens.first.width,
      greaterThan(400),
      reason:
          'a screen is as wide as its card, not as wide as a phone used to be',
    );
  });
}
