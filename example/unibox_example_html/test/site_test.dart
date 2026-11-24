import 'package:test/test.dart';
import 'package:unibox_example_html/site/site_document.dart';

void main() {
  test(
    'publishes a region-first guide with two independent rendering previews',
    () {
      final html = buildSiteDocument().write();
      expect(
        html,
        contains(
          '<title>Unibox — shared UI regions for HTML and Flutter</title>',
        ),
      );
      expect(RegExp('<h1').allMatches(html), hasLength(1));
      expect(html, contains('<main'));
      expect(RegExp('<iframe').allMatches(html), hasLength(2));
      expect(html, contains('src="web/listings/"'));
      expect(html, contains('src="flutter/listings/"'));
      expect(html, isNot(contains('<iframe src="web/takeover/')));
      expect(html, contains('href="web/takeover/"'));
      expect(html, contains('LinkNode'));
      expect(html, isNot(contains('Box(url:')));
      expect(html, isNot(contains('main.client.js')));
    },
  );
}
