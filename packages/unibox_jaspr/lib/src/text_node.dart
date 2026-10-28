import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'labels.dart';
import 'stylesheet.dart';
import 'values.dart';

/// Renders a [core.TextNode] as a styled `<span>`.
///
/// Only the typography tokens set on the node are emitted, so the text keeps
/// inheriting font family, line height and everything else from the page — the
/// same way a Flutter `Text` inherits from `DefaultTextStyle`.
///
/// A [core.TextNode.headingLevel] renders the text as `<h1>`–`<h6>`, with the user
/// agent's heading styles cancelled so the tree still decides how it looks.
///
/// A [core.TextNode.maxLines] is rendered with the `-webkit-line-clamp` box,
/// which is the only way to truncate after a number of lines in CSS. Without
/// `maxLines` a [core.TextOverflow.ellipsis] truncates the single line instead.
class JasprText extends StatelessComponent {
  /// Creates a renderer for [node].
  const JasprText({required this.node, super.key});

  /// The node being rendered.
  final core.TextNode node;

  @override
  Component build(BuildContext context) {
    final int? level = node.headingLevel;
    final List<Component> children = <Component>[Component.text(node.text)];
    final Styles styles = toTextStyles(node);
    final String? className = _className(context, styles);

    if (level == null) {
      return span(
        children,
        classes: className,
        styles: className == null ? styles : null,
        attributes: withNodeLabel(node),
      );
    }

    // A heading is an element here and a `Semantics` level in Flutter, which is
    // the whole of what each platform can say about it. The element brings no
    // look: `toTextStyles` cancels the user agent's heading styles.
    return Component.element(
      tag: 'h$level',
      children: children,
      classes: className,
      styles: className == null ? styles : null,
      attributes: withNodeLabel(node),
    );
  }

  /// The class of [styles] in the rendering in progress, or `null` when the text
  /// is rendered on its own.
  String? _className(BuildContext context, Styles styles) {
    return UniboxStylesheetScope.of(context)?.classFor(
      'text',
      declarationsOf(styles),
      (String name) => <StyleRule>[
        StyleRule(selector: Selector.className(name), styles: styles),
      ],
    );
  }
}
