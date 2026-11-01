import 'package:test/test.dart';
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('the reveal', () {
    test('never happens under the reader it would move', () {
      // The page changes hands at the reveal, and the element a reader is on goes with the
      // document. So the reveal waits for them to leave it — on every policy, because it is the
      // reveal that takes the element away, not the boot.
      for (final BootPolicy policy in BootPolicy.values) {
        final String script = bootScript('a.js', policy: policy);

        expect(script, contains('inside(document.activeElement)'));
        expect(script, contains("addEventListener('focusout'"));
        expect(script, contains('setTimeout(reveal, 0)'));
      }
    });

    test('moves focus before it hides what the focus was in', () {
      // `inert` blurs whatever is inside it, so a reveal that hides first and focuses second
      // drops the reader on the body with nothing said.
      final String script = bootScript('a.js');
      final int focus = script.indexOf('host.focus(');
      final int retire = script.indexOf('    retire();');

      expect(focus, greaterThan(0));
      expect(retire, greaterThan(focus));
    });

    test("announces the change once, in the page's language", () {
      final String script = bootScript('a.js', readyLabel: 'De app is klaar');

      expect(script, contains("status.setAttribute('role', 'status')"));
      expect(script, contains("status.setAttribute('lang', lang)"));
      expect(script, contains('De app is klaar'));
    });

    test('keeps the focus of the reader who pressed the way in', () {
      // `disabled` would drop the focus of the reader who just pressed it; `aria-disabled` says
      // the same thing to a screen reader and leaves them where they are.
      final String script = bootScript(
        'a.js',
        policy: BootPolicy.onIntent,
        loadingLabel: 'Opening the map…',
      );

      expect(script, contains("ask.setAttribute('aria-disabled', 'true')"));
      expect(script, contains('Opening the map…'));
      expect(script, isNot(contains('ask.disabled = true')));
    });

    test('tells the application it was handed a page', () {
      // Flutter ships semantics off on the web. The boot says it is a takeover, and the renderer
      // turns the tree on — no host code, and nothing enabled on a page that was opened at the
      // application's own address.
      expect(bootScript('a.js'), contains('unibox.takeover = true'));
    });
  });
}
