import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// A ring: two circles, the inner one punched out by the fill rule.
const core.BoxShape ring = core.BoxShape(
  viewBoxWidth: 100,
  viewBoxHeight: 100,
  fillRule: core.BoxFillRule.evenOdd,
  commands: <core.BoxPathCommand>[
    core.BoxPathMoveTo(50, 0),
    core.BoxPathArcTo(50, 100, radiusX: 50, radiusY: 50),
    core.BoxPathArcTo(50, 0, radiusX: 50, radiusY: 50),
    core.BoxPathMoveTo(50, 25),
    core.BoxPathArcTo(50, 75, radiusX: 25, radiusY: 25),
    core.BoxPathArcTo(50, 25, radiusX: 25, radiusY: 25),
  ],
);

/// A shape is a path in a view box, so the suite measures the path: where it
/// lands, what it contains, and which parts of it count as inside.
void main() {
  group('pathOf', () {
    test('fills the box a circle is drawn in', () {
      final Path path = pathOf(core.BoxShape.circle, const Size(100, 100));

      expect(path.getBounds(), const Rect.fromLTRB(0, 0, 100, 100));
      expect(path.fillType, PathFillType.nonZero);
      expect(path.contains(const Offset(50, 50)), isTrue);
      expect(path.contains(const Offset(2, 2)), isFalse);
    });

    test('stretches with the box, as a view box does', () {
      final Path path = pathOf(core.BoxShape.circle, const Size(200, 100));

      expect(path.getBounds(), const Rect.fromLTRB(0, 0, 200, 100));
      expect(path.contains(const Offset(100, 50)), isTrue);
      // A ninth of the way in is inside a circle and outside an ellipse this flat.
      expect(path.contains(const Offset(20, 50)), isTrue);
      expect(path.contains(const Offset(20, 10)), isFalse);
    });

    test('punches the hole of an even-odd shape', () {
      final Path path = pathOf(ring, const Size(100, 100));

      expect(path.fillType, PathFillType.evenOdd);
      expect(
        path.contains(const Offset(50, 50)),
        isFalse,
        reason: 'the inner circle is the hole of the ring',
      );
      expect(
        path.contains(const Offset(50, 8)),
        isTrue,
        reason: 'the band between the two circles is the ring itself',
      );
    });

    test('draws straight edges where the commands say', () {
      const core.BoxShape triangle = core.BoxShape(
        viewBoxWidth: 100,
        viewBoxHeight: 100,
        commands: <core.BoxPathCommand>[
          core.BoxPathMoveTo(50, 0),
          core.BoxPathLineTo(100, 100),
          core.BoxPathLineTo(0, 100),
          core.BoxPathClose(),
        ],
      );

      final Path path = pathOf(triangle, const Size(100, 100));

      expect(path.getBounds(), const Rect.fromLTRB(0, 0, 100, 100));
      expect(path.contains(const Offset(50, 80)), isTrue);
      expect(path.contains(const Offset(10, 20)), isFalse);
    });
  });

  group('a shaped box', () {
    testWidgets('paints its outline instead of a rectangle', (
      WidgetTester tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          shape: core.BoxShape.circle,
          backgroundColor: core.BoxColor.white,
          border: core.BoxBorder(color: core.BoxColor.black),
          children: <core.UINode>[core.TextNode('Hi')],
        ),
      );

      expect(find.text('Hi'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is CustomPaint && widget.painter != null,
        ),
        findsOneWidget,
        reason: 'the outline is painted, not a decorated rectangle',
      );
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color != null,
        ),
        findsNothing,
        reason: 'the fill belongs to the shape, so no decoration paints one',
      );
    });

    testWidgets('caps the ends of an arc the way its border says', (
      WidgetTester tester,
    ) async {
      await pumpNode(
        tester,
        core.Box(
          width: 48,
          height: 48,
          shape: core.BoxShape.arc(stroke: 4, sweep: 0.42, viewBox: 48),
          border: const core.BoxBorder(
            width: 4,
            color: core.BoxColor.black,
            cap: core.BoxStrokeCap.round,
          ),
        ),
      );

      // An arc is a line, not a region: what a reader sees is the stroke, and its ends
      // are the only place a cap is drawn. The matcher cannot read a cap, so the mapping
      // that supplies it is pinned in `toStrokeCap`'s own test below.
      await expectLater(
        find.byWidgetPredicate(
          (Widget widget) => widget is CustomPaint && widget.painter != null,
        ),
        paints..path(strokeWidth: 4),
      );
    });

    test('maps every cap to the one Flutter draws the same way', () {
      expect(toStrokeCap(core.BoxStrokeCap.butt), StrokeCap.butt);
      expect(toStrokeCap(core.BoxStrokeCap.round), StrokeCap.round);
      expect(toStrokeCap(core.BoxStrokeCap.square), StrokeCap.square);
    });

    testWidgets('clips its content only when the box says so', (
      WidgetTester tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          shape: core.BoxShape.circle,
          children: <core.UINode>[core.TextNode('Hi')],
        ),
      );

      expect(find.byType(ClipPath), findsNothing);

      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          shape: core.BoxShape.circle,
          overflow: core.Overflow.hidden,
          children: <core.UINode>[core.TextNode('Hi')],
        ),
      );

      expect(find.byType(ClipPath), findsOneWidget);
    });

    testWidgets('draws a ring with a hole a child can be seen through', (
      WidgetTester tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          shape: ring,
          backgroundColor: core.BoxColor.black,
        ),
      );

      final CustomPaint paint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (Widget widget) => widget is CustomPaint && widget.painter != null,
        ),
      );

      expect(paint.painter.runtimeType.toString(), 'UniboxShapePainter');
      expect(tester.takeException(), isNull);
    });
  });
}
