/// The CSS one tree needs, described once for every web renderer.
///
/// This package exists so the web is written once. A token's CSS lives here rather
/// than in a renderer, which is what lets `unibox_html` — a plain string emitter —
/// and any renderer built on a framework produce the same declarations for the same
/// tree. They have to: a class name is a hash of its declarations, so two mappings
/// that disagree name one look two ways, and a host stylesheet written against one
/// page stops applying to the other.
///
/// It is pure Dart with no dependencies, so it can be used in a server, in a build
/// step, in a CLI, and — for a host whose backend is not Dart — compiled to
/// JavaScript along with the renderer that consumes it.
library;

export 'src/box.dart';
export 'src/declarations.dart';
export 'src/nodes.dart';
export 'src/rules.dart';
export 'src/shape.dart';
export 'src/values.dart';
