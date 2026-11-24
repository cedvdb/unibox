import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import 'fonts.dart';
import 'site/favicon.dart';

/// The same release bundle can run directly or inside the handover document.
const String boot = '../../flutter/flutter_bootstrap.js';

/// The server owns document composition and metadata around the shared region.
Document buildExampleDocument({String? build}) => _listings(build: build);

/// A separate, opt-in handover with an explicit keyed save action.
Document buildTakeoverDocument({String? build, bool debug = false}) =>
    _listings(build: build, handover: true, debug: debug);

Document _listings({
  String? build,
  bool handover = false,
  bool debug = false,
}) => Document(
  node: Box(
    width: double.infinity,
    crossAlign: CrossAlign.center,
    padding: const BoxSpacing.all(24),
    children: <UINode>[
      Box(
        width: double.infinity,
        maxWidth: 912,
        gap: 24,
        semantics: const BoxSemantics(element: BoxElement.main),
        children: <UINode>[
          const TextNode(
            'Homes worth a closer look',
            headingLevel: 1,
            fontSize: 28,
          ),
          const TextNode(
            'Six homes. One shared listing region. Each host owns the rest of the page.',
          ),
          buildListingRegion(
            photoPrefix: '../../',
            onSave: handover ? () {} : null,
          ),
          TextNode(
            handover
                ? 'Optional handover: scroll or press Save this search. The host restores the document offset before revealing Flutter and replays the intercepted action once.'
                : 'This is a complete server document. Read the listings and follow links without JavaScript or Flutter. Search, filters and dialogs are features of the Flutter host.',
          ),
          const LinkNode(
            '../../flutter/listings/',
            children: <UINode>[TextNode('Open the Flutter example')],
          ),
        ],
      ),
    ],
  ),
  head: DocumentHead(
    title: handover ? 'Optional handover — Unibox' : 'Shared listings — Unibox',
    description: 'Six homes rendered as readable HTML from a shared Dart listing region. The host owns the document and application behaviour.',
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
          openLabel: 'Open the Flutter handover demo',
          debug: debug,
        )
      : null,
);

/// The optional vocabulary is demonstrated separately from the application.
Document buildComponentsDocument({String? build}) => Document(
  node: buildMaterialSection(listingsUrl: '../listings/'),
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
    'body { margin: 0; font-family: UniboxText, system-ui, sans-serif; background: #fff; color: #202124 }';
