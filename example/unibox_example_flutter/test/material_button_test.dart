import 'package:flutter/material.dart' hide MaterialButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// The pill a reader sees and the box a press lands on are one and the same.
///
/// A button is a `Box` around a `MaterialInkWell`, and the well is what carries the press, the
/// cursor, the tints and the ink — so a well that hugs its label leaves the ends of the pill dead,
/// which is the bug this suite exists for. A component lives in `unibox_material`, which no
/// renderer may depend on, so the measurement against real widgets sits here.
void main() {
  Widget page(core.UINode button) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: renderFlutter(button, theme: MaterialPalette.lightTheme),
      ),
    ),
  );

  /// The pill: the box the button wraps its well in.
  Finder pillOf(MaterialButton button) => find.byWidgetPredicate(
    (Widget widget) =>
        widget is FlutterBox && identical(widget.box, button.children.single),
  );

  /// The control: the box that answers the press, which is the well's own surface.
  Finder control() => find.byWidgetPredicate(
    (Widget widget) => widget is FlutterBox && widget.box.onTap != null,
  );

  testWidgets(
    'fills the pill with the press, whatever room the caller leaves',
    (WidgetTester tester) async {
      // Four pixels above and below the label is a 28 pixel control inside a 40 pixel pill
      // until the minimum belongs to the well rather than to the fill.
      final MaterialButton button = MaterialButton.outlined(
        label: const core.TextNode('Sign in'),
        padding: const core.BoxSpacing.symmetric(horizontal: 16, vertical: 4),
        onTap: () {},
      );

      await tester.pumpWidget(page(button));

      final Rect pill = tester.getRect(pillOf(button));
      final Rect controlBox = tester.getRect(control());

      expect(
        pill.height,
        40,
        reason: 'the minimum is a floor, whatever the padding',
      );
      expect(controlBox.size, pill.size, reason: 'the press fills the pill');
    },
  );

  testWidgets('fills a pill whose size the caller pinned', (
    WidgetTester tester,
  ) async {
    final MaterialButton button = MaterialButton.filled(
      label: const core.TextNode('Sign in'),
      width: 240,
      height: 56,
      onTap: () {},
    );

    await tester.pumpWidget(page(button));

    final Rect pill = tester.getRect(pillOf(button));
    final Rect controlBox = tester.getRect(control());

    expect(pill.size, const Size(240, 56));
    expect(
      controlBox.size,
      pill.size,
      reason: 'the sides of a pinned pill press',
    );
  });

  testWidgets('is 64 by 40 when nothing in the label asks for more', (
    WidgetTester tester,
  ) async {
    final MaterialButton button = MaterialButton.filled(
      label: const core.TextNode('a'),
      onTap: () {},
    );

    await tester.pumpWidget(page(button));

    expect(tester.getRect(control()).size, const Size(64, 40));
    expect(tester.getRect(pillOf(button)).size, const Size(64, 40));
  });

  testWidgets('grows past the floor rather than being clamped to it', (
    WidgetTester tester,
  ) async {
    // A label taller than 40 grows the button, and the press grows with it.
    final MaterialButton button = MaterialButton.filled(
      label: const core.TextNode('Two\nlines'),
      onTap: () {},
    );

    await tester.pumpWidget(page(button));

    final Rect pill = tester.getRect(pillOf(button));
    expect(pill.height, greaterThan(40));
    expect(tester.getRect(control()).size, pill.size);
  });

  testWidgets('keeps a taller tap target, with the press on the target', (
    WidgetTester tester,
  ) async {
    // The one case where the press is deliberately bigger than the pill: 48 of room around a
    // 40 pixel shape, centred, so the target and the shape still share a width.
    final MaterialInkWell well = MaterialInkWell(
      onTap: () {},
      height: 40,
      minWidth: 64,
      tapTargetHeight: 48,
      borderRadius: 20,
      child: const core.TextNode('Sign in'),
    );

    await tester.pumpWidget(page(well));

    final Finder target = find.byWidgetPredicate(
      (Widget widget) => widget is FlutterBox && widget.box.onTap != null,
    );
    final Finder shape = find.descendant(
      of: target,
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is FlutterBox && widget.box.overflow == core.Overflow.hidden,
      ),
    );

    expect(tester.getRect(target).height, 48);
    expect(tester.getRect(shape).height, 40);
    expect(tester.getRect(shape).width, tester.getRect(target).width);
    expect(
      tester.getRect(shape).center.dy,
      closeTo(tester.getRect(target).center.dy, 0.5),
    );
  });
}
