import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'labels.dart';
import 'render.dart';
import 'stylesheet.dart';

/// Renders a [core.GridNode] as one CSS grid.
///
/// The whole reflow is one declaration: `repeat(auto-fill, minmax(min(100%,
/// max(minItemWidth, (100% - (maxColumns - 1) * gap) / maxColumns)), 1fr))`, with
/// `align-items: start` and the gutters in `gap`. `auto-fill` creates the tracks from the width the grid
/// is given, so the browser reflows the cards on its own — no media query, no
/// script, and the same answer after hydration as in the server render.
///
/// The `min(100%, …)` clamp is what makes a container narrower than the minimum
/// behave like [core.GridNode.columnsFor]: the track becomes the whole width
/// instead of overflowing it. The `max(...)` inside is the cap: once the width
/// fits [core.GridNode.maxColumns] columns, the minimum track grows with it, so
/// the count stops there and the cards keep growing.
class JasprGrid extends StatelessComponent {
  /// Creates a renderer for [node].
  const JasprGrid({required this.node, super.key});

  /// The node being rendered.
  final core.GridNode node;

  @override
  Component build(BuildContext context) {
    final Styles styles = Styles(raw: _declarations());
    final List<Component> children = node.children
        .map(renderNode)
        .toList(growable: false);
    final UniboxStylesheet? sheet = UniboxStylesheetScope.of(context);

    if (sheet != null) {
      final String className = sheet.classFor(
        'grid',
        declarationsOf(styles),
        (String name) => <StyleRule>[
          StyleRule(selector: Selector.className(name), styles: styles),
        ],
      );

      return div(children, classes: className, attributes: withNodeLabel(node));
    }

    return div(children, styles: styles, attributes: withNodeLabel(node));
  }

  Map<String, String> _declarations() {
    return <String, String>{
      'display': 'grid',
      // A grid takes the width it is given: the tracks are counted from it, which
      // is what the Flutter renderer does with the constraints of the same box. A
      // block-level grid already fills its parent, but a box aligns its children to
      // the start by default, and a flex item that is not stretched shrinks to fit
      // — where `auto-fill` would then find room for exactly one column.
      'width': '100%',
      'min-width': '0',
      if (node.gap > 0) 'gap': _pixels(node.gap),
      'align-items': 'start',
      'grid-template-columns': _tracks(),
    };
  }

  String _tracks() {
    final String minimum = _pixels(node.minItemWidth);
    final int? cap = node.maxColumns;

    if (cap == null) {
      return 'repeat(auto-fill, minmax(min(100%, $minimum), 1fr))';
    }

    final double gutters = (cap - 1) * node.gap;
    final String share = gutters == 0
        ? '100% / $cap'
        : '(100% - ${_pixels(gutters)}) / $cap';

    return 'repeat(auto-fill, minmax(min(100%, max($minimum, $share)), 1fr))';
  }

  /// A length in CSS: a whole number without a decimal point, as CSS reads it.
  String _pixels(double value) {
    return value == value.roundToDouble() ? '${value.toInt()}px' : '${value}px';
  }
}
