import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// A grid with the example's rule: 280 wide, three columns at most, 16 gutters.
const GridNode _grid = GridNode(minItemWidth: 280, maxColumns: 3, gap: 16);

void main() {
  group('GridNode arithmetic', () {
    test('fits one column below the first two-column width', () {
      // 250 is narrower than the minimum, which is what the CSS clamp is for.
      expect(_grid.columnsFor(250), 1);
      expect(_grid.cellWidthFor(250), 250);
      expect(_grid.columnsFor(375), 1);
      expect(_grid.cellWidthFor(375), 375);
    });

    test('fits a column when the gutters fit with it', () {
      // Two columns fit when 2 * 280 + 16 = 576 does: one pixel less does not.
      expect(_grid.columnsFor(600), 2);
      expect(_grid.cellWidthFor(600), 292);
      expect(_grid.columnsFor(575), 1);
      expect(_grid.columnsFor(576), 2);
    });

    test('fits three columns at the width the third one asks for', () {
      // Three columns fit when 3 * 280 + 2 * 16 = 872 does.
      expect(_grid.columnsFor(899), 3);
      expect(_grid.cellWidthFor(899), 289);
      expect(_grid.columnsFor(880), 3);
      expect(_grid.columnsFor(871), 2);
      expect(_grid.columnsFor(872), 3);
      expect(_grid.cellWidthFor(900), closeTo(289.3333, 0.0001));
    });

    test('grows the columns past the cap instead of adding a fourth', () {
      // The cap is not a breakpoint: 1280 fits four columns of 280, and the cap
      // gives three columns of 416 instead.
      expect(_grid.columnsFor(1280), 3);
      expect(_grid.cellWidthFor(1280), 416);
    });

    test('has no cap when it names none', () {
      const GridNode open = GridNode(minItemWidth: 280, gap: 16);

      expect(open.columnsFor(1280), 4);
      expect(open.cellWidthFor(1280), 308);
    });

    test('lays out as one column at its minimum without a bounded width', () {
      // A grid inside a horizontal scroll view is given no width to divide.
      expect(_grid.columnsFor(double.infinity), 1);
      expect(_grid.cellWidthFor(double.infinity), 280);
      expect(_grid.columnsFor(double.nan), 1);
    });

    test('keeps a zero gap out of the arithmetic', () {
      const GridNode tight = GridNode(minItemWidth: 100);

      expect(tight.columnsFor(300), 3);
      expect(tight.cellWidthFor(300), 100);
    });

    test('gives a child one track unless it names a span', () {
      const GridNode grid = GridNode(
        minItemWidth: 280,
        maxColumns: 3,
        gap: 16,
        children: <UINode>[Box(height: 40), Box(height: 40, gridSpan: 2)],
      );

      expect(grid.spanOf(0, 3), 1);
      expect(grid.spanOf(1, 3), 2);
    });

    test('clamps a span to the columns the width gives', () {
      // A browser clamps `grid-column: span 3` in a grid that has one track, and
      // the model answers the same way rather than laying a card out twice.
      const GridNode grid = GridNode(
        minItemWidth: 280,
        children: <UINode>[Box(height: 40, gridSpan: 3), Box(height: 40)],
      );

      expect(grid.columnsFor(375), 1);
      expect(grid.spanOf(0, 1), 1);
      expect(grid.spanOf(0, 2), 2);
    });

    test('measures a spanning cell as its tracks and the gutters between', () {
      // One card of two tracks is two cells and the gutter the second cell starts
      // after, which is the width both renderers have to give it.
      const GridNode grid = GridNode(minItemWidth: 280, maxColumns: 3, gap: 16);
      final double cell = grid.cellWidthFor(900);

      expect(grid.spanWidthFor(1, 900), closeTo(cell, 0.0001));
      expect(grid.spanWidthFor(2, 900), closeTo(cell * 2 + 16, 0.0001));
      expect(grid.spanWidthFor(3, 900), closeTo(900, 0.0001));
    });
  });

  group('GridNode validation', () {
    List<TreeIssue> issuesOf(UINode root) => validateTree(root);

    test('accepts a grid of plain cards', () {
      expect(
        issuesOf(
          const GridNode(
            minItemWidth: 280,
            maxColumns: 3,
            gap: 16,
            children: <UINode>[Box(height: 40), Box(height: 40)],
          ),
        ),
        isEmpty,
      );
    });

    test('reports a child that flexes', () {
      final List<TreeIssue> issues = issuesOf(
        const GridNode(minItemWidth: 280, children: <UINode>[Box(flex: 1)]),
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('flex'));
    });

    test('reports a child with a finite width', () {
      final List<TreeIssue> issues = issuesOf(
        const GridNode(minItemWidth: 280, children: <UINode>[Box(width: 200)]),
      );

      expect(issues.single.message, contains('width of 200.0'));
    });

    test('accepts a child that fills the track', () {
      expect(
        issuesOf(
          const GridNode(
            minItemWidth: 280,
            children: <UINode>[Box(width: double.infinity, height: 40)],
          ),
        ),
        isEmpty,
      );
    });

    test('accepts a banner that spans two tracks', () {
      expect(
        issuesOf(
          const GridNode(
            minItemWidth: 280,
            maxColumns: 3,
            children: <UINode>[Box(height: 40), Box(height: 40, gridSpan: 2)],
          ),
        ),
        isEmpty,
      );
    });

    test('reports a span on a box that is not a grid child', () {
      final List<TreeIssue> issues = issuesOf(
        const Box(children: <UINode>[Box(height: 40, gridSpan: 2)]),
      );

      expect(issues.single.isError, isFalse);
      expect(issues.single.message, contains('no grid to span'));
    });

    test('reports a span of zero, which no track can hold', () {
      final List<TreeIssue> issues = issuesOf(
        const GridNode(
          minItemWidth: 280,
          children: <UINode>[Box(height: 40, gridSpan: 0)],
        ),
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('one track or more'));
    });

    test('reports a child with an infinite height', () {
      final List<TreeIssue> issues = issuesOf(
        const GridNode(
          minItemWidth: 280,
          children: <UINode>[Box(height: double.infinity)],
        ),
      );

      expect(issues.single.message, contains('infinity'));
    });

    test('reports parameters that leave no column', () {
      expect(
        issuesOf(const GridNode(minItemWidth: 0)).single.message,
        contains('minItemWidth'),
      );
      expect(
        issuesOf(const GridNode(minItemWidth: 100, gap: -1)).single.message,
        contains('gap'),
      );
      expect(
        issuesOf(const GridNode(minItemWidth: 100, maxColumns: 0))
            .single
            .message,
        contains('maxColumns'),
      );
    });

    test('reports a photo whose height waits for the file', () {
      final List<TreeIssue> issues = issuesOf(
        const GridNode(
          minItemWidth: 280,
          children: <UINode>[ImageNode('photo.jpg', width: double.infinity)],
        ),
      );

      expect(issues.single.message, contains('before the file arrives'));
    });

    test('accepts a photo with a reserved box', () {
      expect(
        issuesOf(
          const GridNode(
            minItemWidth: 280,
            children: <UINode>[
              Box(height: 200, children: <UINode>[ImageNode('photo.jpg')]),
            ],
          ),
        ),
        isEmpty,
        reason:
            'A box with a finite height gives the photo below it a height to '
            'resolve against, which is what the ratio box will do too.',
      );
    });
  });
}
