/// Pure Dart layout primitives shared by every Unibox renderer.
///
/// This library is intentionally free of platform dependencies: it never
/// imports `dart:ui`, Flutter or Jaspr, so it can be consumed from command line
/// tools, servers and both UI targets alike.
///
/// The public API is composed of:
/// * style tokens ([BoxColor], [BoxColors], [BoxSpacing], [BoxStyle],
///   [BoxBorder], [BoxShadow]),
/// * layout enums ([Axis], [MainAlign], [CrossAlign], [Overflow], [ImageFit],
///   [FontWeight], [TextAlign], [TextOverflow]),
/// * the immutable node tree rooted in [UINode]: [Box], [TextNode],
///   [ImageNode], [LinkNode], [StackNode], [PositionedNode],
///   [TextInputNode], [OverlayNode] and [StatefulNode], which adds a subtree
///   that owns its state,
/// * [Store], the state a [StatefulNode] draws, and [validateTree], which
///   reports nodes that a renderer cannot honour.
library;

export 'src/callbacks.dart';
export 'src/enums.dart';
export 'src/events.dart';
export 'src/nodes/box.dart';
export 'src/nodes/embed_node.dart';
export 'src/nodes/grid_node.dart';
export 'src/nodes/image_node.dart';
export 'src/nodes/link_node.dart';
export 'src/nodes/overlay_node.dart';
export 'src/nodes/positioned_node.dart';
export 'src/nodes/stack_node.dart';
export 'src/nodes/stateful_node.dart';
export 'src/nodes/text_input_node.dart';
export 'src/nodes/text_node.dart';
export 'src/nodes/ui_node.dart';
export 'src/state/state_store.dart';
export 'src/state/store.dart';
export 'src/tokens/box_border.dart';
export 'src/tokens/box_color.dart';
export 'src/tokens/box_colors.dart';
export 'src/tokens/box_corners.dart';
export 'src/tokens/box_semantics.dart';
export 'src/tokens/box_shadow.dart';
export 'src/tokens/box_spacing.dart';
export 'src/tokens/box_style.dart';
export 'src/tokens/box_text_style.dart';
export 'src/tokens/box_transform.dart';
export 'src/tokens/box_transition.dart';
export 'src/tokens/unibox_theme.dart';
export 'src/validation.dart';
