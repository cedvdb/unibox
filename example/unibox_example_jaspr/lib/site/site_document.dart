import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import '../fonts.dart';
import 'site_root.dart';

/// The document the site is served as.
///
/// One page, three bands — the claim, the comparison, the catalogue — so there is one
/// title and one description, and they describe the whole of it.
///
/// The default body margin is removed: Flutter lays its page out edge to edge, and the
/// eight pixels a browser reserves around a body would show as a white frame around
/// the canvas the tree asked for. The page is longer than a viewport, so nothing here
/// gives it the height of one: it scrolls, and its bands paint their own backgrounds
/// down its whole length.
///
/// The metadata is the host's, not the tree's: a title and a description describe a
/// *document*, while a node tree describes a region of one. A host that needs more — a
/// canonical url, Open Graph tags, structured data — adds them through
/// `Document.head`, which is where elements that do not belong to the tree go.
Document buildSiteDocument() {
  return Document(
    // Without `lang` both a screen reader and a crawler have to guess which language
    // the page is in.
    lang: 'en',
    // No `<base>` element: the site may be served from a subdirectory — `/unibox/` —
    // so the default `/` would resolve every relative link, the two frames included,
    // against the domain root. Without it the browser resolves against the document.
    base: null,
    title: 'Unibox — one tree, two renderers',
    viewport: 'width=device-width, initial-scale=1',
    meta: <String, String>{
      'description':
          'Describe a screen once, in plain Dart, and draw it twice: Flutter widgets '
          'in an app and HTML with CSS in a browser. The Material 3 type scale, the '
          'colour roles and the components, as values and nodes.',
    },
    head: <Component>[
      fontFaces(''),
      // The browser runtime, beside the page. The document is static HTML and CSS,
      // which is what a crawler reads and what a page without JavaScript keeps; this
      // script makes it react. It renders the same root the server rendered (see
      // `buildSiteRoot`), so the page it replaces is the page it drew.
      Component.element(
        tag: 'script',
        attributes: <String, String>{'src': 'main.client.js', 'defer': ''},
      ),
    ],
    styles: <StyleRule>[
      // The font is the one thing the model leaves to the application:
      // `BoxTextStyle.defaults` has no family, because a font file is an asset.
      // Flutter hands the tree the platform UI font by saying nothing, so the
      // document asks CSS for the same thing — a browser falls back along the stack to
      // the face its platform considers the UI font. The stack is written raw because
      // a comma separated list is a CSS construct, while a
      // `BoxTextStyle.fontFamily` names one family, which Flutter and CSS both
      // understand the same way.
      const StyleRule(
        selector: Selector('body'),
        styles: Styles(
          margin: Spacing.zero,
          raw: <String, String>{
            'font-family':
                "UniboxText, system-ui, -apple-system, 'Segoe UI', Roboto, "
                'sans-serif',
          },
        ),
      ),
    ],
    // The theme is the host's to install, and `buildSiteRoot` does it inside the
    // renderer, which is also what the browser runtime calls: the page that arrives
    // and the page it redraws are one root, not two that look alike.
    body: buildSiteRoot(),
  );
}
