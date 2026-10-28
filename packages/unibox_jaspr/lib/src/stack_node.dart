import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'keys.dart';
import 'labels.dart';
import 'render.dart';
import 'stylesheet.dart';
import 'values.dart';

/// Renders a [core.StackNode] as a layering container.
///
/// The element is a relative grid whose children all share one cell, so they
/// overlap each other and are painted in source order (last on top). The
/// container still sizes to its largest child, matching a Flutter `Stack`, and
/// it never clips its content, matching `Clip.none`.
///
/// A child that is not a [core.PositionedNode] is wrapped in a grid cell, which
/// is the CSS equivalent of placing it at the top start corner of the stack.
class JasprStack extends StatelessComponent {
  /// Creates a renderer for [node].
  const JasprStack({required this.node, super.key});

  /// The node being rendered.
  final core.StackNode node;

  @override
  Component build(BuildContext context) {
    final Styles styles = toStackStyles(node);
    final String? className = _className(context, styles);

    return div(
      <Component>[
        for (final core.UINode child in node.children) _stackChild(child),
      ],
      classes: className,
      styles: className == null ? styles : null,
      attributes: withNodeLabel(node),
    );
  }

  /// The class of [styles] in the rendering in progress, or `null` without one.
  String? _className(BuildContext context, Styles styles) =>
      UniboxStylesheetScope.of(context)?.classFor(
        'stack',
        declarationsOf(styles),
        (String name) => <StyleRule>[
          StyleRule(selector: Selector.className(name), styles: styles),
        ],
      );
}

/// Renders a [core.PositionedNode] as an absolutely positioned element.
///
/// A positioned node without any offset keeps its natural place, exactly like a
/// `Positioned` widget that was never needed: it is rendered as a regular stack
/// child. Rendering the node on its own falls back to its child, since there is
/// no stack to position it in.
///
/// A node with an [core.BoxAlignment] fills the stack instead and its child is placed
/// by a flex alignment inside that — `inset: 0` and a `justify-content`/
/// `align-items` pair, which is the `Positioned.fill` and `Align` of the other target.
class JasprPositioned extends StatelessComponent {
  /// Creates a renderer for [node].
  const JasprPositioned({required this.node, super.key});

  /// The node being rendered.
  final core.PositionedNode node;

  @override
  Component build(BuildContext context) {
    final Component child = renderNode(node.child);

    final core.BoxAlignment? alignment = node.alignment;
    final Styles styles = alignment != null
        ? toAlignedStyles(alignment)
        : node.isUnpositioned
        ? toStackChildStyles()
        : toPositionedStyles(node);
    final String? className = UniboxStylesheetScope.of(context)?.classFor(
      'stack-child',
      declarationsOf(styles),
      (String name) => <StyleRule>[
        StyleRule(selector: Selector.className(name), styles: styles),
      ],
    );

    return div(
      <Component>[child],
      classes: className,
      styles: className == null ? styles : null,
      attributes: withNodeLabel(node),
    );
  }
}

/// Renders a plain child of a stack: the cell wrapper that keeps its own size.
class JasprStackChild extends StatelessComponent {
  /// Creates the wrapper around [child].
  const JasprStackChild({required this.child, super.key});

  /// The rendered child.
  final Component child;

  @override
  Component build(BuildContext context) {
    final Styles styles = toStackChildStyles();
    final String? className = UniboxStylesheetScope.of(context)?.classFor(
      'stack-child',
      declarationsOf(styles),
      (String name) => <StyleRule>[
        StyleRule(selector: Selector.className(name), styles: styles),
      ],
    );

    return div(
      <Component>[child],
      classes: className,
      styles: className == null ? styles : null,
    );
  }
}

/// Renders [node] as a child of a stack.
Component _stackChild(core.UINode node) {
  if (node is core.PositionedNode) {
    return JasprPositioned(node: node, key: toJasprKey(node.key));
  }

  return JasprStackChild(child: renderNode(node), key: toJasprKey(node.key));
}
