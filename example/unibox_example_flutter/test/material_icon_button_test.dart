import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// An icon button is a square a finger is aimed at, and a badge is placed in it.
///
/// The badge is the part that has to be seen to be believed: it is pinned to the end of
/// the square rather than added beside the glyph, so a count sits over the corner of the
/// icon it counts and the control keeps the size the finger needs.
void main() {
  // The glyph a Material Symbols font carries: one character, so it is a picture of a
  // control rather than a word the tree has to wrap.
  final core.UINode glyph = MaterialIcon.codePoint(0xe9b2);

  Widget page({int? badgeCount, void Function()? onTap, bool enabled = true}) =>
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(
              MaterialIconButton(
                icon: glyph,
                label: 'Filters',
                badgeCount: badgeCount,
                enabled: enabled,
                onTap: onTap,
              ),
              theme: MaterialPalette.lightTheme,
            ),
          ),
        ),
      );

  Finder control() => find.byWidgetPredicate(
    (Widget widget) => widget is FlutterBox && widget.box is MaterialIconButton,
  );

  testWidgets('is a 40 pixel square with the glyph centred in it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(page());

    final Rect square = tester.getRect(control());
    final Rect icon = tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) => widget is FlutterBox && widget.box is MaterialIcon,
      ),
    );

    expect(square.size, const Size(40, 40));
    expect(icon.size, const Size(24, 24));
    expect(icon.center.dx, closeTo(square.center.dx, 0.5));
    expect(icon.center.dy, closeTo(square.center.dy, 0.5));
  });

  testWidgets('runs its press, and not when it is disabled', (
    WidgetTester tester,
  ) async {
    int pressed = 0;

    await tester.pumpWidget(page(onTap: () => pressed++));
    await tester.tap(control());
    await tester.pumpAndSettle();

    expect(pressed, 1);

    await tester.pumpWidget(page(onTap: () => pressed++, enabled: false));
    await tester.tap(control());
    await tester.pumpAndSettle();

    expect(pressed, 1, reason: 'a disabled control recalls its callback');
  });

  testWidgets('sits the count over the top right corner of the glyph', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(page(badgeCount: 3));

    final Rect square = tester.getRect(control());
    final Rect pill = tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) => widget is FlutterBox && widget.box.height == 16,
      ),
    );

    // The corner of the glyph rather than the middle of the padding: 40 - 16 = 24 is
    // where the pill starts, and it takes no room from the square.
    expect(pill.height, 16);
    expect(pill.width, greaterThanOrEqualTo(16));
    expect(pill.right, closeTo(square.right, 0.5));
    expect(pill.top, closeTo(square.top, 0.5));
    expect(square.size, const Size(40, 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('names the control once, and hides the picture beside it', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(page(badgeCount: 3));

    expect(find.bySemanticsLabel('Filters'), findsOneWidget);

    // A count a reader is not told is a picture: the pill is in the tree as a hidden
    // node, so the browser writes `aria-hidden` and a reader moves past it.
    final badge = tester.getSemantics(
      find.byWidgetPredicate(
        (Widget widget) => widget is FlutterBox && widget.box.height == 16,
      ),
    );
    expect(badge.flagsCollection.isHidden, isTrue);

    handle.dispose();
  });
}
