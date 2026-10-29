import 'dart:io';

import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_example_html/document.dart';
import 'package:unibox_example_html/site/site_document.dart';

/// Writes the site to static files: one page, and the example it compares.
///
/// ```sh
/// dart run bin/build_site.dart --out=build/site --build=$(git rev-parse HEAD)
/// ```
///
/// Two kinds of document. `index.html` is the **site** — one page of three bands: the claim,
/// the comparison, and the Material catalogue the page is drawn with. `web/listings/` and
/// `web/signup/` are the **example**: the same tree as the left frame of the comparison,
/// exported twice because being open is state and a document cannot be clicked into existence.
///
/// Those two are takeover documents: they prefetch the bundle `flutter build web` writes beside
/// them and boot it when a reader arrives, so the page a crawler reads and the application a
/// reader uses are one document.
void main(List<String> arguments) {
  final Directory out = Directory(_option(arguments, 'out') ?? 'build/site');
  // `tool/site.sh` passes the commit it writes into `version.txt`, so a document can name the
  // build it came from and a stale tab can be told from a live one.
  final String? build = _option(arguments, 'build');

  _write(out, 'index.html', buildSiteDocument(build: build));

  for (final ExamplePage page in ExamplePage.values) {
    _write(
      out,
      'web/${_routeOf(page)}/index.html',
      buildExampleDocument(page: page, build: build),
    );
  }
}

/// The directory [page] is published at, relative to the export.
String _routeOf(ExamplePage page) => switch (page) {
  ExamplePage.apartments => 'listings',
  ExamplePage.signup => 'signup',
};

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
