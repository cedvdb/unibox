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

  /// The name a developer should read for this node, or `null` to derive one
  /// from the type.
  ///
  /// A renderer may write [debugName] on the element it draws, so an element in
  /// a browser's inspector says which node produced it. It is a development
  /// aid and nothing else: it is never styled, never part of a class name, never
  /// read by a layout, and absent unless the host asks for it.
  ///
  /// Override it when the type name is not the name to show — a subclass whose
  /// own name is a detail of a package, or when a build minifies type names.
  String? get debugLabel => null;

  /// The name that identifies this node to a developer: [debugLabel], else the
  /// kebab-cased type without its `Node` suffix.
  ///
  /// `TextNode` reads `text`, `GridNode` reads `grid`, `MaterialCard` reads
  /// `material-card`, a private class loses its underscore and a generic type
  /// keeps only its own name.
  ///
  /// A derived name is read from the runtime type, so it is only meaningful in
  /// an unobfuscated build; [debugLabel] is the stable spelling.
  String get debugName => debugLabel ?? _kebabCase(runtimeType.toString());
}

/// [name] in kebab case, without generics, a leading underscore or a `Node`
/// suffix.
///
/// Written as a loop rather than a look-behind pattern: this package is compiled
/// to JavaScript, where a look-behind is a syntax error on the browsers that do
/// not have it.
String _kebabCase(String name) {
  final String bare = name.split('<').first.replaceFirst(RegExp('^_+'), '');
  final StringBuffer buffer = StringBuffer();

  for (var index = 0; index < bare.length; index++) {
    final String character = bare[index];
    final bool isUpper =
        character.toUpperCase() == character &&
        character.toLowerCase() != character;

    if (isUpper && index > 0) {
      buffer.write('-');
    }
    buffer.write(character.toLowerCase());
  }

  final String kebab = buffer.toString();
  const String suffix = '-node';

  return kebab.endsWith(suffix) && kebab.length > suffix.length
      ? kebab.substring(0, kebab.length - suffix.length)
      : kebab;
}
