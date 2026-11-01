/// The CSS one tree needs, described once for every web renderer.
///
/// The web is written once because a token's CSS lives here rather than in a renderer:
/// `unibox_html` writes it into a document and `unibox_dom` builds the same elements in a page.
/// They have to agree — a class name is a hash of its declarations, so two mappings that
/// disagree name one look two ways, and a host stylesheet written against one page stops
/// applying to the other.
///
/// The model is its only dependency, so it runs in a server, in a build step, in a CLI, and —
/// for a host whose backend is not Dart — compiled to JavaScript along with the renderer that
/// consumes it.
library;

export 'box.dart';
export 'declarations.dart';
export 'nodes.dart';
export 'rules.dart';
export 'shape.dart';
export 'values.dart';
