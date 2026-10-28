import 'package:unibox_core/unibox_core.dart' as core;

/// Renders markup this target draws and the model does not describe.
///
/// The escape hatch for a web component, a `<video>`, a chart from another package — a
/// piece of a page whose content is the host's and not a node. Everything around it still
/// lays out with boxes, and nothing is inherited across the boundary: the element decides
/// what it renders and how.
///
/// ```dart
/// Box(
///   children: <core.UINode>[HtmlEmbed('<sl-button>Save</sl-button>')],
/// )
/// ```
///
/// **The markup is written as it is, not escaped.** That is the whole point of the node and
/// the whole risk of it: a `String` this target trusts. Never build one from data a reader
/// supplied — a tree carrying one is a tree that can inject.
///
/// The Flutter renderer cannot draw an `HtmlEmbed` and reports it, which is where an
/// implementation of your own belongs: a node carries one payload per target, and this is
/// the web's half.
final class HtmlEmbed extends core.EmbedNode {
  /// Wraps [html] as a node.
  const HtmlEmbed(this.html, {super.key});

  /// The markup to write.
  final String html;

  /// The payloads a renderer may draw, which for this target is the markup itself.
  @override
  List<Object> get implementations => <Object>[html];
}
