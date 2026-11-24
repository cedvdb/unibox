import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import 'fonts.dart';
import 'site/favicon.dart';

/// The same release bundle can run directly or inside the handover document.
const String boot = '../../flutter/flutter_bootstrap.js';

/// The HTML reference rendering used to compare the two targets.
Document buildExampleDocument({String? build}) => _listings(build: build);

/// HTML first, then Flutter rendering the same declaration.
Document buildTakeoverDocument({String? build, bool debug = false}) =>
    _listings(build: build, handover: true, debug: debug);

Document _listings({
  String? build,
  bool handover = false,
  bool debug = false,
}) => Document(
  node: buildListingExample(photoPrefix: '../../', onSave: () {}),
  head: DocumentHead(
    title: 'Find your next home — Unibox',
    description:
        'One Dart declaration, rendered as HTML and handed over to Flutter.',
    meta: <String, String>{
      'unibox-build': ?build,
      'unibox-page': handover ? 'none' : 'example',
    },
    links: <DocumentLink>[faviconLink('../../'), ...fontPreloadLinks('../../')],
    raw: <String>['<style>${fontFaceCss('../../')}$pageCss</style>'],
  ),
  scope: UniboxScope(theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed)),
  takeover: handover
      ? Takeover(
          boot: boot,
          policy: BootPolicy.onIntent,
          reveal: RevealPolicy.onReady,
          openLabel: 'Open in Flutter',
          debug: debug,
        )
      : null,
);

/// The optional vocabulary is demonstrated separately from the application.
Document buildComponentsDocument({String? build}) => Document(
  node: buildComponentReference(),
  head: DocumentHead(
    title: 'Material vocabulary — Unibox',
    description: 'Shared design values and a small set of components with native Flutter substitutions.',
    meta: <String, String>{'unibox-build': ?build, 'unibox-page': 'components'},
    links: <DocumentLink>[faviconLink('../../'), ...fontPreloadLinks('../../')],
    raw: <String>['<style>${fontFaceCss('../../')}$pageCss</style>'],
  ),
  scope: UniboxScope(theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed)),
);

/// Fonts and the document canvas belong to the server host.
const String pageCss =
    'body { margin: 0; font-family: UniboxText, system-ui, sans-serif }';
