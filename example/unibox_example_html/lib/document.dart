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
    ExamplePageNode(),
    title: 'Apartments — Unibox',
    description:
        'Six apartments with a map beside the listings on a wide screen and the '
        'listings alone on a narrow one, from the same node tree.',
    meta: <String, String>{'unibox-build': ?build},
    theme: ExamplePalette.themeFor(ExampleSeed.blue),
    head: <String>['<style>${fontFaceCss('../../')}$pageCss</style>'],
    // One argument: the bundle is prefetched, the recorders travel with the boot, and the boot
    // waits for a signal. The example is the application's front door, so the default policy fits.
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
