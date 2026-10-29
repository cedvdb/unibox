import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_example_html/site/site_document.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:web/web.dart' as web;

/// The page a reader can act on, without Flutter.
///
/// Compiled with `dart compile js` by `tool/site.sh` and fetched by the site's document. It adopts
/// the markup the server wrote — the same tree, the same classes — instead of painting over it, so a
/// reader who has already scrolled keeps their place, and a crawler's page and a reader's page stay
/// one document.
///
/// The catalogue is why this exists: its chips, its segmented button and its dialog are a store
/// each, and a store needs a runtime. Here it is, at a fraction of an engine: the same Dart closures
/// the Flutter host would call.
/// Which tree a page draws. The document says so in its head, so one bundle serves both: a page that
/// names `example` gets the example, and one that names `site` gets the site.
String _pageName() {
  final web.Element? meta = web.document.querySelector(
    'meta[name="unibox-page"]',
  );

  return meta?.getAttribute('content') ?? 'site';
}

void main() {
  final web.Element? root = web.document.body?.firstElementChild;

  if (root == null) {
    // A page with nothing drawn in it: nothing to adopt, and nothing to say about it.
    return;
  }

  // The palette a reader chose is in the address, because the picker is a row of links: the export
  // writes the default one, and this is what answers the address with another.
  final ExampleSeed seed = seedFromQuery(web.window.location.search);

  // Two pages, one bundle: the site (the claim and the catalogue) and the example (the listings and
  // the sign-up dialog). Which one this is, the document says — no path is sniffed.
  final core.UINode tree = _pageName() == 'example'
      ? ExamplePageNode(seed: seed)
      : sitePageTree(seed: seed);

  DomView.adopt(
    tree,
    root,
    theme: _pageName() == 'example'
        ? ExamplePalette.themeFor(seed)
        : siteThemeFor(seed),
  );
}
