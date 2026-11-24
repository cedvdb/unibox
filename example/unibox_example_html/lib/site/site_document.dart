import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import '../fonts.dart';
import 'favicon.dart';
import 'iframe_node.dart';

/// The server document for the region-first project guide.
Document buildSiteDocument({
  ExampleSeed seed = ExampleSeed.defaultSeed,
  String? build,
}) {
  return Document(
    node: sitePageTree(seed: seed),
    head: DocumentHead(
      title: 'Unibox — shared UI regions for HTML and Flutter',
      description: 'Declare shared content in pure Dart. Render readable server HTML and native Flutter widgets, with optional host-directed handover.',
      meta: <String, String>{'unibox-build': ?build, 'unibox-page': 'site'},
      links: <DocumentLink>[faviconLink(''), ...fontPreloadLinks('')],
      raw: <String>['<style>${fontFaceCss('')}$siteCss</style>'],
    ),
    scope: core.UniboxScope(theme: siteThemeFor(seed)),
  );
}

/// The site uses host-supplied frames to compare independent renderings.
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
