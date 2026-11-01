@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:unibox_html/unibox_html.dart'
    show BootPolicy, RevealPolicy, bootScript;
import 'package:web/web.dart' as web;

/// An engine, as a document sees one: it appears in the body, and then it paints.
///
/// Two turns of the event loop, because the boot adopts the element through a `MutationObserver`
/// before it can be focused or revealed — a frame dispatched in the same task as the insertion
/// would arrive before the boot knows the element exists, which is a test being faster than the
/// thing it is testing, not a bug in either.
const String _engine = '''
setTimeout(function () {
  var view = document.createElement('div');
  view.id = 'fake-engine';
  view.style.cssText = 'position:fixed;inset:0';
  document.body.appendChild(view);

  setTimeout(function () {
    window.dispatchEvent(new Event('flutter-first-frame'));
  }, 0);
}, 0);
''';

const String _silent = 'void 0;';

/// A page whose document is a paragraph and whose engine is one of the two above.
String page({
  required String engine,
  BootPolicy policy = BootPolicy.immediately,
  RevealPolicy reveal = RevealPolicy.onFrame,
  Duration readyTimeout = const Duration(milliseconds: 400),
}) {
  final String boot = bootScript(
    'data:text/javascript,${Uri.encodeComponent(engine)}',
    policy: policy,
    reveal: reveal,
    readyTimeout: readyTimeout,
    openLabel: 'Open the application',
    loadingLabel: 'Opening…',
    readyLabel: 'The application is ready',
  );

  return '<!DOCTYPE html><html lang="nl"><head><meta charset="utf-8">'
      '<title>handover</title></head>'
      '<body><p id="doc">A document a crawler reads.</p>'
      '<script>$boot</script></body></html>';
}

/// Loads [html] in a frame of its own, because a boot takes the page apart.
Future<web.Document> load(String html) async {
  final web.HTMLIFrameElement frame = web.HTMLIFrameElement()
    ..srcdoc = html.toJS
    ..style.display = 'none';
  final Completer<void> loaded = Completer<void>();
  frame.addEventListener(
    'load',
    ((web.Event event) {
      if (!loaded.isCompleted) {
        loaded.complete();
      }
    }).toJS,
  );
  web.document.body!.append(frame);
  await loaded.future;

  return frame.contentDocument!;
}

/// Polls [test] until it answers, so the assertion is about the handover and not about a delay.
Future<void> until(bool Function() test, {String? reason}) async {
  for (int tick = 0; tick < 200; tick++) {
    if (test()) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  fail(reason ?? 'the page never reached the state the test waited for');
}

String? stateOf(web.Document document) =>
    document.documentElement!.getAttribute('data-unibox-state');

void main() {
  test('hands the page over at the first frame', () async {
    final web.Document document = await load(page(engine: _engine));

    await until(() => stateOf(document) == 'app');

    // The application is the page, and the document is gone — not merely covered.
    final web.Element engine = document.querySelector('#fake-engine')!;

    expect(engine.getAttribute('data-unibox-app'), 'true');
    expect(document.querySelector('#doc'), isNull);
  });

  test('announces the change, in the page\'s language', () async {
    final web.Document document = await load(page(engine: _engine));

    await until(() => stateOf(document) == 'app');

    final web.Element status = document.querySelector('[data-unibox-status]')!;

    expect(status.textContent, 'The application is ready');
    expect(status.getAttribute('role'), 'status');
    expect(status.getAttribute('lang'), 'nl');
  });

  test('goes back to being a document when no frame arrives', () async {
    // A page that cannot become an application is still a page, and this is what a host pays the
    // most for: the engine is a download that can 404.
    final web.Document document = await load(page(engine: _silent));

    await until(() => stateOf(document) == 'failed');

    expect(document.querySelector('#doc'), isNotNull);
    expect(document.querySelector('#fake-engine'), isNull);
  });

  test('reveals when the application never says it is ready', () async {
    // The engine painted but the application had nothing to add: holding the document for longer
    // than `readyTimeout` would be a page that waits forever.
    final web.Document document = await load(
      page(engine: _engine, reveal: RevealPolicy.onReady),
    );

    await until(() => stateOf(document) == 'app');

    expect(
      document.documentElement!.getAttribute('data-unibox-held'),
      isNotNull,
    );
  });
}
