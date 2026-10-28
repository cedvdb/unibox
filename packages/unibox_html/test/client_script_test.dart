import 'dart:io';

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('a press the page may paint', () {
    test('is not invented by the renderer', () {
      // Ink is the ink well's: a `MaterialInkWell` draws it in Flutter because the node
      // says so, so a document cannot paint one for every box that listens — that would
      // be a look one target can draw and the other cannot.
      expect(toHtml(core.Box(onTap: () {})), isNot(contains('unibox-ink')));
    });

    test('is recorded where a node keyed the element', () {
      final String html = toHtml(core.Box(key: 'cta', onTap: () {}));

      expect(html, contains('data-unibox-key="cta"'));
    });
  });

  group('the client script', () {
    test('names the attribute the renderer writes', () {
      // Pinned from Dart because no Dart suite can run the script: a name that drifts
      // here is a marker nothing reads.
      expect(pressScript, contains("'$pressKeyAttribute'"));
    });

    test('adds its own member, so including it twice does nothing', () {
      // A page may include the file and a component may include it again; the second
      // include has to be a no-op, not a second set of listeners.
      expect(pressScript, contains('unibox.takePressed = function'));
      expect(pressScript, contains('if (unibox.takePressed) { return; }'));
    });

    test('listens once for the whole page, in the capture phase', () {
      // So a control added later works without being registered, and a press is caught
      // whatever it landed on.
      expect(pressScript, contains("addEventListener('pointerdown'"));
      expect(pressScript, contains('capture: true'));
      expect(pressScript, contains('passive: true'));
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

    test('is what a host gets when it asks for the page behaviour', () {
      expect(uniboxClientScript, pressScript);
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
      final File file = File('${directory.path}/press.js')
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
