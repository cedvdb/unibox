import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A bar is a node of `unibox_material`, which no renderer may depend on, so what it
/// looks like on a real widget is pinned here, in the example that depends on both.
///
/// The facts worth a widget are the ones a tree cannot state: that the bar takes the
/// height and the width it was given, that the destinations share it equally, and
/// that a press reaches the destination it landed on.
void main() {
  /// The destination a press asked for.
  int? pressed;

  MaterialNavigationBar bar() => MaterialNavigationBar(
    destinations: const <MaterialNavigationDestination>[
      MaterialNavigationDestination(label: TextNode('Listings')),
      MaterialNavigationDestination(label: TextNode('Map')),
      MaterialNavigationDestination(label: TextNode('Saved')),
    ],
    selected: 0,
    onSelect: (int index) => pressed = index,
  );

  Future<void> pumpBar(WidgetTester tester) async {
    pressed = null;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              child: renderFlutter(bar(), theme: MaterialPalette.lightTheme),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('fills the width it is given and states its 80 pixels', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester);

    final Finder barBox = find.byWidgetPredicate(
      (Widget widget) =>
          widget is FlutterBox && widget.box is MaterialNavigationBar,
    );

    expect(
      tester.getSize(barBox),
      const Size(360, MaterialNavigationBar.barHeight),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('spreads the destinations equally across the bar', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester);

    final List<double> centres = <double>[
      tester.getCenter(find.text('Listings')).dx,
      tester.getCenter(find.text('Map')).dx,
      tester.getCenter(find.text('Saved')).dx,
    ];

    // Three equal shares of 360: the labels sit at 60, 180 and 300.
    expect(centres[0], closeTo(60, 1));
    expect(centres[1], closeTo(180, 1));
    expect(centres[2], closeTo(300, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reaches the destination a press landed on', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester);

    await tester.tap(find.text('Map'));
    await tester.pump();

    expect(pressed, 1);
    expect(tester.takeException(), isNull);
  });
}
