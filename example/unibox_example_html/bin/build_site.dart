import 'dart:io';

import 'package:unibox_example_html/site/favicon.dart';
import 'package:unibox_example_html/site/pages.dart';
import 'package:unibox_html/unibox_html.dart';

/// Writes the guide, independent hosts and optional handover document to files.
///
/// Run `dart run bin/build_site.dart --out=build/site` from this package.
/// `--url=` supplies canonical addresses; `--dev` enables handover diagnostics.
void main(List<String> arguments) {
  final Directory out = Directory(_option(arguments, 'out') ?? 'build/site');
  // `tool/site.sh` passes the commit it writes into `version.txt`, so a document can name the
  // build it came from and a stale tab can be told from a live one.
  final String? build = _option(arguments, 'build');
  // Where the site is served from, when the build knows: it is what turns each path into the
  // canonical address a search engine files the page under.
  final String? url = _option(arguments, 'url');

  final List<({String path, Document document})> pages = sitePages(
    build: build,
    url: url,
    // `--dev` writes a site a developer may inspect from the address: `?unibox=debug`,
    // `?unibox=profile` and `?unibox=compare` on the takeover page. A published build does not,
    // because a url is something a visitor can edit.
    debug: arguments.contains('--dev'),
  );

  for (final ({String path, Document document}) page in pages) {
    _write(out, page.path, page.document.write());
  }

  // From the same list, at the addresses the pages themselves claim: a sitemap that disagrees
  // with the page it lists files it under an address that page denies.
  if (url != null) {
    _write(out, 'sitemap.xml', sitemapOf(pages));
  }

  // The mark every document names, written by the build so that a page can never point at an
  // icon this build did not write — and so that a tab asks for it instead of for the origin's
  // `/favicon.ico`, which a project site answers with a 404.
  _write(out, faviconPath, faviconSvg);
}

/// Writes [document] to [path] below [out].
void _write(Directory out, String path, String document) {
  final File file = File('${out.path}/$path')..createSync(recursive: true);
  file.writeAsStringSync(document);
  stdout.writeln('Wrote ${file.path} (${document.length} bytes)');
}

/// The value of `--name=value`, or `null` when the flag is absent.
String? _option(List<String> arguments, String name) {
  for (final String argument in arguments) {
    if (argument.startsWith('--$name=')) {
      return argument.substring(name.length + 3);
    }
  }

  return null;
}
