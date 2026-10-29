import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

/// A page that becomes an application, wired in one argument.
void main() {
  group('a takeover', () {
    final String html = toDocument(
      const core.Box(key: 'page'),
      takeover: const Takeover(boot: '../../flutter/app.js'),
    );

    test('prefetches the bundle while the reader reads', () {
      // Deferring the download as well is how a page gets a good score and a dead click.
      expect(
        html,
        contains(
          '<link rel="prefetch" href="../../flutter/app.js" as="script">',
        ),
      );
    });

    test('carries the recorders before the boot', () {
      // The application asks what the reader did, so the recorders have to exist first.
      final int recorders = html.indexOf('unibox.takePressed');
      final int boot = html.indexOf('unibox.boot');

      expect(recorders, isNot(-1));
      expect(html, contains('unibox.takeScroll'));
      expect(recorders, lessThan(boot));
    });

    test('boots on a signal, not on the first paint', () {
      expect(html, contains("'pointermove'"));
      expect(html, contains('requestIdleCallback'));
    });

    test('can be asked to leave the recorders behind', () {
      // A page that only has to boot pays for nothing it does not use.
      final String lean = toDocument(
        const core.Box(),
        takeover: const Takeover(boot: 'app.js', record: false),
      );

      expect(lean, isNot(contains('unibox.takePressed')));
      expect(lean, contains('unibox.boot'));
    });

    test('takes the policy the page needs', () {
      final String eager = toDocument(
        const core.Box(),
        takeover: const Takeover(
          boot: 'app.js',
          policy: BootPolicy.immediately,
        ),
      );

      expect(eager, contains('boot();\n})();'));
    });

    test('takes a nonce for a policy that refuses inline script', () {
      final String strict = toDocument(
        const core.Box(),
        takeover: const Takeover(boot: 'app.js', nonce: 'r4nd0m'),
      );

      expect(strict, contains('nonce="r4nd0m"'));
    });

    test('is absent unless it is asked for', () {
      expect(toDocument(const core.Box()), isNot(contains('unibox.boot')));
    });
  });
}
