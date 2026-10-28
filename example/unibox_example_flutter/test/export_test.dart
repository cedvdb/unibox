import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_flutter/export.dart';

/// What the exported site owes a crawler.
///
/// The documents are what the application takes over and what a reader without JavaScript
/// keeps, so the facts a search engine reads are pinned here rather than left to whichever
/// renderer last wrote the file.
void main() {
  late Directory output;

  setUp(() {
    output = Directory.systemTemp.createTempSync('unibox-export');
    exportTo(output);
  });

  tearDown(() => output.deleteSync(recursive: true));

  String read(String path) => File('${output.path}/$path').readAsStringSync();

  test('writes one document per state of the example', () {
    expect(File('${output.path}/listings/index.html').existsSync(), isTrue);
    expect(File('${output.path}/signup/index.html').existsSync(), isTrue);
  });

  test('names each document in its own words', () {
    // Two documents that share a title look like one page twice to a search engine.
    expect(
      read('listings/index.html'),
      contains('<title>Apartments — Unibox</title>'),
    );
    expect(
      read('signup/index.html'),
      contains('<title>Join Unibox — sign up</title>'),
    );
  });

  test('publishes the dialog at the url that exists to show it', () {
    // A document has no click, so the page that shows the dialog says so.
    final String signup = read('signup/index.html');
    final int dialog = signup.indexOf('role="dialog"');

    expect(dialog, isNot(-1), reason: 'the sign-up document has no dialog');

    // The tag the dialog is on, which must not be the hidden one.
    final String tag = signup.substring(
      signup.lastIndexOf('<div', dialog),
      signup.indexOf('>', dialog),
    );

    expect(tag, isNot(contains('hidden')));
  });

  test('leaves the dialog out of the page that is not showing it', () {
    // Presence in the tree *is* the state: a closed dialog is a node that is not there,
    // not one that is hidden.
    expect(read('listings/index.html'), isNot(contains('role="dialog"')));
  });

  test('gives every document a canonical url and a description', () {
    final String listings = read('listings/index.html');

    expect(
      listings,
      contains(
        '<link rel="canonical" href="https://example.com/unibox/web/listings/">',
      ),
    );
    expect(
      listings,
      contains('<meta name="description" content="Six apartments'),
    );
  });

  test('carries the colours of the theme in the root block', () {
    expect(read('listings/index.html'), contains('--unibox-color-primary:'));
  });

  test('writes a sitemap that names both documents', () {
    final String sitemap = read('sitemap.xml');

    expect(
      sitemap,
      contains('<loc>https://example.com/unibox/web/listings/</loc>'),
    );
    expect(
      sitemap,
      contains('<loc>https://example.com/unibox/web/signup/</loc>'),
    );
  });

  test('lets a crawler read the site, and tells it where the map is', () {
    final String robots = read('robots.txt');

    expect(robots, contains('User-agent: *'));
    expect(robots, contains('Sitemap: https://example.com/unibox/sitemap.xml'));
  });
}
