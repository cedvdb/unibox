import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

import 'fonts.dart';

/// The bootstrap the page loads to become the application.
///
/// The documents sit two directories below the site root, which is where `tool/site.sh` puts
/// the output of `flutter build web`.
const String boot = '../../flutter/flutter_bootstrap.js';

/// The example as a document, rendered from the same tree the app draws.
///
/// One document per state of the example — `web/listings/` and `web/signup/` — because being
/// open is state and a document cannot be clicked into existence.
///
/// The page is a document first and an application second: the stylesheet arrives in the head,
/// the tree in the body, the bundle is prefetched while the reader reads, and the boot waits
/// for the first sign of a reader. The two recorders are what let the application pick up
/// where they left: where they scrolled, and what they pressed.
///
/// [build] is the commit the document was rendered from. A tab opened before a deploy and the
/// deployed page look identical, down to a layout the new build has fixed, so the document
/// carries the one fact that separates them.
String buildExampleDocument({
  ExamplePage page = ExamplePage.apartments,
  String? build,
}) {
  return toDocument(
    ExamplePageNode(signupOpen: page == ExamplePage.signup),
    title: titleOf(page),
    description: descriptionOf(page),
    meta: <String, String>{if (build != null) 'unibox-build': build},
    // A document has no click, so the page that exists to show the dialog says so.
    showOverlays: page == ExamplePage.signup,
    theme: ExamplePalette.theme,
    head: <String>['<style>${fontFaceCss('../../')}$pageCss</style>'],
    prefetch: <String>[boot],
    scripts: <DocumentScript>[
      DocumentScript.inline(
        body: '$pressScript\n$scrollScript\n${bootScript(boot)}',
      ),
    ],
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

/// The `<title>` of [page], which is what a search result links and a tab shows.
///
/// The page name comes first and the site name last, the order a reader scans a result in.
String titleOf(ExamplePage page) {
  return switch (page) {
    ExamplePage.signup => 'Join Unibox — sign up',
    ExamplePage.apartments => 'Apartments — Unibox',
  };
}

/// The `<meta name="description">` of [page].
///
/// It describes what the page is, in the words a reader would use, because a search engine may
/// show it under the title instead of an excerpt of the text.
String descriptionOf(ExamplePage page) {
  return switch (page) {
    ExamplePage.signup =>
      'A sign-up card described as one Unibox node tree and rendered by '
          'Flutter and as HTML, with a working form on both.',
    ExamplePage.apartments =>
      'Six apartments with a map beside the listings on a wide screen and the '
          'listings alone on a narrow one, from the same node tree.',
  };
}
