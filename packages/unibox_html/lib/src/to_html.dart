import 'package:unibox_core/unibox_core.dart' as core;

// Prefixed, because an extension's own members are in scope inside its body: a bare
// `toHtml(this, …)` here would call this method rather than the renderer's function.
import 'render.dart' as render;

/// Rendering helpers for Unibox nodes, in the spelling the Flutter renderer uses.
///
/// `toWidget()` is an extension on a node, so a reader who has written
/// `runApp(page.toWidget())` looks for `page.toHtml()` next and not for a function that takes
/// the page as its first argument. A fragment is the whole of what a tree becomes on this
/// target, which is why it is the call that has a shorthand; a document needs the facts of a
/// page — its title, its canonical url, the languages it is translated into — that no tree
/// carries, so `toDocument(node, …)` stays a function with the tree as an argument.
extension UINodeHtmlRenderer on core.UINode {
  /// Renders this node as an HTML fragment, with one `<style>` element in front of it.
  ///
  /// Shorthand for `toHtml(this, theme: theme, showOverlays: showOverlays)`, and it takes
  /// the same two arguments for the same reasons: a tree built from colour roles names them
  /// and is reported without a theme, and an overlay is in the tree whether or not a
  /// document was asked to show it open.
  ///
  /// ```dart
  /// final String fragment = card.toHtml(theme: palette);
  /// ```
  String toHtml({core.UniboxTheme? theme, bool showOverlays = false}) =>
      render.toHtml(this, theme: theme, showOverlays: showOverlays);
}
