import 'package:test/test.dart';
import 'package:unibox_example_html/site/site_document.dart';

void main() {
  test('compares the same UI and makes Flutter handover the main demo', () {
    final html = buildSiteDocument().write();
    expect(
      html,
      contains('<title>Unibox — Flutter UI. Searchable HTML.</title>'),
    );
    expect(RegExp('<h1').allMatches(html), hasLength(1));
    expect(RegExp('<iframe').allMatches(html), hasLength(2));
    expect(html, contains('src="web/listings/"'));
    expect(html, contains('src="web/takeover/"'));
    expect(html, isNot(contains('src="flutter/listings/"')));
    expect(html, contains('Make Flutter Web pages indexable'));
    expect(html, contains('Just boxes'));
    expect(html, contains('Typography'));
    expect(html, contains('@keyframes unibox-flow'));
    expect(html, contains('prefers-reduced-motion: reduce'));
    expect(html, isNot(contains('main.client.js')));
  });
}
