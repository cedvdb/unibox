import 'package:jaspr/jaspr.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_jaspr/unibox_jaspr.dart';
import 'package:unibox_material/unibox_material.dart';

import 'iframe_node.dart';

/// The body of a site page, as the export draws it and as the browser redraws it.
///
/// One function for both sides, for the reason `buildExampleRoot` has one: the
/// client runtime replaces the page with a render of this, and a root that differed
/// would be a second design of the same document. The gallery needs it for the
/// ripple — the ink is a `StatefulNode`, so a press leaves a drop only where a store
/// is subscribed.
Component buildSiteRoot(SitePage page) {
  return renderJaspr(
    // The gallery and the bar are built from material components, which name
    // colour roles: the theme answers them, once, for the whole page.
    theme: MaterialPalette.lightTheme,
    buildSitePage(
      page,
      frame: ({required String src, required String title}) => IframeNode(
        src: src,
        title: title,
        // A reader drags either frame narrower to watch the page inside reflow,
        // which is the comparison the showcase exists for.
        resizable: true,
      ),
    ),
  );
}
