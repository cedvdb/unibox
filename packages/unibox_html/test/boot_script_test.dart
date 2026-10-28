import 'dart:io';

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('the boot script', () {
    test('waits for intent, and never blocks the page', () {
      final String script = bootScript('flutter_bootstrap.js');

      // A pointer, a touch, a key or a focus is the reader asking for the application.
      for (final String intent in <String>[
        'pointermove',
        'pointerover',
        'pointerdown',
        'touchstart',
        'keydown',
        'focusin',
      ]) {
        expect(script, contains("'$intent'"));
      }

      expect(script, contains('capture: true'));
      expect(script, contains('passive: true'));
      expect(script, contains('once: true'));
    });

    test('starts as soon as the pointer moves, not when it presses', () {
      // The press spends the engine's start-up inside the reader's first interaction; the
      // movement before it does not.
      final String script = bootScript('a.js');

      expect(script, contains("'pointermove'"));
      expect(script, contains("'pointerdown'"));
    });

    test(
      'can leave a passing pointer alone, for a page that is a document',
      () {
        final String script = bootScript('a.js', onMove: false);

        expect(script, isNot(contains("'pointermove'")));
        expect(script, contains("'pointerdown'"));
      },
    );

    test('remembers an intent that arrives before the page has loaded', () {
      // An engine that starts while the document is still arriving competes with the largest
      // paint; the intent is honoured at the load instead of being lost or acted on early.
      final String script = bootScript('a.js');

      expect(script, contains("document.readyState === 'complete'"));
      expect(script, contains('wanted = true;'));
      expect(script, contains('if (wanted) { boot(); }'));
    });

    test('boots once, however often it is asked', () {
      // A press during the download and the load event that follows it must not start two
      // applications.
      expect(bootScript('a.js'), contains('if (booted) { return; }'));
    });

    test('boots when idle for a page that exists for its application', () {
      final String script = bootScript('a.js');

      expect(script, contains('requestIdleCallback'));
      expect(script, contains("addEventListener('load'"));
    });

    test('offers the application only when asked for a document', () {
      // The difference between a content page and an application entry, and the host is the
      // only one who knows which it published.
      final String script = bootScript('a.js', whenIdle: false);

      expect(script, isNot(contains('requestIdleCallback')));
      expect(script, contains('pointerover'));
    });

    test('cannot be broken out of by the url it is given', () {
      // A parameter that becomes markup is an injection, and this one sits in a raw text
      // element where nothing is escaped for us.
      final String script = bootScript("a'</script><script>alert(1)//");

      expect(script, isNot(contains('</script><script>')));
      expect(script, contains(r'<\/script>'));
      expect(script, contains(r"a\'"));
    });

    test('is valid JavaScript, with and without the idle boot', () {
      final String? node = _nodePath();

      if (node == null) {
        markTestSkipped('node is not installed');

        return;
      }

      for (final bool whenIdle in <bool>[true, false]) {
        final Directory directory = Directory.systemTemp.createTempSync(
          'unibox',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final File file = File('${directory.path}/boot.js')
          ..writeAsStringSync(bootScript('main.dart.js', whenIdle: whenIdle));
        final ProcessResult result = Process.runSync(node, <String>[
          '--check',
          file.path,
        ]);

        expect(
          result.exitCode,
          0,
          reason: 'whenIdle: $whenIdle ${result.stderr}',
        );
      }
    });
  });

  group('a page that boots', () {
    test('prefetches the bundle, so the boot is never on a cold cache', () {
      final String html = toDocument(
        const core.Box(),
        prefetch: <String>['flutter_bootstrap.js'],
      );

      expect(
        html,
        contains(
          '<link rel="prefetch" href="flutter_bootstrap.js" as="script">',
        ),
      );
    });

    test('carries the boot as a deferred script', () {
      final String html = toDocument(
        const core.Box(),
        scripts: <DocumentScript>[
          DocumentScript.inline(body: bootScript('flutter_bootstrap.js')),
        ],
      );

      expect(html, contains('<script>'));
      expect(html, contains('unibox.boot'));
    });
  });
}

/// The `node` binary, or `null` when the machine has none.
String? _nodePath() {
  final ProcessResult result = Process.runSync('which', <String>['node']);

  if (result.exitCode != 0) {
    return null;
  }

  return (result.stdout as String).trim();
}
