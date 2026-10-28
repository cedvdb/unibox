import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

void main() {
  group('the corners of a box', () {
    test('are square unless a corner is named', () {
      const BoxBorderRadius corners = BoxBorderRadius();

      expect(corners.radii, <double>[0, 0, 0, 0]);
      expect(corners.isUniform, isTrue);
      expect(corners.isSquare, isTrue);
    });

    test('take one radius for all four', () {
      const BoxBorderRadius corners = BoxBorderRadius.all(8);

      expect(corners.radii, <double>[8, 8, 8, 8]);
      expect(corners.isUniform, isTrue);
      expect(corners.isSquare, isFalse);
    });

    test('round the two a filled field rounds, in CSS order', () {
      const BoxBorderRadius corners = BoxBorderRadius(topLeft: 4, topRight: 4);

      expect(corners.radii, <double>[4, 4, 0, 0]);
      expect(corners.isUniform, isFalse);
      expect(corners.isSquare, isFalse);
    });

    test('are equal when every corner matches', () {
      expect(
        const BoxBorderRadius.all(4),
        const BoxBorderRadius(
          topLeft: 4,
          topRight: 4,
          bottomRight: 4,
          bottomLeft: 4,
        ),
      );
      expect(
        const BoxBorderRadius.all(4),
        isNot(const BoxBorderRadius(topLeft: 4)),
      );
    });

    test('reach the resolved style of a box', () {
      const Box box = Box(corners: BoxBorderRadius(topLeft: 4, topRight: 4));

      expect(
        box.computedStyle.corners,
        const BoxBorderRadius(topLeft: 4, topRight: 4),
      );
    });
  });

  group('a box that sets both a radius and corners', () {
    test('is reported, since only one shape can be drawn', () {
      final List<TreeIssue> issues = validateTree(
        const Box(borderRadius: 8, corners: BoxBorderRadius(topLeft: 4)),
      );

      expect(
        issues.map((TreeIssue issue) => issue.message),
        contains(contains('both borderRadius and corners')),
      );
    });
  });
}
