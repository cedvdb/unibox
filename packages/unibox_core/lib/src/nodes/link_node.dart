import '../callbacks.dart';
import 'ui_node.dart';

/// A hyperlink wrapping a single [child].
///
/// Renders a native `<a>` element on the web and a tappable region that opens
/// the [url] on Flutter.
class LinkNode extends UINode {
  /// Creates a link node.
  const LinkNode(
    this.url, {
    super.key,
    required this.child,
    this.newTab = false,
    this.onTap,
  });

  /// The destination of the link.
  final String url;

  /// The content of the link.
  final UINode child;

  /// Whether the destination should open in a new tab on the web.
  final bool newTab;

  /// Called when the link is pressed, instead of following [url].
  ///
  /// A link with this callback is handled by the tree: on the web a plain click is
  /// cancelled before the browser follows [url], so a page whose runtime answers the
  /// press does not also load the document the link names, and on Flutter the
  /// enclosing opener is not called. [url] stays on the anchor either way, which is
  /// what keeps the link working on a page without the runtime, in a new tab, in a
  /// context menu and for a crawler.
  ///
  /// Leave it unset for a link that is a destination rather than a press: a static
  /// page with no runtime has no other way to reach what it points at.
  final TapCallback? onTap;

  @override
  List<UINode> get children => <UINode>[child];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'link';
}
