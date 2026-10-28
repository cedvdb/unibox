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

  /// Called when the link is tapped, in addition to following [url].
  final TapCallback? onTap;

  @override
  List<UINode> get children => <UINode>[child];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'link';
}
