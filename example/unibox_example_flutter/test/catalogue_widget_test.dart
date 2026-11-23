import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:unibox_core/unibox_core.dart';

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
              scope: UniboxScope(
                theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
              ),
            ),
          ),
        ),
      ),
    );

    // Nothing may be thrown: a tree Flutter cannot lay out — an unbounded flex, a share of nothing
    // — is exactly what a page that only ever rendered in CSS hides.
    expect(tester.takeException(), isNull);

    // And the blocks are as wide as the cells they are drawn in: a share of a track is the grid's
    // to state, and a block that sized itself from its own words would be a card sitting in the
    // corner of its own cell — the shape this test was written to catch.
    final List<Size> blocks = <Size>[
      for (final Element element
          in find
              .byWidgetPredicate(
                (Widget widget) =>
                    widget is FlutterBox && widget.box is MaterialCard,
              )
              .evaluate())
        (element.renderObject! as RenderBox).size,
    ];

    expect(blocks, isNotEmpty, reason: 'the catalogue draws its cards');
    for (final Size block in blocks) {
      expect(block.width, greaterThan(0));
      expect(
        block.width,
        lessThanOrEqualTo(1280),
        reason: 'a card is as wide as its cell, not as wide as the page',
      );
    }
  });
}
