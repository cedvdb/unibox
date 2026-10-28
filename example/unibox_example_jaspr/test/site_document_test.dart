import 'dart:convert';

import 'package:jaspr/server.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_example_jaspr/site/site_document.dart';

/// Pins the one document the site is served as.
///
/// It is the page a crawler reads and the page a visitor keeps: one document, three
/// bands, and the two frames of the comparison below them.
void main() {
  setUpAll(Jaspr.initializeApp);

  group('buildSiteDocument', () {
    late String html;

    setUpAll(() async {
      final ResponseLike page = await renderComponent(buildSiteDocument());
      html = utf8.decode(page.body);
    });

    test('describes the whole page to a search engine', () {
      expect(html, contains('<html lang="en">'));
      expect(html, contains('<title>Unibox — one tree, two renderers</title>'));
      expect(
        html,
        contains(
          '<meta name="description" content="Describe a screen once, in plain '
          'Dart',
        ),
      );
    });

    test('writes the page as one outline', () {
      // One h1 for the claim, an h2 per band and an h3 per block of the catalogue:
      // that is the outline a crawler and a screen reader build the page from.
      expect(RegExp('<h1 ').allMatches(html), hasLength(1));
      expect(RegExp('<h2 ').allMatches(html), hasLength(2));
      expect(RegExp('<h3 ').allMatches(html).length, greaterThan(4));
      expect(html, contains('Describe a screen once.'));
      expect(html, contains('The same tree, drawn twice'));
      expect(html, contains('Material 3, as values and nodes'));
    });

    test('frames the same screen in both renderings', () {
      expect(RegExp('<iframe').allMatches(html), hasLength(2));
      expect(html, contains('src="web/listings/"'));
      expect(html, contains('src="flutter/listings/"'));
      expect(html, contains('title="Jaspr — HTML and CSS"'));
      expect(html, contains('title="Flutter — the same tree"'));
    });

    test('installs the palette the page names roles from', () {
      // The site is drawn with the palette the example grows from its seed, so the
      // value is the generated one — what matters here is that the role is installed
      // as a custom property and that the page reads it rather than a hex value.
      expect(
        RegExp(r'--unibox-color-surface-container:\s*#[0-9a-f]{6}')
            .hasMatch(html),
        isTrue,
        reason: 'the generated palette is not in the root',
      );
      expect(html, contains('var(--unibox-color-surface-container)'));
    });

    test('names the build it came from when it is told one', () async {
      // A tab opened before a deploy keeps the markup it arrived with, which looks
      // identical to the deployed page; the stamp is the one fact that separates them.
      final ResponseLike stamped = await renderComponent(
        buildSiteDocument(build: 'abc1234'),
      );

      expect(
        utf8.decode(stamped.body),
        contains('<meta name="unibox-build" content="abc1234"'),
      );
      // A build that cannot name itself says nothing rather than guessing.
      expect(html, isNot(contains('unibox-build')));
    });

    test('loads the browser runtime beside the page', () {
      expect(html, contains('src="main.client.js"'));
      expect(html, contains('defer'));
    });

    test('does not give the document the height of a viewport', () {
      // The page is longer than a screen and scrolls, so a `height: 100%` root —
      // which the example's app documents need, because their page box fills the
      // window — would clip it. The body keeps its margin removed, and no more.
      expect(html, contains('margin: 0;'));
      expect(html, isNot(contains('html, body')));
    });
  });
}
