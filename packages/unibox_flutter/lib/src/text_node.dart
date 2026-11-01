import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'scope.dart';
import 'values.dart';

/// Renders a [core.TextNode] as a Flutter [Text].
///
/// Only the typography tokens set on the node are passed to Flutter, so the
/// surrounding `DefaultTextStyle` keeps providing everything else — including
/// the style a box installs from its `textStyle`.
///
/// A node with a [core.TextNode.headingLevel] is wrapped in a `Semantics` with the
/// same level: Flutter has no heading element, so the level is the whole of what
/// the platform can say about it, and the text looks the same either way.
class FlutterText extends StatelessWidget {
  /// Creates a renderer for [node].
  const FlutterText({required this.node, super.key});

  /// The node being rendered.
  final core.TextNode node;

  @override
  Widget build(BuildContext context) {
    final core.TextAlign? align = node.textAlign;
    final core.TextOverflow? overflow = node.overflow;
    final int? level = node.headingLevel;

    final Widget text = Text(
      node.text,
      style: toTextStyle(
        node.computedStyle.resolve(
          UniboxScopeWidget.of(context).theme ?? core.UniboxTheme.none,
        ),
      ),
      textAlign: align == null ? null : toTextAlign(align),
      maxLines: node.maxLines,
      overflow: overflow == null ? null : toTextOverflow(overflow),
    );

    if (level == null) {
      return text;
    }

    // The level is what a screen reader announces and what lets it build the
    // outline of the page, which is the counterpart of the `<h1>`-`<h6>` the web
    // renderer emits. Nothing about the look of the text changes.
    return Semantics(header: true, headingLevel: level, child: text);
  }
}
