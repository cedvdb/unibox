import '../enums.dart';
import 'ui_node.dart';

/// A child of a [StackNode] placed by offsets, or by an [alignment].
///
/// At least one of [top], [right], [bottom] or [left] should be set; unset
/// edges keep the child at its natural position.
///
/// [alignment] is the other way to place it, and the one a floating control wants:
/// the child fills the stack and the alignment says where in it the child sits, so a
/// button pinned to the bottom centre stays there whatever the window is. The two are
/// alternatives — a node that states both is reported by `validateTree`.
class PositionedNode extends UINode {
  /// Creates a positioned node.
  const PositionedNode({
    super.key,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.alignment,
    required this.child,
  });

  /// The offset from the top edge of the stack in logical pixels.
  final double? top;

  /// The offset from the right edge of the stack in logical pixels.
  final double? right;

  /// The offset from the bottom edge of the stack in logical pixels.
  final double? bottom;

  /// The offset from the left edge of the stack in logical pixels.
  final double? left;

  /// Where in the stack the child sits, instead of at an offset.
  ///
  /// The child fills the stack and the alignment places it within that cell, which is
  /// what a floating button is: the same tree at every window, and no measurement of
  /// one. A child that needs a distance from the edge states it as its own `margin`.
  final BoxAlignment? alignment;

  /// The node to position.
  final UINode child;

  /// Whether no offset is set at all.
  bool get isUnpositioned =>
      top == null && right == null && bottom == null && left == null;

  /// Whether the child is placed by [alignment] rather than by an offset.
  bool get isAligned => alignment != null;

  @override
  List<UINode> get children => <UINode>[child];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'positioned';
}
