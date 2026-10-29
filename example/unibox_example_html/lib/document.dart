import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import 'fonts.dart';

/// The loader the page boots the application through.
///
/// The documents sit two directories below the site root, which is where `tool/site.sh` puts
/// the output of `flutter build web`. It is not Flutter's own `flutter_bootstrap.js`: that one
/// resolves its entrypoint against the document, which is the wrong directory from here, so the
/// site writes a loader that states where the application is instead.
const String boot = '../../flutter/app.js';

/// The example as a document, rendered from the same tree the app draws.
///
/// One document, in the state the application starts in. The page is a document first and an
/// application second: the stylesheet arrives in the head, the tree in the body, the bundle is
/// prefetched while the reader reads, and the boot waits for the first sign of a reader. The two
/// recorders are what let the application pick up where they left: where they scrolled, and what
/// they pressed.
///
/// There is no document per state, and the sign-up form is the reason: a dialog is not a page.
/// Nothing links to it, a crawler has nothing to index under it, and a document cannot be clicked
/// into existence — so the one page is the listings, and the form is what a press opens once the
/// application is there. `showOverlays` answers a page whose published state *is* a dialog; this
/// example has no such page.
///
/// [build] is the commit the document was rendered from. A tab opened before a deploy and the
/// deployed page look identical, down to a layout the new build has fixed, so the document
/// carries the one fact that separates them.
String buildExampleDocument({String? build}) {
  return toDocument(
    ExamplePageNode(photoPrefix: '../../'),
    title: 'Apartments — Unibox',
    description:
        'Six apartments with a map beside the listings on a wide screen and the '
        'listings alone on a narrow one, from the same node tree.',
    meta: <String, String>{'unibox-build': ?build, 'unibox-page': 'example'},
    theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
    head: <String>[
      fontPreloadLinks('../../'),
      '<style>${fontFaceCss('../../')}$pageCss</style>',
    ],
    // A document that runs itself rather than one that becomes an application. The client renderer
    // adopts this markup and keeps it: a reader acts on real elements — the same ones a crawler
    // read — and Flutter is nowhere on the page. That is the difference worth showing, and it is
    // also what makes the comparison honest: the left frame is HTML before and after a press.
    scripts: const <DocumentScript>[
      // The client renderer, which adopts this markup and keeps it: a reader acts on the same
      // elements the crawler read, and Flutter is nowhere on the page. One directory up, because
      // this document is one directory down from the file `tool/site.sh` compiles.
      DocumentScript(src: '../main.client.js'),
    ],
  );
}

/// The same tree, as a document an application takes over.
///
/// This is the other way to make a page interactive, and the one the comparison's right frame shows:
/// the document paints first — a crawler reads it, and so does a reader — and Flutter starts on the
/// first sign of a reader, or when the browser is idle. Nobody has to touch the frame to see the
/// application, and what that costs the host page is what a takeover costs: the frame arrives as
/// markup and becomes an engine, which is the trade the whole library is about.
String buildTakeoverDocument({String? build}) {
  return toDocument(
    ExamplePageNode(),
    title: 'Apartments, taken over by Flutter — Unibox',
    description:
        'The same node tree as the document beside it, first as HTML and then, when a '
        'reader touches it, as the Flutter application.',
    meta: <String, String>{'unibox-build': ?build, 'unibox-page': 'none'},
    theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
    head: <String>['<style>${fontFaceCss('../../')}$pageCss</style>'],
    takeover: const Takeover(boot: boot),
  );
}

/// The rules that describe the surface rather than the tree.
///
/// The eight pixels a browser reserves around a body would show as a white frame around the
/// canvas the tree asked for, and Flutter lays its page out edge to edge. The height is what
/// the example's page box resolves its `double.infinity` against, and what the apartments page
/// scrolls inside instead of growing the document.
///
/// The font is the other half of that surface, and the one thing the model leaves to the
/// application: `BoxTextStyle.defaults` has no family, because a font file is an asset. The
/// stack is written raw because a comma separated list is a CSS construct, while a
/// `BoxTextStyle.fontFamily` names one family, which Flutter and CSS both understand alike.
///
/// The dark block is the host's last word: the tree says "the canvas role", and this says what
/// that role is worth in a dark browser. Nothing in the tree changes, which is the point of
/// writing roles as custom properties.
const String pageCss = '''
html, body { height: 100%; margin: 0 }
body { font-family: UniboxText, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif }
@media (prefers-color-scheme: dark) {
  :root {
    --unibox-color-canvas: #101216;
    --unibox-color-panel: #1a1d24;
    --unibox-color-text: #e9eaee;
    --unibox-color-muted: #a2a8b4;
    --unibox-color-border: #2c313a;
  }
}''';
