import 'package:test/test.dart';
import 'package:unibox_example_html/document.dart';

void main() {
  test(
    'publishes useful listing content without Flutter or an event runtime',
    () {
      final html = buildExampleDocument(build: 'test-revision').write();
      expect(html, contains('<html lang="en">'));
      expect(html, contains('<title>Shared listings — Unibox</title>'));
      expect(html, contains('test-revision'));
      expect(html, contains('<h1'));
      expect(html, contains('<h2'));
      expect(html, contains('Rue de Turenne 12'));
      expect(RegExp('<article').allMatches(html), hasLength(6));
      expect(RegExp('<h3').allMatches(html), hasLength(6));
      expect(html, contains('alt="A room in Rue de Turenne 12"'));
      expect(html, contains('href="https://github.com/cedvdb/unibox"'));
      expect(html, isNot(contains('flutter_bootstrap.js')));
      expect(html, isNot(contains('listing-save')));
      expect(html, isNot(contains('<input')));
    },
  );
  test(
    'opts into keyed capture and host readiness only on the handover page',
    () {
      final html = buildTakeoverDocument().write();
      expect(html, contains(boot));
      expect(html, contains('data-unibox-key="listing-save"'));
      expect(html, contains('data-unibox-action'));
      expect(html, contains("var wants = 'ready'"));
      expect(html, contains('Save this search'));
      expect(html, isNot(contains('role="dialog"')));
    },
  );
  test(
    'ships local font declarations and a site icon on both document paths',
    () {
      for (final html in <String>[
        buildExampleDocument().write(),
        buildTakeoverDocument().write(),
      ]) {
        expect(html, contains('roboto-400.woff2'));
        expect(html, contains('../../favicon.svg'));
        expect(html, contains('../../assets/photos/apartment-1.jpg'));
      }
    },
  );
}
