import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:unibox_example_jaspr/document.dart';
import 'package:unibox_example_jaspr/site/site_document.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

/// Renders the site to static files: one page, and the example it compares.
///
/// ```sh
/// dart run bin/build_site.dart --out=build/site --build=$(git rev-parse HEAD)
/// ```
///
/// Two kinds of document. `index.html` is the **site** — one page of three bands: the
/// claim, the comparison, and the Material catalogue the page is drawn with — and its
/// comparison frames the example below it. `web/listings/` and `web/signup/` are the
/// **example**: the same tree as the left frame, exported twice because being open is
/// state and a document cannot be clicked into existence.
///
/// Nothing here decides a URL the build script does not also write: `tool/site.sh`
/// adds the Flutter build beside these files and the robots and sitemap that name
/// them.
Future<void> main(List<String> arguments) async {
  Jaspr.initializeApp();

  final Directory out = Directory(_option(arguments, 'out') ?? 'build/site');
  // `tool/site.sh` passes the commit it writes into `version.txt`, so a document can
  // name the build it came from and a stale tab can be told from a live one.
  final String? build = _option(arguments, 'build');

  await _write(out, 'index.html', buildSiteDocument(build: build));

  for (final ExamplePage page in ExamplePage.values) {
    final String path = page == ExamplePage.apartments
        ? 'web/listings/index.html'
        : 'web/${page.name}/index.html';

    await _write(out, path, buildExampleDocument(page: page, build: build));
  }
}

/// Renders [document] to [path] below [out].
Future<void> _write(Directory out, String path, Document document) async {
  final ResponseLike rendered = await renderComponent(document);
  final File file = File('${out.path}/$path')..createSync(recursive: true);
  file.writeAsBytesSync(rendered.body);
  stdout.writeln('Wrote ${file.path} (${rendered.body.length} bytes)');
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
