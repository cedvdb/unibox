import 'dart:io';

import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

/// Writes the example as documents a crawler can read.
///
/// One document per state of the example — `listings/` and `signup/` — so a reader who
/// arrives with JavaScript off sees the listings, and a crawler sees the sign-up dialog at
/// its own url rather than nowhere. It is the other half of the application: the same tree,
/// rendered once into a file and once into widgets, which is the whole claim of the library.
///
/// ```shell
/// dart run bin/export.dart build/web
/// ```
///
/// The output is a directory a static host serves as it is: the documents, a `sitemap.xml`
/// that names them, and a `robots.txt` that lets them be read.
void main(List<String> arguments) {
  exportTo(Directory(arguments.isEmpty ? 'build/web' : arguments.first));
}

/// Writes the documents of the example into [output].
void exportTo(Directory output) {
  for (final ExamplePage page in ExamplePage.values) {
    final File document = File('${output.path}/${_routeOf(page)}/index.html')
      ..createSync(recursive: true);

    document.writeAsStringSync(
      toDocument(
        ExamplePageNode(signupOpen: page == ExamplePage.signup),
        title: _titleOf(page),
        description: _descriptionOf(page),
        canonical: '${_site}/web/${_routeOf(page)}/',
        theme: ExamplePalette.theme,
        // A document has no click, so the one that exists to *show* the dialog says so.
        showOverlays: page == ExamplePage.signup,
      ),
    );

    stdout.writeln('wrote ${document.path}');
  }

  File('${output.path}/sitemap.xml').writeAsStringSync(_sitemap());
  File('${output.path}/robots.txt').writeAsStringSync(_robots());
  stdout.writeln('wrote ${output.path}/sitemap.xml and robots.txt');
}

/// The directory [page] is published at, relative to the export.
String _routeOf(ExamplePage page) => switch (page) {
  ExamplePage.apartments => 'listings',
  ExamplePage.signup => 'signup',
};

/// The origin the example pretends to be published from.
///
/// A canonical url and a sitemap have to name one, and a relative one is the mistake that
/// makes a search engine index the same page twice.
const String _site = 'https://example.com/unibox';

/// The `<title>` of [page]: what a result links and what a tab shows.
///
/// The page name first and the site name last, the order a reader scans a result in. Two
/// documents that share a title look like one page twice to a search engine, which is why
/// each gets its own.
String _titleOf(ExamplePage page) => switch (page) {
  ExamplePage.signup => 'Join Unibox — sign up',
  ExamplePage.apartments => 'Apartments — Unibox',
};

/// The `<meta name="description">` of [page], in the words a reader would use.
String _descriptionOf(ExamplePage page) => switch (page) {
  ExamplePage.signup =>
    'A sign-up card described as one Unibox node tree and rendered by '
        'Flutter and as HTML, with a working form on both.',
  ExamplePage.apartments =>
    'Six apartments with a map beside the listings on a wide screen and the '
        'listings alone on a narrow one, from the same node tree.',
};

/// Every document of the export, at its canonical url.
String _sitemap() {
  final String urls = <String>[
    for (final ExamplePage page in ExamplePage.values)
      '  <url><loc>$_site/web/${_routeOf(page)}/</loc></url>',
  ].join('\n');

  return '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
      '$urls\n'
      '</urlset>\n';
}

/// The rule a crawler reads: everything may be read, and here is the map.
String _robots() =>
    'User-agent: *\n'
    'Allow: /\n'
    '\n'
    'Sitemap: $_site/sitemap.xml\n';
