import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import '../fonts.dart';
import 'favicon.dart';
import 'iframe_node.dart';

/// The server document for the renderer comparison and live handover.
Document buildSiteDocument({
  ExampleSeed seed = ExampleSeed.defaultSeed,
  String? build,
}) {
  return Document(
    node: sitePageTree(seed: seed),
    head: DocumentHead(
      title: 'Unibox — Flutter UI. Searchable HTML.',
      description: 'One Dart UI rendered as searchable HTML and Flutter widgets, with live handover.',
      meta: <String, String>{'unibox-build': ?build, 'unibox-page': 'site'},
      links: <DocumentLink>[faviconLink(''), ...fontPreloadLinks('')],
      raw: <String>['<style>${fontFaceCss('')}$siteCss</style>'],
    ),
    scope: core.UniboxScope(theme: siteThemeFor(seed)),
  );
}

/// The site uses host-supplied frames to compare the same UI before and after Flutter handover.
core.UINode sitePageTree({ExampleSeed seed = ExampleSeed.defaultSeed}) =>
    buildSitePage(
      seed: seed,
      frame: ({required String src, required String title}) =>
          IframeNode(src: src, title: title),
    );

/// The design values shared by the documentation hosts.
core.UniboxTheme siteThemeFor(ExampleSeed seed) =>
    ExamplePalette.themeFor(seed);

/// Fonts and document background belong to the HTML host.
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
