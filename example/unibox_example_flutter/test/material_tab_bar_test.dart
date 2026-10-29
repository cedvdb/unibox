import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A bar is a node of `unibox_material`, which no renderer may depend on, so what it
/// looks like on a real widget is pinned here, in the example that depends on both.
///
/// The facts worth a widget are the ones a tree cannot state: how wide a tab came out,
/// and therefore whether the underline that spans it really is the label's width.
void main() {
  /// The tab a press asked for.
  int? pressed;

  /// The tab the tree currently says is chosen: a bar is a node, so a press asks the host
  /// for a new tree rather than changing this one.
  int selected = 0;

  setUp(() {
    pressed = null;
    selected = 0;
  });

  MaterialTabBar bar({
    MaterialTabVariant variant = MaterialTabVariant.secondary,
  }) => MaterialTabBar(
    tabs: const <MaterialTab>[
      MaterialTab(label: TextNode('Overview')),
      MaterialTab(label: TextNode('Listings')),
      MaterialTab(label: TextNode('Reviews')),
    ],
    selected: selected,
    variant: variant,
    onSelect: (int index) {
      pressed = index;
      selected = index;
    },
  );

  Future<void> pumpBar(
    WidgetTester tester,
    MaterialTabBar node, {
    // Wide enough for three labels of the test font, which draws a square per glyph.
    double width = 600,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: renderFlutter(node, theme: MaterialPalette.lightTheme),
            ),
          ),
        ),
      ),
    );
  }

  /// The underline of the chosen tab, which is the one painted at full strength.
  Finder underline(double opacity) => find.byWidgetPredicate(
    (Widget widget) =>
        widget is FlutterBox &&
        widget.box.height == MaterialTabBar.indicatorHeight &&
        widget.box.opacity == opacity,
  );

  testWidgets('draws an underline exactly as wide as the label above it', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, bar());

    // The one width a tab cannot state and a share cannot reach: the label's own. A
    // stack takes the size of the child it lays out, and the underline is pinned across
    // it, so the two are the same width without anyone measuring the text.
    final double label = tester.getSize(find.text('Overview')).width;
    final Size line = tester.getSize(underline(1));

    expect(line.width, closeTo(label, 0.5));
    expect(line.height, MaterialTabBar.indicatorHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sits the underline on the bottom edge of the bar', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, bar());

    final Rect line = tester.getRect(underline(1));
    final Rect barBox = tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) => widget is FlutterBox && widget.box is MaterialTabBar,
      ),
    );

    expect(line.bottom, closeTo(barBox.bottom, 0.5));
    // The underline of every other tab is there and invisible, so the chosen one can
    // fade in where the reader last saw it instead of appearing from nowhere.
    expect(underline(0), findsNWidgets(2));
    expect(tester.getSize(underline(0).first).width, greaterThan(0));
  });

  testWidgets('packs the tabs, each as wide as its label and its padding', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, bar());

    final double first = tester.getRect(find.text('Overview')).left;
    final double second = tester.getRect(find.text('Listings')).left;

    // 16 of padding either side of a label is what a secondary tab is wide, so the second
    // label starts one label, two paddings and no gap after the first.
    expect(
      tester.getRect(find.text('Listings')).left,
      closeTo(first + tester.getSize(find.text('Overview')).width + 32, 1),
    );
    expect(second, greaterThan(first));
    expect(tester.takeException(), isNull);
  });

  testWidgets('moves the underline to the tab a press landed on', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, bar());

    final Rect before = tester.getRect(underline(1));

    await tester.tap(find.text('Reviews'));
    await tester.pump();

    expect(pressed, 2);

    // The tree is immutable: the press asks the host for a bar that says `2`, and the
    // underline follows because it belongs to the tab rather than to a position.
    await pumpBar(tester, bar());
    await tester.pump(const Duration(milliseconds: 400));

    final Rect after = tester.getRect(underline(1));

    expect(after.left, greaterThan(before.left));
    expect(
      tester.getSize(underline(1)).width,
      closeTo(tester.getSize(find.text('Reviews')).width, 0.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the share-wide indicator to a primary bar', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, bar(variant: MaterialTabVariant.primary));

    // One indicator for the whole bar, a third of it wide, rather than one per tab: the
    // two variants are two ways of placing the same three pixels.
    final Finder indicator = find.byWidgetPredicate(
      (Widget widget) =>
          widget is FlutterBox && widget.box.widthFraction != null,
    );

    expect(indicator, findsOneWidget);
    expect(tester.getSize(indicator).width, closeTo(600 / 3, 1));
    expect(
      underline(0),
      findsNothing,
      reason: 'a primary tab carries no underline of its own',
    );
    expect(tester.takeException(), isNull);
  });
}
