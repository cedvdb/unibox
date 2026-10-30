import 'dart:math' as math;

import 'box.dart';
import 'ui_node.dart';

/// A grid of equal columns whose count follows the width of the box.
///
/// The rule is one line of arithmetic and no breakpoint: fit as many
/// [minItemWidth] columns as the width allows, cap the count at [maxColumns],
/// and let the tracks share the width equally.
///
/// ```dart
/// GridNode(
///   minItemWidth: 280,
///   maxColumns: 3,
///   gap: 16,
///   children: listings,
/// )
/// ```
///
/// **The width is the box's, not the viewport's.** A web renderer turns the rule
/// into `grid-template-columns: repeat(auto-fill, minmax(min(100%, max(280px,
/// (100% - 32px) / 3)), 1fr))`, which the browser resolves against the width of
/// the grid itself; the Flutter renderer applies [columnsFor] and
/// [cellWidthFor] to the constraints it is given. That is why the same tree
/// reflows the same way inside a padded column, next to a sidebar or on a phone,
/// and why nothing in the tree has to ask how wide the screen is.
///
/// **The last row keeps its empty tracks.** A row with fewer cards than columns
/// leaves the remaining track empty rather than stretching the cards it has —
/// `auto-fill` creates the tracks, and Flutter pads the row with empty slots of
/// the same width. That is the one distribution rule both targets can honour.
///
/// **Children do not size or flex themselves.** The track fixes every card's
/// width and the row fixes its height: `validateTree` reports a child that
/// declares a finite `width`, a `flex`, or an infinite `height`, because CSS and
/// Flutter would not agree about what those mean inside a track.
///
/// **A bounded width is what reflows.** Given an unbounded width — inside a
/// horizontal scroll view, or in a row that lets its children be wide — the grid
/// lays out as one column of [minItemWidth], which is the answer that needs no
/// knowledge of a surface there is none of.
final class GridNode extends UINode {
  /// Creates a grid of [children] with at least [minItemWidth] per column.
  const GridNode({
    super.key,
    required this.minItemWidth,
    this.maxColumns,
    this.gap = 0,
    this.children = const <UINode>[],
  });

  /// The narrowest a column may get, in logical pixels.
  ///
  /// The count follows from it: a width of `n * minItemWidth + (n - 1) * gap`
  /// fits `n` columns, and one pixel less fits `n - 1`.
  final double minItemWidth;

  /// The widest count the grid may reach, or `null` for no cap.
  ///
  /// A cap is not a breakpoint: the extra width goes to the columns that exist,
  /// so three capped columns keep growing past the width that first fitted them.
  final int? maxColumns;

  /// The space between two columns and between two rows, in logical pixels.
  final double gap;

  /// The cards of the grid, in reading order.
  @override
  final List<UINode> children;

  /// How many columns a grid [width] logical pixels wide holds.
  ///
  /// It is the arithmetic the web renderer expresses as `auto-fill`, so the two
  /// targets can be compared at any width; [double.infinity] — or any other
  /// value with no finite measure — is one column, which is what a grid without
  /// a bounded width lays out as.
  int columnsFor(double width) {
    if (!width.isFinite) {
      return 1;
    }

    final double unit = minItemWidth + gap;
    final int fitting = unit > 0 ? ((width + gap) / unit).floor() : 1;
    final int? cap = maxColumns;
    final int limited = cap == null ? fitting : math.min(fitting, cap);

    return math.max(1, limited);
  }

  /// The width of one card in a grid [width] logical pixels wide.
  ///
  /// The tracks share the width left over after the gutters: `width - (columns
  /// - 1) * gap`, divided by the count. Without a bounded width it is
  /// [minItemWidth], the one column [columnsFor] answers with.
  double cellWidthFor(double width) {
    if (!width.isFinite) {
      return minItemWidth;
    }

    final int columns = columnsFor(width);

    return (width - (columns - 1) * gap) / columns;
  }

  /// How many of [columns] tracks the child at [index] occupies.
  ///
  /// A child takes one track unless it is a `Box` that states `gridSpan`, and a
  /// span wider than the grid is clamped to its count — which is what a browser
  /// does with `grid-column: span 2` in a grid with one track, and the reason both
  /// targets keep `auto-fill`: a span cannot add a column, because the count is
  /// what the width gives.
  int spanOf(int index, int columns) {
    final UINode child = children[index];
    final int declared = child is Box ? child.computedStyle.gridSpan ?? 1 : 1;

    return math.min(math.max(declared, 1), math.max(columns, 1));
  }

  /// The width of a child that spans [span] tracks of a grid [width] wide,
  /// gutters included.
  ///
  /// It is the one measurement a renderer needs to give a spanning card its row:
  /// `span` tracks and the `span - 1` gutters between them.
  double spanWidthFor(int span, double width) {
    final double cell = cellWidthFor(width);

    return span * cell + (span - 1) * gap;
  }

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'grid';
}
