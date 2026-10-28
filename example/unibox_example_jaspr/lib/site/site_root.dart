import 'package:jaspr/jaspr.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_jaspr/unibox_jaspr.dart';

import 'iframe_node.dart';

/// The body of the site page, as the export draws it and as the browser redraws it.
///
/// One function for both sides: the client runtime replaces the page with a render of
/// this, and a root that differed would be a second design of the same document. The
/// gallery needs it for the ripple — the ink is a `StatefulNode`, so a press leaves a
/// drop only where a store is subscribed.
///
/// The two frames of the comparison are the one thing a node tree cannot describe, so
/// this is where the host supplies them: an `<iframe>` per panel, resizable, which is
/// what lets a reader narrow one and watch the page inside reflow.
Component buildSiteRoot() {
  return renderJaspr(
    // The page is built from material components, which name colour roles: the
    // theme answers them, once, for the whole page.
    theme: ExamplePalette.theme,
    // No scroll recorder: this document is read, and the browser redraws it, but no
    // Flutter binary ever boots over it — so there is no takeover to carry a scroll
    // position into, and a page a crawler reads keeps its no-script property.
    recordScroll: false,
    buildSitePage(
      frame: ({required String src, required String title}) =>
          IframeNode(src: src, title: title, resizable: true),
    ),
  );
}
