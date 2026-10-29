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
void main() {
  final web.Element? root = web.document.body?.firstElementChild;

  if (root == null) {
    // A page with nothing drawn in it: nothing to adopt, and nothing to say about it.
    return;
  }

  // The palette a reader chose is in the address, because the picker is a row of links: the
  // export writes the default one, and this is what answers the address with another. The
  // rendered tree differs only in the roles it resolves, so adopting it patches the custom
  // properties and the few elements that name a colour directly — the page a reader is looking
  // at stays the page they were looking at.
  final ExampleSeed seed = seedFromQuery(web.window.location.search);

  DomView.adopt(sitePageTree(seed: seed), root, theme: siteThemeFor(seed));
}
