import 'package:unibox_core/unibox_core.dart' as core;

import 'grid_appearance.dart';

/// One grid together with the placement every renderer has to give it.
///
/// A renderer suite renders [node] at [width], reads the tracks back out of its
/// own output and compares them with [expected]. Both suites walk the same entry,
/// so a target cannot be relaxed without failing the other.
final class GridCase {
  /// Creates a case named [description] that lays [node] out at [width].
  const GridCase({
    required this.description,
    required this.node,
    required this.width,
    required this.expected,
  });

  /// What the case is about, as a sentence.
  final String description;

  /// The grid to render.
  ///
  /// Every child carries a key: it is how a renderer is asked which element became
  /// which child, and a list that a reader can point at is a list that answers.
  final core.GridNode node;

  /// The width, in logical pixels, the grid is laid out at.
  ///
  /// A span is counted in tracks and the count comes from the width, so a case
  /// that pins a span has to say the width it is pinned at.
  final double width;

  /// The tracks each child has to occupy.
  final GridAppearance expected;

  /// How many columns the rule gives at [width].
  int get columns => node.columnsFor(width);

  @override
  String toString() => 'GridCase($description)';
}

/// The grids every renderer is checked against.
///
/// The table takes the placement rules one at a time — a child that states no
/// span, a banner that takes two tracks, a span wider than the grid — and states
/// what each target has to end up with at a width where the column count is known.
/// Nothing here is a look: a grid's background or gap is a box token and belongs to
/// the tables beside this one.
const List<GridCase> gridCases = <GridCase>[
  GridCase(
    description: 'gives a child one track when it states no span',
    node: core.GridNode(
      minItemWidth: 280,
      maxColumns: 3,
      gap: 16,
      children: <core.UINode>[
        core.Box(key: 0, height: 40),
        core.Box(key: 1, height: 40),
        core.Box(key: 2, height: 40),
      ],
    ),
    width: 900,
    expected: GridAppearance(spans: <int>[1, 1, 1]),
  ),
  GridCase(
    description: 'lays a banner across two of the three columns',
    // Two cards, a banner the width of two tracks, then the cards after it: the
    // row of a promo that interrupts a listing grid.
    node: core.GridNode(
      minItemWidth: 280,
      maxColumns: 3,
      gap: 16,
      children: <core.UINode>[
        core.Box(key: 0, height: 40),
        core.Box(key: 1, height: 40, gridSpan: 2),
        core.Box(key: 2, height: 40),
        core.Box(key: 3, height: 40),
      ],
    ),
    width: 900,
    expected: GridAppearance(spans: <int>[1, 2, 1, 1]),
  ),
  GridCase(
    description: 'clamps a span wider than the column count',
    // One column at 375: a span of three is one track, which is what a browser
    // does with `grid-column: span 3` in a grid that has one, and what the
    // Flutter renderer does with the same number.
    node: core.GridNode(
      minItemWidth: 280,
      maxColumns: 3,
      gap: 16,
      children: <core.UINode>[
        core.Box(key: 0, height: 40, gridSpan: 3),
        core.Box(key: 1, height: 40),
      ],
    ),
    width: 375,
    expected: GridAppearance(spans: <int>[1, 1]),
  ),
];
