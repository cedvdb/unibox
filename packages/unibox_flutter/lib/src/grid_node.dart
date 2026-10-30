import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'render.dart';

/// Renders a [core.GridNode]: equal columns, computed from the box it is given.
///
/// The count and the cell width come from [core.GridNode.columnsFor] and
/// [core.GridNode.cellWidthFor], the arithmetic the web renderer writes as
/// `repeat(auto-fill, minmax(min(100%, …), 1fr))` — so both targets read the
/// same rule, one from CSS and one from the constraints of the grid itself.
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
