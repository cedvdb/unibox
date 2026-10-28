import 'dart:io';

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('a press the page may paint', () {
    test('is marked where a box listens', () {
      final String html = toHtml(core.Box(onTap: () {}));

      expect(html, contains(inkAttribute));
    });

    test('is not marked where nothing listens', () {
      // A box that paints and holds nothing has nothing to press.
      expect(toHtml(const core.Box()), isNot(contains(inkAttribute)));
    });

    test('is not marked on a disabled box', () {
      expect(
        toHtml(core.Box(enabled: false, onTap: () {})),
        isNot(contains(inkAttribute)),
      );
    });

    test('brings the drop it describes, once', () {
      final String html = toHtml(
        core.Box(
          onTap: () {},
          children: <core.UINode>[core.Box(onTap: () {})],
        ),
      );

      // The rule once, however many elements wear it.
      expect('.unibox-ink{'.allMatches(html), hasLength(1));
      expect(html, contains('@keyframes unibox-ink'));
    });

    test('leaves a page with nothing to press without an animation', () {
      expect(toHtml(const core.Box()), isNot(contains('unibox-ink')));
    });

    test('is inert without the script, which is how a page opts out', () {
      // The marker is markup; the behaviour is a file. Including neither is a valid page.
      expect(inkAttribute, 'data-unibox-ink');
      expect(uniboxClientScript, contains(inkAttribute));
    });
  });

  group('the client script', () {
    test('names the attributes the renderer writes', () {
      // Pinned from Dart because no Dart suite can run the script: a name that drifts
      // here is a marker nothing reads.
      expect(inkScript, contains("'$inkAttribute'"));
      expect(pressScript, contains("'$pressKeyAttribute'"));
    });

    test('is a behaviour per file, each adding its own member', () {
      // So a host includes the one it wants, and including two — or one twice — does
      // nothing the second time.
      expect(inkScript, contains('unibox.ink = true'));
      expect(pressScript, contains('unibox.takePressed'));
      expect(inkScript, contains('if (unibox.ink) { return; }'));
      expect(pressScript, contains('if (unibox.takePressed) { return; }'));
    });

    test('listens once for the whole page, in the capture phase', () {
      // So a control added later works without being registered, and a press is caught
      // whatever it landed on.
      for (final String script in <String>[inkScript, pressScript]) {
        expect(script, contains("addEventListener('pointerdown'"));
        expect(script, contains('capture: true'));
        expect(script, contains('passive: true'));
      }
    });

    test('records a press in the pixels of the element it landed on', () {
      // The same coordinates a Flutter renderer reports, so a replay needs no conversion.
      expect(pressScript, contains('getBoundingClientRect'));
      expect(pressScript, contains('clientX - box.left'));
      expect(pressScript, contains('clientY - box.top'));
    });

    test('takes the record once, so nothing is replayed twice', () {
      expect(pressScript, contains('pressed = [];'));
    });

    test('is what a host gets when it asks for all of it', () {
      expect(uniboxClientScript, contains(inkScript));
      expect(uniboxClientScript, contains(pressScript));
    });

    test('is valid JavaScript, alone and together', () {
      // The one thing a Dart suite can check about it, and the one that would otherwise
      // reach a reader: a syntax error is an empty page with a console message.
      final String? node = _nodePath();

      if (node == null) {
        markTestSkipped('node is not installed');

        return;
      }

      for (final ({String name, String script}) fragment
          in <({String name, String script})>[
            (name: 'ink', script: inkScript),
            (name: 'press', script: pressScript),
            (name: 'all', script: uniboxClientScript),
          ]) {
        final Directory directory = Directory.systemTemp.createTempSync(
          'unibox',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final File file = File('${directory.path}/${fragment.name}.js')
          ..writeAsStringSync(fragment.script);
        final ProcessResult result = Process.runSync(node, <String>[
          '--check',
          file.path,
        ]);

        expect(
          result.exitCode,
          0,
          reason: '${fragment.name}: ${result.stderr}',
        );
      }
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
