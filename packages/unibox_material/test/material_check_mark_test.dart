import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('MaterialCheckMark', () {
    test('is an 18 pixel square of two strokes', () {
      final MaterialCheckMark mark = MaterialCheckMark(color: BoxColors.red);

      expect(mark, isA<StackNode>());
      expect(mark.width, 18);
      expect(mark.height, 18);
      expect(mark.children, hasLength(2));
      expect(
        mark.children.whereType<PositionedNode>(),
        hasLength(2),
        reason: 'both strokes are centred in the square that holds them',
      );
    });

    test('draws each stroke in the given colour, with rounded ends', () {
      final List<Box> strokes = _strokesOf(
        MaterialCheckMark(color: BoxColors.red),
      );

      for (final Box stroke in strokes) {
        expect(stroke.backgroundColor, BoxColors.red);
        // A rounded end is a radius of half the thickness, which is the cap
        // Material's own outline has on both strokes.
        expect(stroke.borderRadius, (stroke.height as double) / 2);
      }
    });

    test("carries Material's weight, in the icon font's own 24 pixel grid", () {
      final List<Box> strokes = _strokesOf(
        MaterialCheckMark(color: BoxColors.red, size: 24),
      );

      // The glyph is a 2 pixel stroke, a 7.07 pixel short arm and a 14 pixel long one
      // at 24. A seventh of the box is what a hand-tuned tick draws, and it reads
      // nearly twice as heavy as Material's.
      expect(strokes.first.height, closeTo(2, 0.001));
      expect(strokes.first.width, closeTo(7.07, 0.001));
      expect(strokes.last.width, closeTo(14, 0.001));
    });

    test('runs the two arms at 45 degrees, one each way', () {
      final List<Box> strokes = _strokesOf(
        MaterialCheckMark(color: BoxColors.red),
      );

      expect(
        strokes.map((Box stroke) => stroke.transform?.rotation).toList(),
        <double>[45, -45],
      );
    });

    test('meets the two arms at one point, the elbow of the tick', () {
      const double size = 18;
      final List<Box> strokes = _strokesOf(
        MaterialCheckMark(color: BoxColors.red, size: size),
      );

      // Two arms that do not share their inner end leave a notch at the elbow, which
      // is what a tick of two bars gets wrong when its offsets are guessed.
      final BoxPoint elbow = _elbowOf(strokes);

      // Across, the elbow is Material's own: 9.55 of a 24 pixel box. Down, it sits a
      // sixth of a stroke below Material's 16.6, because a round cap reaches where the
      // flat end of the glyph's polygon does not — that is what keeps the mark centred.
      expect(elbow.x, closeTo(9.55 / 24 * size - size / 2, 0.001));
      expect(
        elbow.y,
        closeTo(16.6 / 24 * size - size / 2 + 0.35 / 24 * size, 0.02),
      );
    });

    test('stays inside its square, and centred in it', () {
      const double size = 18;
      final List<BoxPoint> ends = <BoxPoint>[
        for (final Box stroke in _strokesOf(
          MaterialCheckMark(color: BoxColors.red, size: size),
        ))
          ..._endsOf(stroke),
      ];

      expect(
        ends.map((BoxPoint point) => point.x).reduce(math.min),
        greaterThan(-size / 2),
      );
      expect(
        ends.map((BoxPoint point) => point.x).reduce(math.max),
        lessThan(size / 2),
      );
      expect(
        ends.map((BoxPoint point) => point.y).reduce(math.min),
        greaterThan(-size / 2),
      );
      expect(
        ends.map((BoxPoint point) => point.y).reduce(math.max),
        lessThan(size / 2),
      );
      // A mark that hung off one side would sit off centre beside its label.
      expect(
        ends.map((BoxPoint point) => point.x).reduce(math.min) +
            ends.map((BoxPoint point) => point.x).reduce(math.max),
        closeTo(0, 0.01),
      );
      expect(
        ends.map((BoxPoint point) => point.y).reduce(math.min) +
            ends.map((BoxPoint point) => point.y).reduce(math.max),
        closeTo(0, 0.01),
      );
    });

    test('scales with its size, and takes a key', () {
      final MaterialCheckMark small = MaterialCheckMark(
        color: BoxColors.red,
        size: 12,
      );
      final MaterialCheckMark keyed = MaterialCheckMark(
        color: BoxColors.red,
        key: 'mark',
      );

      expect(small.width, 12);
      expect(small.height, 12);
      expect(_strokesOf(small).first.width, closeTo(12 * 7.07 / 24, 0.001));
      expect(keyed.key, 'mark');
      expect(MaterialCheckMark.defaultSize, 18);
    });

    test('names itself for an inspector', () {
      expect(
        MaterialCheckMark(color: BoxColors.red).debugLabel,
        'material-check-mark',
      );
    });
  });
}

/// The strokes of [mark], in the order they are painted: the short arm first.
List<Box> _strokesOf(MaterialCheckMark mark) => mark.children
    .whereType<PositionedNode>()
    .map((PositionedNode node) => node.child)
    .whereType<Box>()
    .toList();

/// The two ends of [stroke], in the square's own coordinates: its middle, moved half
/// its length along the 45 degree line it lies on.
List<BoxPoint> _endsOf(Box stroke) {
  const double diagonal = math.sqrt2 / 2;
  final double half = (stroke.width as double) / 2;
  final double across = (stroke.transform?.rotation ?? 0) > 0
      ? diagonal
      : -diagonal;
  final double centreX = stroke.transform?.offsetX ?? 0;
  final double centreY = stroke.transform?.offsetY ?? 0;

  return <BoxPoint>[
    BoxPoint(centreX - half * diagonal, centreY - half * across),
    BoxPoint(centreX + half * diagonal, centreY + half * across),
  ];
}

/// The point both arms end on, which is the elbow of the tick.
BoxPoint _elbowOf(List<Box> strokes) {
  final List<BoxPoint> first = _endsOf(strokes.first);
  final List<BoxPoint> second = _endsOf(strokes.last);

  for (final BoxPoint one in first) {
    for (final BoxPoint other in second) {
      if ((one.x - other.x).abs() < 0.001 && (one.y - other.y).abs() < 0.001) {
        return one;
      }
    }
  }

  fail('the two arms do not meet: $first and $second');
}
