/// The web renderer: a Unibox tree as HTML a search engine can read.
///
/// A Flutter screen is a canvas, which a crawler, a link preview and a reader without
/// JavaScript all see as nothing. This package renders the same tree as a document: real
/// text, real headings, real links, one stylesheet, no framework and no runtime.
///
/// ```dart
/// import 'package:unibox_html/unibox_html.dart';
///
/// final String page = ListingsPage(listings).toHtml();
/// final String document = toDocument(
///   ListingsPage(listings),
///   head: const DocumentHead(title: 'Apartments'),
/// );
/// ```
///
/// It is pure Dart with no dependencies, so a document can be rendered in a server, in a
/// build step, in a command line tool, and — for a host whose backend is not Dart —
/// compiled to JavaScript.
///
/// ## What a document is
///
/// A snapshot of a state, not a running application. A `StatefulNode` draws the state its
/// store starts in, an `OverlayNode` draws its overlay open, and no callback becomes a
/// listener: there is nothing in the output that needs a runtime. Interactivity is the
/// application's, once it takes the page over.
library;

export 'src/client/all.dart' show uniboxClientScript;
export 'src/client/boot.dart' show BootPolicy, bootScript;
export 'src/client/keys.dart' show nodeKeyAttribute;
export 'src/client/scroll.dart' show scrollScript;
export 'src/client/press.dart'
    show pressKeyAttribute, pressRecordLimit, pressScript;
export 'src/document.dart';
export 'src/document_head.dart';
export 'src/embed_node.dart';
export 'src/escape.dart';
export 'src/render.dart';
export 'src/to_html.dart';
export 'src/takeover.dart';
export 'src/write.dart' show writeElement;
