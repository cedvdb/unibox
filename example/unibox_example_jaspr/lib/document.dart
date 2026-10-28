import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'fonts.dart';
import 'main.dart';

/// The document the example is served as.
///
/// The page box centres itself in a surface that fills the viewport — `width`
/// and `height: double.infinity` render as `100%` — so the root elements have to
/// give that percentage something to resolve against. Without `height: 100%`
/// the page box collapses to the height of its content, which is a state a
/// Flutter host never gets into: a `Scaffold` body is as tall as the window, so
/// the card ends up in the middle of the screen there and at the top of a short
/// grey strip here. The same height is what the apartments page scrolls inside
/// instead of growing the document.
///
/// The default body margin is removed for the same reason. Flutter lays the page
/// box out edge to edge, and the eight pixels a browser reserves around a body
/// would show up as a white frame around the canvas colour that nothing in the
/// node tree asked for.
///
/// Both rules describe the *host*, not the tree: they are the browser equivalent
/// of the surface a Flutter application is given, which is why they live next to
/// the app instead of in the renderer.
///
/// [page] is the destination the export starts on, which is the listings. Being
/// open is state, so a static export cannot open anything by itself:
/// `bin/build_site.dart` writes one document per destination, and the sign-up
/// document starts with the dialog open while the entry document starts with it
/// closed.
///
/// The metadata is the host's, not the tree's: a title and a description describe
/// a *document*, while a node tree describes a region of one. That is also why
/// each page gets its own: two documents that share a title look like one page
/// twice to a search engine. A host that needs more — a canonical url, Open Graph
/// tags, structured data — adds them through `Document.head`, which is where
/// elements that do not belong to the tree go.
Document buildExampleDocument({ExamplePage page = ExamplePage.apartments}) {
  return Document(
    // Without `lang` both a screen reader and a crawler have to guess which
    // language the page is in.
    lang: 'en',
    // No `<base>` element: the document is served from a subdirectory of a static
    // site, so the default `/` would resolve every relative link — the navigation
    // to `../signup/` included — against the domain root, which is a 404. Without
    // it the browser resolves against the document, which is what a page written
    // for `/web/signup/` expects.
    base: null,
    title: _titleOf(page),
    viewport: 'width=device-width, initial-scale=1',
    meta: <String, String>{'description': _descriptionOf(page)},
    // The documents of the example sit two directories below the site root.
    head: <Component>[
      fontFaces('../../'),
      // The browser runtime. The document is static HTML and CSS, which is what a
      // crawler reads and what a page without JavaScript keeps; this script makes
      // it react. It renders the same root the server rendered (see
      // `buildExampleRoot`), so the page it replaces is the page it drew.
      Component.element(
        tag: 'script',
        attributes: <String, String>{
          'src': '../../main.client.js',
          'defer': '',
        },
      ),
    ],
    styles: <StyleRule>[
      StyleRule(
        selector: const Selector('html, body'),
        styles: Styles(height: const Unit.percent(100), margin: Spacing.zero),
      ),
      // The font is the other half of that surface, and the one thing the model
      // leaves to the application: `BoxTextStyle.defaults` has no family, because
      // a font file is an asset. Flutter hands the tree the platform UI font by
      // saying nothing, so the document asks CSS for the same thing — a browser
      // falls back along the stack to the face its platform considers the UI font.
      // The stack is written raw because a comma separated list is a CSS
      // construct, while a `BoxTextStyle.fontFamily` names one family, which
      // Flutter and CSS both understand the same way.
      // A host keeps the last word: the tree says "the canvas role", and this block
      // says what that role is worth in a dark browser. Nothing in the tree changes,
      // which is the whole point of writing roles as custom properties.
      const StyleRule.media(
        query: MediaQuery.all(prefersColorScheme: ColorScheme.dark),
        styles: <StyleRule>[
          StyleRule(
            selector: Selector(':root'),
            styles: Styles(
              raw: <String, String>{
                '--unibox-color-canvas': '#101216',
                '--unibox-color-surface': '#1a1d24',
                '--unibox-color-text': '#e9eaee',
                '--unibox-color-muted': '#a2a8b4',
                '--unibox-color-border': '#2c313a',
              },
            ),
          ),
        ],
      ),
      const StyleRule(
        selector: Selector('body'),
        styles: Styles(
          raw: <String, String>{
            'font-family':
                "UniboxText, system-ui, -apple-system, 'Segoe UI', Roboto, "
                'sans-serif',
          },
        ),
      ),
    ],
    // The theme is the host's to install: the page names roles, and this is where
    // they are given values. The `:root` block of the document follows from it.
    // `buildExampleRoot` is the same call the browser runtime makes, so the page
    // that arrives and the page it redraws are one root, not two that look alike.
    body: buildExampleRoot(openSignup: page == ExamplePage.signup),
  );
}

/// The `<title>` of [page], which is what a search result links and what a
/// browser tab shows.
///
/// The page name comes first and the site name last, the order a reader scans a
/// result in.
String _titleOf(ExamplePage page) {
  return switch (page) {
    ExamplePage.signup => 'Join Unibox — sign up',
    ExamplePage.apartments => 'Apartments — Unibox',
  };
}

/// The `<meta name="description">` of [page].
///
/// It describes what the page is, in the words a reader would use, because a
/// search engine may show it under the title instead of an excerpt of the text.
String _descriptionOf(ExamplePage page) {
  return switch (page) {
    ExamplePage.signup =>
      'A sign-up card described as one Unibox node tree and rendered by '
          'Flutter and by Jaspr, with a working form on both.',
    ExamplePage.apartments =>
      'Six apartments with a map beside the listings on a wide screen and the '
          'listings alone on a narrow one, from the same node tree.',
  };
}
