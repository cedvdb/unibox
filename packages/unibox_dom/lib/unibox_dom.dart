/// The same tree, drawn into a browser's DOM.
///
/// The third renderer, and the one a document becomes when a reader can act on it: `unibox_html`
/// writes a tree to markup a crawler reads, and this one builds the same elements in the page and
/// keeps them in step with the store a `StatefulNode` created. A callback runs because it is a
/// closure in the same program as the store — no attribute protocol, no name a host implements in
/// JavaScript.
///
/// It shares two things with the string renderer, and they are what make a handover possible: the
/// **element plan** (`unibox_element`) decides which element a node becomes and in what order its
/// attributes are written, and the **stylesheet** gives every look one class name derived from its
/// declarations. Same tree, same tags, same classes — so a client can adopt a page a server wrote
/// instead of painting over it.
///
/// Client only. It depends on `package:web` and `dart:js_interop`, so it is compiled by the host
/// (`dart compile js`) and never imported by a server.
library;

export 'src/mount.dart' show DomView;
