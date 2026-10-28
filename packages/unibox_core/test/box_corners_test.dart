import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

void main() {
  group('the corners of a box', () {
    test('are square unless a corner is named', () {
      const BoxCorners corners = BoxCorners();

      expect(corners.radii, <double>[0, 0, 0, 0]);
      expect(corners.isUniform, isTrue);
      expect(corners.isSquare, isTrue);
    });

    test('take one radius for all four', () {
      const BoxCorners corners = BoxCorners.all(8);

      expect(corners.radii, <double>[8, 8, 8, 8]);
      expect(corners.isUniform, isTrue);
      expect(corners.isSquare, isFalse);
    });

    test('round the two a filled field rounds, in CSS order', () {
      const BoxCorners corners = BoxCorners(topLeft: 4, topRight: 4);

      expect(corners.radii, <double>[4, 4, 0, 0]);
      expect(corners.isUniform, isFalse);
      expect(corners.isSquare, isFalse);
    });

    test('are equal when every corner matches', () {
      expect(
        const BoxCorners.all(4),
        const BoxCorners(
          topLeft: 4,
          topRight: 4,
          bottomRight: 4,
          bottomLeft: 4,
        ),
      );
      expect(const BoxCorners.all(4), isNot(const BoxCorners(topLeft: 4)));
    });

    test('reach the resolved style of a box', () {
      const Box box = Box(corners: BoxCorners(topLeft: 4, topRight: 4));

      expect(
        box.computedStyle.corners,
        const BoxCorners(topLeft: 4, topRight: 4),
      );
    });
  });

  group('a box that sets both a radius and corners', () {
    test('is reported, since only one shape can be drawn', () {
      final List<TreeIssue> issues = validateTree(
        const Box(borderRadius: 8, corners: BoxCorners(topLeft: 4)),
      );

      expect(
        issues.map((TreeIssue issue) => issue.message),
        contains(contains('both borderRadius and corners')),
      );
    });
  });
}
