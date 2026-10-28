import 'ui_node.dart';

/// A node that carries content only a renderer knows how to draw.
///
/// Embeds are the escape hatch for content Unibox does not model: a chart from a
/// Flutter package, a video player component, an effect whose two implementations
/// cannot be one description. Everything around it still lays out with boxes, but
/// nothing is inherited across it — the implementation decides what it renders and
/// how it looks.
///
/// A node carries a list of [implementations] and every renderer draws the first
/// one whose type it understands: a `Widget` on Flutter, a `Component` on the web,
/// a builder that wraps the rendered [child], whatever a renderer of its own
/// chooses to accept. The payloads live here as plain [Object]s on purpose, so
/// this package never learns which platform an implementation is for — a third
/// renderer needs no change in the model, and no API of the model names a target.
///
/// [child] is the content the implementations wrap. An ink ripple, a hover glow or
/// a hero transition is a wrapper and not a leaf, which is why an embed can carry
/// one child; it is exposed through [children], so `validateTree` reaches it like
/// any other subtree.
///
/// A renderer that finds no implementation it can draw throws instead of skipping
/// the node: an embed is a gap in the abstraction, so it has to be a visible one.
///
/// ```dart
/// // The user's own node, with one implementation per target, none of which the
/// // model has ever heard of.
/// final class InkRipple extends EmbedNode {
///   const InkRipple({required UINode child}) : super(child: child);
///
///   @override
///   List<Object> get implementations => const <Object>[
///     MaterialInk(), // draws a Flutter Widget around the child
///     HtmlInk(), // draws a wrapper around the child, on the web
///   ];
/// }
/// ```
abstract class EmbedNode extends UINode {
  /// Creates an embed that wraps [child], or a leaf embed when it is `null`.
  const EmbedNode({super.key, this.child});

  /// The content the implementations wrap, or `null` for a leaf embed.
  final UINode? child;

  /// The implementations of this embed, one per renderer that can draw it.
  ///
  /// The objects are opaque to the model: a renderer looks for the first one it
  /// can draw, and reports the node when it finds none or when it finds two.
  List<Object> get implementations;

  /// The single implementation of a node that only carries one.
  @Deprecated(
    'Use implementations: an embed may carry one implementation per renderer.',
  )
  Object get payload => implementations.first;

  @override
  List<UINode> get children =>
      child == null ? const <UINode>[] : <UINode>[child!];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'embed';
}
