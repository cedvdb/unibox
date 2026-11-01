import 'package:test/test.dart';
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('the address', () {
    test('lets a reader ask for the document, whatever the build allows', () {
      // The one value that needs no flag: it can only take an application away, and a reader who
      // wants the text can say so in a url they can bookmark, share or paste into a ticket.
      final String script = bootScript('a.js');

      expect(script, contains("chosen === 'document'"));
      expect(script, contains("unibox.mode = 'document'"));
    });

    test('opens nothing a build did not allow', () {
      // A visitor can never turn on a report, a profile or a comparison the host did not publish.
      final String script = bootScript('a.js', debug: false);

      expect(script, contains("if (chosen !== '' && !debug)"));
      expect(script, contains('var debug = false;'));
    });

    test('is not read at all when the host says so', () {
      expect(bootScript('a.js'), contains('URLSearchParams'));
      expect(
        bootScript('a.js', query: false),
        isNot(contains('URLSearchParams')),
      );
    });

    test('draws the two renderings over each other, at half', () {
      final String script = bootScript('a.js', debug: true);

      expect(
        script,
        contains("root.setAttribute('data-unibox-compare', '0.5')"),
      );
      expect(
        script,
        contains('[data-unibox-compare] [data-unibox-app]{opacity:.5}'),
      );
      // The document is kept — that is the comparison — and still out of the tree a reader sees.
      expect(script, contains('if (!compare && child.parentNode)'));
    });

    test('publishes the numbers a profiler reads', () {
      final String script = bootScript('a.js', debug: true);

      expect(script, contains("performance.mark('unibox:' + name)"));
      expect(script, contains('unibox.profile = marks'));
      expect(script, contains("root.setAttribute('data-unibox-boot'"));
    });

    test('carries none of the checks in a build that refused them', () {
      final String script = bootScript('a.js');

      expect(
        script,
        isNot(contains('a press landed on the pre-boot document')),
      );
      expect(script, isNot(contains('the document still scrolled')));
    });
  });
}
