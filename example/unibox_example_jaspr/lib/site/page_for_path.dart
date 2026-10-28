import 'package:unibox_example_shared/unibox_example_shared.dart';

/// The site page a browser path names, or `null` when it names none of them.
///
/// The export writes one directory per destination (`material/index.html`), so the
/// path a browser reports for that page is usually `material/`, with a trailing
/// slash, and sometimes `material` or `material/index.html` — a host that serves or
/// links the document in the directory directly. All three name the same page, so
/// neither the slash nor the document name is part of the answer.
/// The home document is the fallback rather than a case: it is the directory the
/// other pages sit under.
SitePage? sitePageForPath(String path) {
  String trimmed = path;
  if (trimmed.endsWith('/index.html')) {
    trimmed = trimmed.substring(0, trimmed.length - '/index.html'.length);
  }
  if (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }

  for (final SitePage page in SitePage.values) {
    final String name = page.path.endsWith('/')
        ? page.path.substring(0, page.path.length - 1)
        : page.path;
    if (name.isNotEmpty && trimmed.endsWith('/$name')) {
      return page;
    }
  }

  return null;
}

/// The example page a browser path names, or `null` when it names none of them.
///
/// The export writes one document per destination too — `web/listings/index.html` —
/// so a browser reports `web/listings/`, `web/listings` or `web/listings/index.html`
/// for the same page, and a site served from a subdirectory prefixes all three with
/// `/unibox`. The destination is therefore matched as a *segment*, once the empty
/// last segment and the document name are dropped, which is the rule the Flutter
/// host applies to `Uri.base.pathSegments`.
///
/// Matching the whole path as a suffix is what put the front page in a listing's
/// document: `/web/listings/index.html` named no destination, fell through to the
/// site, and the runtime drew the front page over the page the host had served. The
/// two renderings then scrolled differently — a document scrolls and takes its bar
/// with it, while the app keeps the bar and scrolls the list inside it — which is a
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
    'pricing' => ExamplePage.pricing,
    _ => null,
  };
}
