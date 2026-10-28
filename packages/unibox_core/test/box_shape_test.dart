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
