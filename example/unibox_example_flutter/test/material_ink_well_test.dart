import 'package:flutter/material.dart' hide BoxBorder;
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// The ink is a layer of positioned boxes, so the suite can count it: a press
/// adds one drop, and a drop that has spread takes itself away.
///
/// A well lives in `unibox_material`, which no renderer may depend on, so the
/// check of what a press looks like on a real widget sits here, in the example
/// that depends on both.
void main() {
  Widget page(UINode node) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: renderFlutter(node, theme: MaterialPalette.lightTheme),
      ),
    ),
  );

  /// The shape: the box that paints the surface, clips the ink and takes the press.
  Finder shape() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is FlutterBox && widget.box.overflow == Overflow.hidden,
  );

  /// The layer the three tints are painted on, which is a box of its own.
  Finder tints() => find.byWidgetPredicate(
    (Widget widget) => widget is FlutterBox && widget.box.hoverStyle != null,
  );

  /// The room a finger is given when a target is taller than the shape.
  Finder target() => find.byWidgetPredicate(
    (Widget widget) => widget is FlutterBox && widget.box.onTap != null,
  );

  testWidgets('leaves ink where the press landed, then takes it away', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: renderFlutter(
              Box(
                backgroundColor: const BoxColor(0xFF6750A4),
                borderRadius: 20,
                children: <UINode>[
                  MaterialInkWell(
                    onTap: () {},
                    borderRadius: 20,
                    ink: const BoxColor(0xFFFFFFFF),
                    padding: const BoxSpacing.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: TextNode(
                      'Press me',
                      style: MaterialTypography.labelLarge.copyWith(
                        color: const BoxColor(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // The resting well: the fill, the label, and no ink.
    expect(find.text('Press me'), findsOneWidget);
    expect(find.byType(Positioned), findsNothing);

    await tester.tapAt(tester.getCenter(find.text('Press me')));
    await tester.pump();

    // The press reached the well, which started a drop inside it.
    expect(find.byType(Positioned), findsOneWidget);

    await tester.pump(materialInkDuration + const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(Positioned), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('the tint layer', () {
    testWidgets('covers a pill that a floor gives its size', (
      WidgetTester tester,
    ) async {
      // The consumer's call, measured in a browser at 1440: a pill of 76 by 32 whose
      // tint painted 74 by 20 — the label's line, 1 pixel inside the outline — so six
      // pixels of pill at each end never tinted, and the radius drew a lozenge inside a
      // lozenge. Hovering it read as a second, smaller button appearing in the first.
      final MaterialInkWell well = MaterialInkWell(
        onTap: () {},
        minWidth: 64,
        minHeight: 32,
        borderRadius: 16,
        border: const BoxBorder(color: BoxColor(0xFF79747E)),
        padding: const BoxSpacing.symmetric(horizontal: 6),
        child: const TextNode('OK'),
      );

      await tester.pumpWidget(page(well));

      // A floor and a short label arrive at the same box on both layers, or the layer the
      // pointer lights is smaller than the pill it belongs to.
      expect(tester.getRect(shape()).size, const Size(64, 32));
      expect(
        tester.getRect(tints()).size,
        tester.getRect(shape()).size,
        reason: 'the tint is the pill, not the label',
      );
    });

    testWidgets('stays on the shape when the target is taller', (
      WidgetTester tester,
    ) async {
      final MaterialInkWell well = MaterialInkWell(
        onTap: () {},
        height: 32,
        tapTargetHeight: 48,
        minWidth: 64,
        borderRadius: 16,
        child: const TextNode('OK'),
      );

      await tester.pumpWidget(page(well));

      // The room is the finger's and the paint is the pill's: the tint does not grow into
      // the target it is centred in.
      expect(tester.getRect(target()).height, 48);
      expect(tester.getRect(shape()).size, const Size(64, 32));
      expect(tester.getRect(tints()).size, tester.getRect(shape()).size);
    });

    testWidgets('grows with a label taller than the floor', (
      WidgetTester tester,
    ) async {
      // A floor is never a clamp: two lines of label are 40, and both layers follow.
      final MaterialInkWell well = MaterialInkWell(
        onTap: () {},
        minWidth: 64,
        minHeight: 24,
        borderRadius: 16,
        child: const TextNode('Two\nlines'),
      );

      await tester.pumpWidget(page(well));

      expect(tester.getRect(shape()).height, greaterThan(24));
      expect(tester.getRect(tints()).size, tester.getRect(shape()).size);
    });

    testWidgets('keeps an exact size on both layers', (
      WidgetTester tester,
    ) async {
      final MaterialInkWell well = MaterialInkWell(
        onTap: () {},
        width: 96,
        height: 40,
        borderRadius: 20,
        child: const TextNode('OK'),
      );

      await tester.pumpWidget(page(well));

      expect(tester.getRect(shape()).size, const Size(96, 40));
      expect(tester.getRect(tints()).size, const Size(96, 40));
    });
  });
}
