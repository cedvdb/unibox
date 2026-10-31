import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import '../fonts.dart';
import 'iframe_node.dart';

/// The document the site is served as.
///
/// One page, four bands — the claim with the comparison inside it, what a crawler is
/// served, the vocabulary, the catalogue — so there is one title and one description, and
/// they describe the whole of it: the search engine reason first, because that is the
/// reason a reader arrives from one.
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
String buildSiteDocument({
  ExampleSeed seed = ExampleSeed.defaultSeed,
  String? build,
}) {
  return toDocument(
    sitePageTree(seed: seed),
    head: DocumentHead(
      title: 'Unibox — SEO-friendly Flutter Web without duplicating your UI',
      description:
          'Flutter SEO without a second UI: build the interface once in Dart, serve it '
          'as real HTML and CSS to a search engine, and draw it as Flutter widgets in '
          'the app.',
      meta: <String, String>{'unibox-build': ?build, 'unibox-page': 'site'},
      links: fontPreloadLinks(''),
      raw: <String>['<style>${fontFaceCss('')}$siteCss</style>'],
    ),
    theme: siteThemeFor(seed),
    // A site a crawler reads is a document: the recorders are what a reader who interacts
    // with the catalogue leaves behind, and nothing here starts an application.
    scripts: <DocumentScript>[
      // The recorders first: they are what a reader who acts before the client arrives leaves behind.
      DocumentScript.inline(body: '$pressScript\n$scrollScript'),
      // Then the rendering that makes the page interactive without Flutter: the catalogue's chips,
      // its segmented button and its dialog, drawn from the same tree by the same stores.
      DocumentScript(src: 'web/main.client.js'),
    ],
  );
}

/// The site as one tree, built by the document and adopted by the client.
///
/// A frame is the one thing the model cannot describe, so the same node arrives in both: the document
/// writes it as markup a crawler can follow, and the client builds the identical element from the
/// identical payload.
core.UINode sitePageTree({ExampleSeed seed = ExampleSeed.defaultSeed}) =>
    buildSitePage(
      seed: seed,
      frame: ({required String src, required String title}) =>
          IframeNode(src: src, title: title),
    );

/// The palette the site is drawn with, in the document and in the browser.
///
/// The header's picker is a row of links to `?seed=<name>`, so the palette a reader chose is in
/// the address: the export writes the default one, and the runtime asks the address which one to
/// draw. Nothing else about the page changes — the tree names roles, and a theme is what answers
/// them.
core.UniboxTheme siteThemeFor(ExampleSeed seed) =>
    ExamplePalette.themeFor(seed);

/// The palette a query string names, or the default one.
///
/// A location's `search` arrives with its `?`, which `Uri.splitQueryString` does not expect: it
/// would read the key as `?seed` and answer with the default palette.
ExampleSeed seedFromQuery(String search) => ExampleSeed.fromName(
  Uri.splitQueryString(
    search.startsWith('?') ? search.substring(1) : search,
  )['seed'],
);

/// The rules that describe the surface of the site rather than its tree.
///
/// The font is the one thing the model leaves to the application, and the stack is written raw
/// because a comma separated list is a CSS construct while a `BoxTextStyle.fontFamily` names
/// one family.
const String siteCss = '''
body { margin: 0; font-family: UniboxText, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif }

/* The two arrows of the hero diagram, flowing from the tree to the two things it
   becomes. Three passes and then still: a loop that never stops keeps pulling the eye
   off the claim it introduces, and the resting state is the diagram itself. Only
   opacity and transform move, so the largest paint is unchanged and the layout never
   shifts. */
@keyframes unibox-flow {
  0% { opacity: 0; transform: translateY(-7px) }
  45% { opacity: 1 }
  100% { opacity: 1; transform: translateY(0) }
}

[data-unibox-key="hero-flow-html"],
[data-unibox-key="hero-flow-flutter"] {
  animation: unibox-flow 1.3s cubic-bezier(.2, .7, .3, 1) 3;
}

/* One after the other, so the eye follows the tree out to both branches rather than
   seeing two arrows move at once. */
[data-unibox-key="hero-flow-flutter"] { animation-delay: .16s }

@media (prefers-reduced-motion: reduce) {
  [data-unibox-key="hero-flow-html"],
  [data-unibox-key="hero-flow-flutter"] { animation: none }
}''';
