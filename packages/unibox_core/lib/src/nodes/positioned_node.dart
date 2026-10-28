import 'ui_node.dart';

/// A child of a [StackNode] placed at an absolute offset.
///
/// At least one of [top], [right], [bottom] or [left] should be set; unset
/// edges keep the child at its natural position.
class PositionedNode extends UINode {
  /// Creates a positioned node.
  const PositionedNode({
    super.key,
    this.top,
    this.right,
    this.bottom,
    this.left,
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

  /// The node to position.
  final UINode child;

  /// Whether no offset is set at all.
  bool get isUnpositioned =>
      top == null && right == null && bottom == null && left == null;

  @override
  List<UINode> get children => <UINode>[child];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'positioned';
}
