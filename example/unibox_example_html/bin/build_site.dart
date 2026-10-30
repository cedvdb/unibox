import 'dart:io';

import 'package:unibox_example_html/document.dart';
import 'package:unibox_example_html/site/site_document.dart';

/// Writes the site to static files: one page, and the example it compares.
///
/// ```sh
/// dart run bin/build_site.dart --out=build/site --build=$(git rev-parse HEAD)
/// ```
///
/// Two documents. `index.html` is the **site** — one page of four bands: the claim with the
/// comparison inside it, the markup a search engine is served, the vocabulary that names the
/// nodes the claim never drew, and the Material catalogue the page is drawn with, which closes
/// it. `web/listings/` is the **example**: the same tree as the left frame of the comparison,
/// and a takeover document — it prefetches the bundle `flutter build web` writes beside it and
/// boots it when a reader arrives, so the page a crawler reads and the application a reader
/// uses are one document.
///
/// One document for the example, not one per state: the sign-up form is a dialog, and a dialog is
/// not a page.
void main(List<String> arguments) {
  final Directory out = Directory(_option(arguments, 'out') ?? 'build/site');
  // `tool/site.sh` passes the commit it writes into `version.txt`, so a document can name the
  // build it came from and a stale tab can be told from a live one.
  final String? build = _option(arguments, 'build');

  _write(out, 'index.html', buildSiteDocument(build: build));

  _write(out, 'web/listings/index.html', buildExampleDocument(build: build));
  // The same tree, the other way to make it interactive: HTML first, Flutter when touched. It is what
  // the comparison's right frame shows, and the only page of the three that downloads an engine.
  _write(out, 'web/takeover/index.html', buildTakeoverDocument(build: build));
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
