import '../callbacks.dart';
import '../tokens/box_color.dart';
import 'ui_node.dart';

/// Where an [OverlayNode] puts its content on the screen.
enum OverlayAlignment {
  /// Centred both ways: where a dialog sits.
  center,

  /// Against the top edge, centred horizontally.
  top,

  /// Against the bottom edge, centred horizontally: where a sheet sits.
  bottom,
}

/// Content drawn above the page instead of in the layout of its parent.
///
/// An overlay is a node like any other: it appears in the tree where the state
/// says it should, and the renderer lifts it above the page and covers the rest
/// with a barrier. There is no `open` flag and no overlay slot on a view — being
/// in the tree *is* being shown, so the store decides presence and this node
/// decides policy.
///
/// ```dart
/// UINode details(StoreFrontState state, StoreFrontStore store) => Box(
///   children: <UINode>[
///     const TextNode('Store front'),
///     if (state.details != null)
///       OverlayNode(
///         onDismiss: store.closeDetails,
///         child: TextNode(state.details!.name),
///       ),
///   ],
/// );
/// ```
///
/// **The renderer presents it.** On Flutter it is an `OverlayPortal` on the root
/// overlay, so it escapes the clipping and scrolling of the boxes around it; on
/// the web a server render draws a fixed layer with the barrier and the
/// alignment, and the interaction — `Escape`, a press on the barrier, keeping
/// focus inside — needs the client runtime.
///
/// **Policy, not presence.** [onDismiss], [barrierDismissible], [barrierColor]
/// and [alignment] say how the overlay behaves. Whether it exists is the tree's
/// answer, which is why leaving is a state change and not a token here.
class OverlayNode extends UINode {
  /// Creates content shown above the page.
  const OverlayNode({
    super.key,
    required this.child,
    this.onDismiss,
    this.barrierDismissible = true,
    this.barrierColor = defaultBarrierColor,
    this.alignment = OverlayAlignment.center,
  });

  /// The scrim Material draws behind a modal: black at 32%.
  static const BoxColor defaultBarrierColor = BoxColor(0x52000000);

  /// The content shown above the page.
  final UINode child;

  /// Called when the user asks to leave: `Escape`, or a press on the barrier
  /// when [barrierDismissible].
  ///
  /// Without it the overlay cannot be dismissed from outside, so the content is
  /// the only way out.
  final TapCallback? onDismiss;

  /// Whether a press on the barrier calls [onDismiss].
  final bool barrierDismissible;

  /// The colour of the barrier between the page and the content.
  final BoxColor barrierColor;

  /// Where the content sits on the screen.
  final OverlayAlignment alignment;

  @override
  List<UINode> get children => <UINode>[child];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'overlay';
}
