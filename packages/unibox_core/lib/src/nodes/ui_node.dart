/// Base class of every node in the Unibox tree.
///
/// Nodes are immutable descriptions of a piece of UI. Renderers translate them
/// to Flutter widgets or to Jaspr components.
///
/// Custom nodes may extend this class, renderers will report nodes they do not
/// support.
///
/// ## Naming
///
/// A node only carries the `Node` suffix when its bare name would collide with
/// a Flutter widget that consumers import next to this package. `Text`, `Image`,
/// `Stack`, `Positioned` and `Link` all exist in `flutter/widgets.dart`, so
/// those nodes are named `TextNode`, `ImageNode`, `StackNode`,
/// `PositionedNode` and `LinkNode`. `Box` has no Flutter counterpart and
/// stays unsuffixed.
abstract class UINode {
  /// Creates a node.
  const UINode({this.key});

  /// The identity of this node among its siblings.
  ///
  /// Renderers use it to keep state attached to the node it belongs to when a
  /// list is reordered or filtered. Without a key, a child inherits the state of
  /// whatever node previously occupied its position, which is why a reordered
  /// `TextInputNode` can show the text typed into a different row.
  ///
  /// Keys must be unique among the children of one parent and stable across
  /// rebuilds: the id of the model the node describes is the usual choice.
  /// Flutter renders it as a `ValueKey`, Jaspr as a component `ValueKey`.
  final Object? key;

  /// The direct child nodes of this node in paint order.
  ///
  /// Leaf nodes return an empty list.
  List<UINode> get children => const <UINode>[];

  /// The name this node answers to, or `null` when it names nothing.
  ///
  /// A renderer may write [debugName] on the element it draws, so an element in
  /// a browser's inspector says which node produced it. It is a development aid
  /// and nothing else: it is never styled, never part of a class name, never read by
  /// a layout, and it carries no look to turn off.
  ///
  /// A name is a **literal**, never the type's: a compiled build mangles class
  /// names, so a name derived from `runtimeType` reads `minified:-s` in a browser and
  /// is unfit to ship. Every node of `unibox_core` and of `unibox_material` states
  /// one, and a node of your own names itself by overriding this — one line, and the
  /// only spelling that survives every build. A subclass that says nothing inherits
  /// the name of the node it extends, so a design system names its components.
  String? get debugLabel => null;

  /// The name a developer reads for this node: [debugLabel], else `node`.
  String get debugName => debugLabel ?? 'node';
}
