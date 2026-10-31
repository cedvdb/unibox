import 'dart:math' as math;

import '../enums.dart';
import 'box.dart';
import 'ui_node.dart';

/// A grid: one row of stated columns, or a matrix whose count follows the width.
///
/// ```dart
/// // one row of columns, as `1fr 2fr 1fr` states them
/// GridNode.columns(<int>[1, 2, 1], gap: 12, children: <UINode>[nav, main, aside])
///
/// // and a card grid that reflows without a breakpoint
/// GridNode(minItemWidth: 280, maxColumns: 3, gap: 16, children: listings)
/// ```
///
/// **A stated grid is one row of columns.** [columns] is a flex factor per child — the
/// number `1fr` takes in CSS and the one `Expanded(flex:)` takes in Flutter — and every
/// column is as wide as the widest column per unit, so `[1, 2, 1]` over a `nav` of 80 and
/// a `main` of 200 is one row of 100, 200 and 100. A column is the grid's answer and not
/// the child's: `validateTree` reports a `flex`, a width of its own, a `gridSpan` (the
/// template already says which column each child has) and a template whose length is not
/// the number of children.
///
/// **A grid takes the width it is given, and measures when it is given none.** That is one
/// rule for both forms: a browser writes `width: 100%`, which resolves against the box the
/// grid is in and falls back to the content where that box has no width yet, and Flutter
/// fills the width it is offered on the same terms. It is why a pill of segments hugs
/// inside a row that scrolls and fills the cell it was given.
/// **A reflowing grid fits as many columns as the width allows.** The unnamed constructor
/// states the narrowest a column may get and, optionally, where the count stops, and the
/// tracks then share the width equally. [columnsFor] and [cellWidthFor] are that
/// arithmetic and the web renderer writes it as `repeat(auto-fill, minmax(…))`; the
/// paragraphs below are about it.
///
/// **The width is the box's, not the viewport's.** The browser resolves the rule against
/// the width of the grid itself and Flutter applies [columnsFor] and [cellWidthFor] to the
/// constraints it is given, so the same tree reflows the same way inside a padded column,
/// next to a sidebar or on a phone, and nothing in the tree asks how wide the screen is.
///
/// **The last row keeps its empty tracks.** A row with fewer cards than columns leaves the
/// remaining track empty rather than stretching the cards it has — `auto-fill` creates the
/// tracks, and Flutter pads the row with empty slots of the same width. That is the one
/// distribution rule both targets can honour.
///
/// **A bounded width is what reflows.** Given an unbounded width — inside a horizontal
/// scroll view, or in a row that lets its children be wide — a reflowing grid lays out as
/// one column of [minItemWidth], which is the answer that needs no knowledge of a surface
/// there is none of.
final class GridNode extends UINode {
  /// Creates a grid that reflows, with at least [minItemWidth] per column.
  const GridNode({
    super.key,
    required this.minItemWidth,
    this.maxColumns,
    this.gap = 0,
    this.crossAlign,
    this.children = const <UINode>[],
  }) : columns = null;

  /// Creates a grid of one row, with one flex factor per child in [columns].
  ///
  /// `[1, 2, 1]` is `grid-template-columns: 1fr 2fr 1fr`: the middle column takes twice the
  /// width of the two beside it, and every column is measured from its own content, so the
  /// row hugs at the sum of the factors times the widest content per unit. The list is kept
  /// as it is given, like [children], so a `const` list makes a `const` grid.
  const GridNode.columns(
    this.columns, {
    super.key,
    this.gap = 0,
    this.crossAlign,
    this.children = const <UINode>[],
  }) : minItemWidth = null,
       maxColumns = null;

  /// The narrowest a column may get in a reflowing grid, or `null` for a stated one.
  ///
  /// The count follows from it: a width of `n * minItemWidth + (n - 1) * gap` fits `n`
  /// columns, and one pixel less fits `n - 1`.
  final double? minItemWidth;

  /// The flex factor of each column of a stated grid, or `null` for a reflowing one.
  ///
  /// One entry per child, and one row: a template that does not match the number of
  /// children is reported by `validateTree`, because a row of stated columns has no second
  /// row to flow into on either target.
  final List<int>? columns;

  /// The widest count a reflowing grid may reach, or `null` for no cap.
  ///
  /// A cap is not a breakpoint: the extra width goes to the columns that exist, so three
  /// capped columns keep growing past the width that first fitted them.
  final int? maxColumns;

  /// The space between two columns and between two rows, in logical pixels.
  final double gap;

  /// Where a column sits across the grid, or `null` for [resolvedCrossAlign].
  ///
  /// It is `align-items`: unset is [CrossAlign.start], which keeps a short card at the top
  /// of its row, and [CrossAlign.stretch] makes every column as tall as the tallest — what
  /// a pill of segments wants, where the fill and the tint cover the whole column.
  final CrossAlign? crossAlign;

  /// The alignment the grid lays its columns out with.
  ///
  /// Unset means [CrossAlign.start] and not the browser's default, which stretches: a row
  /// of cards would then be as tall as its tallest card, which the model did not ask for.
  CrossAlign get resolvedCrossAlign => crossAlign ?? CrossAlign.start;

  /// The cards of the grid, in reading order.
  @override
  final List<UINode> children;

  /// How many columns a reflowing grid [width] logical pixels wide holds.
  ///
  /// It is the arithmetic the web renderer expresses as `auto-fill`, so the two targets
  /// can be compared at any width; [double.infinity] — or any other value with no finite
  /// measure — is one column, which is what a grid without a bounded width lays out as.
  /// A stated grid answers with the number of columns it was given, which is its count by
  /// definition.
  int columnsFor(double width) {
    final List<int>? stated = columns;

    if (stated != null) {
      return stated.length;
    }

    if (!width.isFinite) {
      return 1;
    }

    final double unit = minItemWidth! + gap;
    final int fitting = unit > 0 ? ((width + gap) / unit).floor() : 1;
    final int? cap = maxColumns;
    final int limited = cap == null ? fitting : math.min(fitting, cap);

    return math.max(1, limited);
  }

  /// The width of one card in a reflowing grid [width] logical pixels wide.
  ///
  /// The tracks share the width left over after the gutters: `width - (columns - 1) *
  /// gap`, divided by the count. Without a bounded width it is [minItemWidth], the one
  /// column [columnsFor] answers with. A grid that states its columns has no single answer
  /// — each column is its own factor of the content — so this is the reflowing grid's
  /// measurement, and reading it on a stated one is the mistake the assert names.
  double cellWidthFor(double width) {
    assert(
      minItemWidth != null,
      'A stated grid has no cell width: every column is a factor of the content, and only '
      'a renderer that can measure it knows the number.',
    );

    if (!width.isFinite) {
      return minItemWidth ?? 0;
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
