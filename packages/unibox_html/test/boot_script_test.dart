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

    test('is optional in full, which is how a page stays a document', () {
      // A page that must never boot unbidden ships no boot script: the recorders are a
      // separate file, so including them does not start an engine.
      expect(uniboxClientScript, isNot(contains('createElement')));
      expect(uniboxClientScript, isNot(contains('requestIdleCallback')));
    });

    test('remembers an intent that arrives before the page has loaded', () {
      // An engine that starts while the document is still arriving competes with the largest
      // paint; the intent is honoured at the load instead of being lost or acted on early.
      final String script = bootScript('a.js');

      expect(script, contains("document.readyState === 'complete'"));
      expect(script, contains('wanted = true;'));
      expect(script, contains('if (wanted) { ready(); }'));
    });

    test('boots at once when the page is the application', () {
      // A dashboard is not arrived at by accident: waiting for a pointer would be a delay
      // nobody asked for.
      final String script = bootScript('a.js', policy: BootPolicy.immediately);

      // Before the closing brace of the script, and after everything that sets it up.
      expect(script, contains('boot();\n})();'));
      expect(script, isNot(contains("'pointermove'")));
      expect(script, isNot(contains('requestIdleCallback')));
    });

    test('boots into the document even before a body exists', () {
      // The script runs from the head, where `document.body` is still null.
      expect(
        bootScript('a.js', policy: BootPolicy.immediately),
        contains('document.body || document.documentElement'),
      );
    });

    test('names two kinds of page, in order of eagerness', () {
      // `immediately` for a screen nobody arrives at by accident, `onPointer` for everything else:
      // a pointer moving is the earliest honest sign of a reader, and the idle fallback catches the
      // one who only reads — which is what a page that shows an application has to answer to.
      // `immediately` for a screen nobody arrives at by accident, `onPointer` for a front door,
      // `onIntent` for a page that is shown beside something else: two policies is one short of
      // what a host has to say, and a frame that boots when the browser is idle is a frame that
      // spends an engine on a reader who never looked at it.
      expect(BootPolicy.values, <BootPolicy>[
        BootPolicy.immediately,
        BootPolicy.onPointer,
        BootPolicy.onIntent,
      ]);
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

    test('never waits to be asked, because a page that must be asked ships no script', () {
      final String script = bootScript('a.js');

      expect(script, contains('requestIdleCallback'));
      expect(script, contains('pointerdown'));
    });

    test('waits for a signal from the page that holds a shown frame', () {
      // A comparison frame is shown, not arrived at: the reader came for the page around it, and
      // an idle boot would spend an engine on someone who never looked. So no idle, and the
      // signals are read from the top document — a pointer in the middle of the host page never
      // reaches the frame's own window — and from the frame's own, for a reader who moves over
      // the frame itself.
      final String script = bootScript('a.js', policy: BootPolicy.onIntent);

      expect(script, isNot(contains('requestIdleCallback')));
      expect(script, contains('window.top'));
      expect(script, contains('listen(window);'));
      expect(script, contains('if (target !== window)'));
      expect(script, contains('wheel'));
      // A cross-origin frame may not read its host, and a boot that threw would never happen.
      expect(script, contains('catch (error)'));
      expect(script, contains('return window;'));
    });

    test('is told to look by a reader, not to act for one', () {
      // The document is the accessible rendering: real headings, links and fields, interactive
      // through the client renderer. The application is a canvas whose semantics a screen reader
      // has to ask for, so a key, a focus move or a press must not hand it the page — a keyboard
      // reader tabbing through the document would lose the element they were on.
      final String script = bootScript('a.js', policy: BootPolicy.onIntent);

      for (final String gesture in <String>[
        'pointermove',
        'pointerover',
        'touchstart',
        'wheel',
      ]) {
        expect(script, contains("'$gesture'"));
      }

      for (final String using in <String>[
        "'keydown'",
        "'focusin'",
        "'pointerdown'",
      ]) {
        expect(script, isNot(contains(using)));
      }
    });

    test('keeps a reader who is on a control inside the frame waiting', () {
      // The boot replaces every element in the document: under a reader who is on one, it would
      // take that element away and empty the field they had typed into.
      final String script = bootScript('a.js', policy: BootPolicy.onIntent);

      expect(script, contains('document.activeElement'));
      expect(script, contains('active !== document.body'));
      expect(script, contains("addEventListener('focusout'"));

      // A front door is the other way round — the document is a first frame — so its boot is not
      // held back by a focus a reader put there while the application arrives.
      expect(bootScript('a.js'), isNot(contains('document.activeElement')));
    });

    test('offers the application to a reader the pointer never reaches', () {
      // A policy that only a pointer satisfies would deny the application to a keyboard reader,
      // which is not a trade a policy may make on an application's behalf. So the document carries
      // a real control, first in the body, named by its host.
      final String script = bootScript(
        'a.js',
        policy: BootPolicy.onIntent,
        openLabel: 'Open the map',
      );

      expect(script, contains("document.createElement('button')"));
      expect(script, contains('Open the map'));
      expect(script, contains('insertBefore(ask, body.firstChild)'));
      // Out of the page until it takes the focus: the skip control, not a decoration.
      expect(script, contains("ask.addEventListener('focus'"));
      expect(script, contains("ask.style.top = '8px'"));
      // And gone once the application is there, however it arrived.
      expect(script, contains("document.querySelector('[data-unibox-open]')"));

      // A front door needs none of it: a key boots it, and so does the browser going idle.
      expect(bootScript('a.js'), isNot(contains("createElement('button')")));
    });

    test('keeps a label that would end the element it is written into', () {
      // The name is content rather than markup, and it came from a host — which is the same gate
      // the loader's url goes through.
      final String script = bootScript(
        'a.js',
        policy: BootPolicy.onIntent,
        openLabel: "a'</script><script>alert(1)//",
      );

      expect(script, isNot(contains('</script><script>')));
      expect(script, contains(r'<\/script>'));
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

      for (final BootPolicy policy in BootPolicy.values) {
        final Directory directory = Directory.systemTemp.createTempSync(
          'unibox',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final File file = File('${directory.path}/boot.js')
          ..writeAsStringSync(bootScript('main.dart.js', policy: policy));
        final ProcessResult result = Process.runSync(node, <String>[
          '--check',
          file.path,
        ]);

        expect(result.exitCode, 0, reason: '$policy: ${result.stderr}');
      }
    });
  });

  group('a page that boots', () {
    test('prefetches the bundle, so the boot is never on a cold cache', () {
      final String html = toDocument(
        const core.Box(),
        head: const DocumentHead(
          links: <DocumentLink>[
            DocumentLink.prefetch('flutter_bootstrap.js', as: 'script'),
          ],
        ),
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
