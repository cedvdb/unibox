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
      expect(uniboxClientScript, contains("'data-unibox-ink'"));
      expect(uniboxClientScript, contains("'data-unibox-key'"));
      expect(uniboxClientScript, contains('window.unibox'));
      expect(uniboxClientScript, contains('takePressed'));
    });

    test('listens once for the whole page, in the capture phase', () {
      // So a control added later works without being registered, and a press is caught
      // whatever it landed on.
      expect(uniboxClientScript, contains("addEventListener('pointerdown'"));
      expect(uniboxClientScript, contains('capture: true'));
      expect(uniboxClientScript, contains('passive: true'));
    });

    test('is valid JavaScript', () {
      // The one thing a Dart suite can check about it, and the one that would otherwise
      // reach a reader: a syntax error is an empty page with a console message.
      final String? node = _nodePath();

      if (node == null) {
        markTestSkipped('node is not installed');

        return;
      }

      final Directory directory = Directory.systemTemp.createTempSync('unibox');
      addTearDown(() => directory.deleteSync(recursive: true));
      final File file = File('${directory.path}/unibox.js')
        ..writeAsStringSync(uniboxClientScript);
      final ProcessResult result = Process.runSync(node, <String>[
        '--check',
        file.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
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
