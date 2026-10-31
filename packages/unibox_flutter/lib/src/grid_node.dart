import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'render.dart';
import 'values.dart';

/// Renders a [core.GridNode], in either of its two forms.
///
/// **A grid that states its columns** is one row of `Expanded` children — the `flex` of an
/// expanded child is the `1fr` of a CSS track — inside an `IntrinsicWidth`, which is what
/// measures the columns before anything is laid out: a flex container reports the largest
/// of its children's intrinsic widths times the flex factors, so the row takes the sum of
/// the factors times the widest content per unit and then divides that between the
/// children. The constraints clamp it, so a parent narrower than the row shrinks every
/// column instead of overhanging it. A node that stretches its columns is measured once
/// more with an `IntrinsicHeight`, because a flex can only stretch a child to a height it
/// already has.
///
/// **A grid that reflows** counts its columns from the box it is given: the count and the
/// cell width come from [core.GridNode.columnsFor] and [core.GridNode.cellWidthFor], the
/// arithmetic the web renderer writes as `repeat(auto-fill, minmax(min(100%, …), 1fr))`,
/// so both targets read the same rule, one from CSS and one from the constraints of the
/// grid itself.
///
/// A short last row is **padded with empty slots** of the same width. `auto-fill`
/// creates every track whether or not a card lands in it, so a row of two cards in
/// a three-track grid leaves the third track empty; stretching the two cards over
/// it would be a different layout on the two targets, which is why nothing here
/// uses `Expanded` or `Flexible`.
///
/// A card that states a `gridSpan` takes that many tracks — the row of the banner
/// that interrupts a card grid — and a span wider than what is left of the row
/// starts a new row instead, leaving the rest of the current one empty. That is
/// what `auto-flow: row` does with `grid-column: span 2`, and the count itself
/// comes from [core.GridNode.spanOf], so both targets clamp a span to the columns
/// the width gives.
///
/// Every card is top-aligned in its row (`align-items: start` on the web), so a
/// row is as tall as its tallest card and shorter cards are not stretched.
class FlutterGrid extends StatelessWidget {
  /// Creates a renderer for [node].
  const FlutterGrid({required this.node, super.key});

  /// The node being rendered.
  final core.GridNode node;

  @override
  Widget build(BuildContext context) {
    if (node.columns != null) {
      return _stated(context);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = node.columnsFor(width);
        final List<Widget> rows = <Widget>[];
        int index = 0;

        while (index < node.children.length) {
          if (rows.isNotEmpty && node.gap > 0) {
            rows.add(SizedBox(height: node.gap));
          }

          final ({List<Widget> slots, int placed}) line = _line(
            index,
            columns,
            width,
          );

          rows.add(
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: line.slots,
            ),
          );

          index += line.placed;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }

  /// The stated form: one row of columns, measured and then divided.
  ///
  /// `LayoutBuilder` is where both halves of the width rule meet: the width the grid was
  /// offered is the width it fills, and a box that offers none — a row that scrolls, or any
  /// parent that hands the space on unbounded — leaves the row to measure itself. That is
  /// `width: 100%` in CSS, which falls back to the content against a box with no width.
  Widget _stated(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool fills = constraints.hasBoundedWidth;
        final double? width = fills ? constraints.maxWidth : null;
        Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: toCrossAxisAlignment(node.resolvedCrossAlign),
          // Stated even when it is not used: a baseline alignment is the one value that
          // needs it, and a flex that leaves it out asserts when it is.
          textBaseline: uniboxTextBaseline,
          children: _columns(width),
        );

        if (node.resolvedCrossAlign == core.CrossAlign.stretch) {
          row = IntrinsicHeight(child: row);
        }

        final Widget measured = IntrinsicWidth(child: row);

        return fills
            ? SizedBox(width: constraints.maxWidth, child: measured)
            : measured;
      },
    );
  }

  /// One widget per column, with the gap between two of them.
  ///
  /// Every child is expanded at its own factor: the grid measured them all and gave each
  /// its width, and `validateTree` reports a `flex` or a width on a column. A child this
  /// width does not draw keeps no column, which is the `display: none` a browser gives it.
  List<Widget> _columns(double? width) {
    final List<int> factors = node.columns!;
    final List<Widget> children = <Widget>[];

    for (var index = 0; index < node.children.length; index++) {
      if (index > 0 && node.gap > 0) {
        children.add(SizedBox(width: node.gap));
      }

      final core.UINode child = node.children[index];
      final Widget rendered = renderNode(child, availableWidth: width);
      final bool shown =
          child is! core.Box ||
          child.computedStyle.isShownAt(width ?? double.infinity);

      children.add(
        shown
            ? Expanded(flex: factors[index], child: rendered)
            : Visibility(
                visible: false,
                maintainState: true,
                child: SizedBox(width: 0, height: 0, child: rendered),
              ),
      );
    }

    return children;
  }

  /// One row of tracks, and how many children it took.
  ///
  /// A child wider than the tracks left in the row is not placed: the row is
  /// padded to its end and that child starts the next one, which is where
  /// `auto-flow: row` puts it.
  ({List<Widget> slots, int placed}) _line(
    int start,
    int columns,
    double width,
  ) {
    final List<Widget> slots = <Widget>[];
    int column = 0;
    int index = start;

    while (index < node.children.length) {
      final int span = node.spanOf(index, columns);

      if (column + span > columns) {
        break;
      }

      if (column > 0 && node.gap > 0) {
        slots.add(SizedBox(width: node.gap));
      }

      slots.add(
        SizedBox(
          width: node.spanWidthFor(span, width),
          child: renderNode(node.children[index]),
        ),
      );

      column += span;
      index++;
    }

    for (; column < columns; column++) {
      if (column > 0 && node.gap > 0) {
        slots.add(SizedBox(width: node.gap));
      }

      slots.add(SizedBox(width: node.cellWidthFor(width)));
    }

    return (slots: slots, placed: index - start);
  }
}
