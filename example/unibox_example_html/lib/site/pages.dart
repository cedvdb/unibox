import 'package:unibox_html/unibox_html.dart';

import '../document.dart';
import 'site_document.dart';

/// The site's pages, each beside the path it is written to.
///
/// The list is the site: writing it is a loop, and the sitemap is the same list — which is why
/// the addresses are worked out here, once, rather than in the build script and again in the
/// sitemap it writes.
///
/// [url] is where the site is served from. A canonical address is the one thing a build knows
/// and a page does not, so when it is given every page states its own, and [sitemapOf] reads
/// those addresses back instead of being told them a second time.
List<({String path, Document document})> sitePages({
  String? build,
  String? url,
}) {
  final String? root = url == null ? null : (url.endsWith('/') ? url : '$url/');

  ({String path, Document document}) page(String path, Document document) => (
    path: path,
    document: root == null ? document : document.at('$root${_addressOf(path)}'),
  );

  return <({String path, Document document})>[
    page('index.html', buildSiteDocument(build: build)),
    page('web/listings/index.html', buildExampleDocument(build: build)),
    page('web/takeover/index.html', buildTakeoverDocument(build: build)),
  ];
}

/// The sitemap for [pages]: every page, at the address it says is its own.
///
/// A page with no canonical address is left out rather than listed under a path it does not
/// claim, so a sitemap and the pages it lists cannot disagree about where the site is.
String sitemapOf(List<({String path, Document document})> pages) {
  final StringBuffer buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

  for (final ({String path, Document document}) page in pages) {
    final String? canonical = page.document.head.canonical;

    if (canonical != null) {
      buffer.writeln('  <url><loc>${escapeText(canonical)}</loc></url>');
    }
  }

  buffer.writeln('</urlset>');

  return buffer.toString();
}

/// The address a page is served at, from the file it is written to: the root for `index.html`,
/// and the directory for a directory's `index.html`.
String _addressOf(String path) {
  const String index = 'index.html';

  return path.endsWith(index)
      ? path.substring(0, path.length - index.length)
      : path;
}
