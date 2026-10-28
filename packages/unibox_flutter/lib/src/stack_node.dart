import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'keys.dart';
import 'render.dart';
import 'values.dart';

/// Renders a [core.StackNode] as a Flutter [Stack].
///
/// Children are painted in order, so the last child ends up on top. Children
/// that are not [core.PositionedNode]s keep their natural size in the corner
/// [alignment] names, the top start one unless a box said otherwise. Like CSS
/// `overflow: visible`, the stack does not clip its content.
class FlutterStack extends StatelessWidget {
  /// Creates a renderer for [node].
  ///
  /// [alignment] is where the children that are not positioned sit, and it is the
  /// alignment of the box around the stack: a box that holds only a layer keeps its
  /// own main and cross alignment for what the layer draws, which is what a browser
  /// does with a flex container whose one flow child is the layer. A stack that fills
  /// the box and tops its children out would otherwise put a centred label at the top.
  const FlutterStack({required this.node, this.alignment, super.key});

  /// The node being rendered.
  final core.StackNode node;

  /// Where the non-positioned children of the stack sit, or `null` for the top
  /// start corner.
  final core.BoxAlignment? alignment;

  @override
  Widget build(BuildContext context) {
    final core.BoxAlignment? alignment = this.alignment;

    Widget content = Stack(
      clipBehavior: Clip.none,
      alignment: alignment == null
          ? AlignmentDirectional.topStart
          : toDirectionalAlignment(alignment),
      children: <Widget>[
        for (final core.UINode child in node.children) _child(child),
      ],
    );

    if (node.width != null || node.height != null) {
      content = SizedBox(
        width: node.width,
        height: node.height,
        child: content,
      );
    }

    return content;
  }

  /// Renders [node] as a stack child, honouring its absolute offsets.
  Widget _child(core.UINode node) {
    if (node is! core.PositionedNode) {
      return renderNode(node);
    }

    final Widget child = renderNode(node.child);

    // An aligned child fills the cell and the alignment places it inside that: the
    // same statement as `position: absolute; inset: 0` with a flex alignment, and
    // what puts a floating button at the bottom centre of the surface it floats over.
    final core.BoxAlignment? alignment = node.alignment;

    if (alignment != null) {
      return Positioned.fill(
        key: toFlutterKey(node.key),
        child: Align(alignment: toAlignment(alignment), child: child),
      );
    }

    if (node.isUnpositioned) {
      return child;
    }

    return Positioned(
      key: toFlutterKey(node.key),
      top: node.top,
      right: node.right,
      bottom: node.bottom,
      left: node.left,
      child: child,
    );
  }
}
