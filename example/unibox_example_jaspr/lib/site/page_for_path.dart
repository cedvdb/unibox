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
