import 'package:unibox_example_shared/unibox_example_shared.dart';

/// The example page a browser path names, or `null` when it names none of them.
///
/// The export writes one document per state of the example — `web/listings/index.html`
/// and `web/signup/index.html` — so a browser reports `web/listings/`,
/// `web/listings` or `web/listings/index.html` for the same page, and a site served
/// from a subdirectory prefixes all three with `/unibox`. The destination is therefore
/// matched as a *segment*, once the empty last segment and the document name are
/// dropped, which is the rule the Flutter host applies to `Uri.base.pathSegments`.
///
/// Matching the whole path as a suffix is what once put the site's page in a listing's
/// document: `/web/listings/index.html` named no destination, fell through to the
/// site, and the runtime drew the site over the page the host had served. The two
/// renderings then scrolled differently — a document scrolls and takes its bar with
/// it, while the app keeps the bar and scrolls the list inside it — which is a
/// difference no token table can see, because it is a different page.
ExamplePage? examplePageForPath(String path) {
  final List<String> segments = <String>[
    for (final String segment in path.split('/'))
      if (segment.isNotEmpty && segment != 'index.html') segment,
  ];

  if (segments.length < 2 || segments[segments.length - 2] != 'web') {
    return null;
  }

  return switch (segments.last) {
    'listings' => ExamplePage.apartments,
    'signup' => ExamplePage.signup,
    _ => null,
  };
}
