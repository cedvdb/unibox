import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// A hexagon: six edges of a 100 by 100 view box.
const BoxShape hexagon = BoxShape(
  viewBoxWidth: 100,
  viewBoxHeight: 100,
  commands: <BoxPathCommand>[
    BoxPathMoveTo(50, 0),
    BoxPathLineTo(93, 25),
    BoxPathLineTo(93, 75),
    BoxPathLineTo(50, 100),
    BoxPathLineTo(7, 75),
    BoxPathLineTo(7, 25),
    BoxPathClose(),
  ],
);

/// A ring: two circles, the inner one punched out by the fill rule.
const BoxShape ring = BoxShape(
  viewBoxWidth: 100,
  viewBoxHeight: 100,
  fillRule: BoxFillRule.evenOdd,
  commands: <BoxPathCommand>[
    BoxPathMoveTo(50, 0),
    BoxPathArcTo(50, 100, radiusX: 50, radiusY: 50),
    BoxPathArcTo(50, 0, radiusX: 50, radiusY: 50),
    BoxPathMoveTo(50, 20),
    BoxPathArcTo(50, 80, radiusX: 30, radiusY: 30),
    BoxPathArcTo(50, 20, radiusX: 30, radiusY: 30),
  ],
);

void main() {
  group('BoxShape', () {
    test('is a value: two shapes of the same outline are equal', () {
      expect(hexagon, hexagon);
      expect(hexagon.hashCode, hexagon.hashCode);
      expect(hexagon, isNot(ring));
      expect(
        hexagon,
        isNot(
          const BoxShape(
            viewBoxWidth: 100,
            viewBoxHeight: 200,
            commands: <BoxPathCommand>[
              BoxPathMoveTo(50, 0),
              BoxPathLineTo(93, 25),
              BoxPathLineTo(93, 75),
              BoxPathLineTo(50, 100),
              BoxPathLineTo(7, 75),
              BoxPathLineTo(7, 25),
              BoxPathClose(),
            ],
          ),
        ),
        reason: 'the view box is part of the shape, not a drawing hint',
      );
    });

    test('fills with the non-zero rule unless it says otherwise', () {
      expect(hexagon.fillRule, BoxFillRule.nonZero);
      expect(ring.fillRule, BoxFillRule.evenOdd);
    });

    test('states a circle as two half turns', () {
      expect(BoxShape.circle.commands, hasLength(3));
      expect(BoxShape.circle.commands.first, const BoxPathMoveTo(50, 0));
      expect(
        BoxShape.circle.commands[1],
        const BoxPathArcTo(50, 100, radiusX: 50, radiusY: 50),
      );
      expect(
        BoxShape.circle.commands.last,
        const BoxPathArcTo(50, 0, radiusX: 50, radiusY: 50),
      );
    });

    test('reports a shape with no command as empty', () {
      const BoxShape blank = BoxShape(
        viewBoxWidth: 10,
        viewBoxHeight: 10,
        commands: <BoxPathCommand>[],
      );

      expect(blank.isEmpty, isTrue);
      expect(hexagon.isEmpty, isFalse);
    });
  });

  group('BoxShape.ring', () {
    test('is two circles and the even-odd rule for a whole ring', () {
      final BoxShape ring = BoxShape.ring(thickness: 12);

      expect(ring.fillRule, BoxFillRule.evenOdd);
      expect(ring.commands, hasLength(6));
      expect(ring.viewBoxWidth, 100);
      // The outer circle fills the view box; the inner one is 12 units inside it.
      expect(ring.commands.first, const BoxPathMoveTo(50, 0));
      expect(ring.commands[3], const BoxPathMoveTo(50, 12));
    });

    test('is one subpath for a partial ring, filled under non-zero', () {
      final BoxShape quarter = BoxShape.ring(thickness: 12, sweep: 0.25);

      expect(quarter.fillRule, BoxFillRule.nonZero);
      expect(quarter.commands, hasLength(5));
      expect(
        quarter.commands.last,
        const BoxPathClose(),
        reason: 'a sector closes on itself instead of drawing two circles',
      );
      // A quarter turn from twelve o'clock ends at three o'clock on the rim.
      expect(quarter.commands[1].toString(), contains('100'));
    });

    test('takes the long way round past half a turn', () {
      final BoxShape most = BoxShape.ring(thickness: 12, sweep: 0.75);
      final BoxPathArcTo outer = most.commands[1] as BoxPathArcTo;

      expect(outer.largeArc, isTrue);
      expect(
        (BoxShape.ring(thickness: 12, sweep: 0.42).commands[1] as BoxPathArcTo)
            .largeArc,
        isFalse,
      );
    });

    test('draws a sliver at zero instead of nothing', () {
      final BoxShape empty = BoxShape.ring(thickness: 12, sweep: 0);

      expect(empty.isEmpty, isFalse);
      expect(validateTree(const Box(shape: BoxShape.circle)), isEmpty);
    });

    test('keeps a hole however wide the band is asked to be', () {
      final BoxShape thick = BoxShape.ring(thickness: 400);
      final BoxPathArcTo inner = thick.commands[4] as BoxPathArcTo;

      expect(inner.radiusX, greaterThan(0));
      expect(inner.radiusX.isFinite, isTrue);
    });
  });

  group('BoxShape.arc', () {
    test('is an open line, so the stroke has two ends to cap', () {
      final BoxShape quarter = BoxShape.arc(stroke: 4, sweep: 0.25);

      expect(quarter.commands, hasLength(2));
      expect(
        quarter.commands.last,
        isNot(isA<BoxPathClose>()),
        reason: 'an arc is stroked, and a closed path has no ends',
      );
    });

    test('insets the radius by half the stroke', () {
      final BoxShape arc = BoxShape.arc(stroke: 4, viewBox: 100);
      final BoxPathMoveTo start = arc.commands.first as BoxPathMoveTo;

      // The centreline sits 48 from the centre, so a 4 unit stroke reaches the edge.
      expect(start.x, closeTo(50, 0.001));
      expect(start.y, closeTo(2, 0.001));
    });

    test('starts at twelve o clock and runs clockwise', () {
      final BoxShape quarter = BoxShape.arc(stroke: 4, sweep: 0.25);
      final BoxPathArcTo end = quarter.commands[1] as BoxPathArcTo;

      // A quarter turn from the top ends at three o'clock.
      expect(end.x, closeTo(98, 0.001));
      expect(end.y, closeTo(50, 0.001));
      expect(end.largeArc, isFalse);
    });

    test('takes the long way round past half a turn', () {
      final BoxShape most = BoxShape.arc(stroke: 4, sweep: 0.75);

      expect((most.commands[1] as BoxPathArcTo).largeArc, isTrue);
    });

    test('draws two half turns for a whole circle', () {
      final BoxShape whole = BoxShape.arc(stroke: 4);

      expect(whole.commands, hasLength(3));
      expect(whole.commands.first, isA<BoxPathMoveTo>());
      expect((whole.commands[1] as BoxPathArcTo).largeArc, isFalse);
    });

    test('keeps a dot at zero sweep instead of nothing', () {
      final BoxShape empty = BoxShape.arc(stroke: 4, sweep: 0);

      expect(empty.isEmpty, isFalse);
      expect(empty.commands, hasLength(2));
    });

    test('keeps a radius however thick the stroke is asked to be', () {
      final BoxShape thick = BoxShape.arc(stroke: 400);
      final BoxPathArcTo arc = thick.commands[1] as BoxPathArcTo;

      expect(arc.radiusX, greaterThan(0));
      expect(arc.radiusX.isFinite, isTrue);
    });
  });

  group('BoxPathCommand', () {
    test('compares by its numbers, so a path can be keyed', () {
      expect(const BoxPathLineTo(1, 2), const BoxPathLineTo(1, 2));
      expect(const BoxPathLineTo(1, 2), isNot(const BoxPathLineTo(2, 1)));
      expect(
        const BoxPathCubicTo(1, 2, 3, 4, 5, 6),
        const BoxPathCubicTo(1, 2, 3, 4, 5, 6),
      );
      expect(
        const BoxPathQuadraticTo(1, 2, 3, 4),
        const BoxPathQuadraticTo(1, 2, 3, 4),
      );
      expect(const BoxPathClose(), const BoxPathClose());
    });

    test('reads an arc the way SVG reads one', () {
      const BoxPathArcTo arc = BoxPathArcTo(
        10,
        20,
        radiusX: 5,
        radiusY: 6,
        rotation: 30,
        largeArc: true,
        clockwise: false,
      );

      expect(arc.radiusX, 5);
      expect(arc.radiusY, 6);
      expect(arc.rotation, 30);
      expect(arc.largeArc, isTrue);
      expect(arc.clockwise, isFalse);
      expect(
        arc,
        isNot(const BoxPathArcTo(10, 20, radiusX: 5, radiusY: 6, rotation: 30)),
      );
    });
  });
}
