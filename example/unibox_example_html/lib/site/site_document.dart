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
      title: 'Unibox — one UI, two renderers',
      description: 'One declarative UI in Dart. Server HTML and Flutter widgets, with seamless handover.',
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
const String siteCss =
    'body { margin: 0; font-family: UniboxText, system-ui, sans-serif }';
