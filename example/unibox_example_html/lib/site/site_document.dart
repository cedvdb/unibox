import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import '../fonts.dart';
import 'iframe_node.dart';

/// The document the site is served as.
///
/// One page, three bands — the claim, the comparison, the catalogue — so there is one title and
/// one description, and they describe the whole of it.
///
/// The page is longer than a viewport, so nothing here gives it the height of one: it scrolls,
/// and its bands paint their own backgrounds down its whole length. The body margin is removed
/// for the reason [pageCss] gives.
///
/// The metadata is the host's, not the tree's: a title and a description describe a *document*,
/// while a node tree describes a region of one.
///
/// [build] is the commit the document was rendered from, written into the head as
/// `unibox-build`. A tab opened before a deploy and the deployed page look the same, down to a
/// layout the new build has already fixed, so the one thing that separates them is a fact
/// carried by the document itself.
String buildSiteDocument({String? build}) {
  return toDocument(
    buildSitePage(
      frame: ({required String src, required String title}) =>
          IframeNode(src: src, title: title, resizable: true),
    ),
    title: 'Unibox — one tree, two renderers',
    description:
        'Describe a screen once, in plain Dart, and draw it twice: Flutter widgets '
        'in an app and HTML with CSS in a browser. The Material 3 type scale, the '
        'colour roles and the components, as values and nodes.',
    meta: <String, String>{'unibox-build': ?build},
    theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
    head: <String>['<style>${fontFaceCss('')}$siteCss</style>'],
    // A site a crawler reads is a document: the recorders are what a reader who interacts
    // with the catalogue leaves behind, and nothing here starts an application.
    scripts: <DocumentScript>[
      DocumentScript.inline(body: '$pressScript\n$scrollScript'),
    ],
  );
}

/// The rules that describe the surface of the site rather than its tree.
///
/// The font is the one thing the model leaves to the application, and the stack is written raw
/// because a comma separated list is a CSS construct while a `BoxTextStyle.fontFamily` names
/// one family.
const String siteCss = '''
body { margin: 0; font-family: UniboxText, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif }''';
