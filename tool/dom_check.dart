// Presses a control in the built site and reports whether the page answered.
//
// `tool/boot_check.sh` asks whether the *takeover* document becomes the application, and it cannot
// see the client rendering: a page whose `main.client.js` throws, never loads, or binds nothing
// still serves, still scores well in Lighthouse, and still passes every suite here — because a
// suite tests the renderer in a browser it starts itself, not the file a build produced.
//
// So this drives Chrome over the DevTools protocol against a served `build/site`, presses the
// segmented button in the catalogue with the browser's own input path, and exits non-zero when the
// selection does not move. The input path matters: a synthetic `click` passes on a page where every
// real press is lost.
//
// Usage:
//   dart run tool/dom_check.dart http://127.0.0.1:8765/
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// How long to wait for a page to answer before calling it dead.
const Duration timeout = Duration(seconds: 30);

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run tool/dom_check.dart <url>');

    exit(2);
  }

  final String url = arguments.first;
  final Directory profile = Directory.systemTemp.createTempSync(
    'unibox-dom-check',
  );

  // Its own profile: Chrome attaches to a running instance without one, and then the check waits
  // for a browser somebody else is using.
  final Process chrome = await Process.start(_chrome(), <String>[
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--window-size=1280,2400',
    '--remote-debugging-port=0',
    '--user-data-dir=${profile.path}',
    'about:blank',
  ]);

  final Completer<int> debuggingPort = Completer<int>();

  chrome.stderr.transform(utf8.decoder).listen((String line) {
    final RegExpMatch? match = RegExp(
      r'DevTools listening on ws://[^:]+:(\d+)/',
    ).firstMatch(line);

    if (match != null && !debuggingPort.isCompleted) {
      debuggingPort.complete(int.parse(match.group(1)!));
    }
  });

  final int port = await debuggingPort.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => -1,
  );

  if (port < 0) {
    chrome.kill();
    stderr.writeln('Chrome did not open a debugging port.');

    exit(1);
  }

  try {
    final String target = await _pageTarget(port);
    final bool answered = await _presses(target, url);

    if (!answered) {
      stderr.writeln(
        'FAILED: the page did not answer a press. Either `web/main.client.js` did not run, or it\n'
        'binds nothing — check the browser console for the page at $url.',
      );

      exit(1);
    }

    stdout.writeln(
      '==> The client answers a press: the segmented button moved.',
    );
  } finally {
    chrome.kill();
    await chrome.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () => -1,
    );

    try {
      profile.deleteSync(recursive: true);
    } on FileSystemException {
      // A profile Chrome still holds open is the operating system's to clean up.
    }
  }
}

/// The websocket url of a page target, which is where commands are sent.
Future<String> _pageTarget(int port) async {
  final HttpClient client = HttpClient();

  try {
    final HttpClientResponse response = await (await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/json/list'),
    )).close();
    final List<Object?> targets = jsonDecode(
      await response.transform(utf8.decoder).join(),
    ) as List<Object?>;

    for (final Object? target in targets) {
      final Map<String, Object?> entry = target! as Map<String, Object?>;
      final Object? socket = entry['webSocketDebuggerUrl'];

      if (socket is String && entry['type'] == 'page') {
        return socket;
      }
    }
  } finally {
    client.close(force: true);
  }

  throw StateError('Chrome opened no page to drive.');
}

/// Presses a segment with the browser's own input path, and reports whether the selection moved.
Future<bool> _presses(String socketUrl, String url) async {
  final WebSocket socket = await WebSocket.connect(socketUrl);
  int id = 0;
  final Map<int, Completer<Map<String, Object?>>> pending =
      <int, Completer<Map<String, Object?>>>{};

  socket.listen((dynamic raw) {
    final Map<String, Object?> message =
        jsonDecode(raw as String) as Map<String, Object?>;
    pending.remove(message['id'])?.complete(message);
  });

  Future<Map<String, Object?>> send(
    String method, [
    Map<String, Object?>? params,
  ]) {
    final int next = ++id;
    final Completer<Map<String, Object?>> completer =
        Completer<Map<String, Object?>>();
    pending[next] = completer;
    socket.add(
      jsonEncode(<String, Object?>{
        'id': next,
        'method': method,
        'params': ?params,
      }),
    );

    return completer.future;
  }

  Future<Object?> evaluate(String expression) async {
    final Map<String, Object?> result = await send(
      'Runtime.evaluate',
      <String, Object?>{
        'expression': expression,
        'returnByValue': true,
        'awaitPromise': true,
      },
    );
    final Object? inner =
        (result['result'] as Map<String, Object?>?)?['result'];

    return inner is Map ? inner['value'] : null;
  }

  /// The class of the segmented button's share for [label], which moves with the selection.
  const String selection =
      "(function(){var t=[...document.querySelectorAll('[data-unibox-node=\"text\"]')]"
      ".filter(function(n){return n.textContent==='LABEL'&&n.children.length===0})[0];"
      'if(!t){return "missing"}var b=t;for(var i=0;i<3;i++){b=b.parentElement}'
      'return b.className})()';

  try {
    await send('Page.enable');
    await send('Page.navigate', <String, Object?>{'url': url});
    await Future<void>.delayed(const Duration(seconds: 4));

    final Object? before = await evaluate(
      selection.replaceAll('LABEL', 'Month'),
    );

    if (before == 'missing' || before == null) {
      stderr.writeln('FAILED: the page has no catalogue to press.');

      return false;
    }

    final Object? point = await evaluate(
      "(function(){var t=[...document.querySelectorAll('[data-unibox-node=\"text\"]')]"
      ".filter(function(n){return n.textContent==='Month'&&n.children.length===0})[0];"
      't.scrollIntoView({block:"center"});var r=t.getBoundingClientRect();'
      'return JSON.stringify({x:Math.round(r.left+r.width/2),y:Math.round(r.top+r.height/2)})})()',
    );
    final Map<String, Object?> at =
        jsonDecode(point! as String) as Map<String, Object?>;
    final Map<String, Object?> press = <String, Object?>{
      'x': at['x'],
      'y': at['y'],
      'button': 'left',
      'clickCount': 1,
    };

    await send('Input.dispatchMouseEvent', <String, Object?>{
      'type': 'mouseMoved',
      ...press,
    });
    await send('Input.dispatchMouseEvent', <String, Object?>{
      'type': 'mousePressed',
      ...press,
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await send('Input.dispatchMouseEvent', <String, Object?>{
      'type': 'mouseReleased',
      ...press,
    });

    // The store publishes, the boundary is planned again and the page is patched — all before a
    // frame is due, so a short wait is enough for a fast machine and generous for a slow one.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final Object? after = await evaluate(
      selection.replaceAll('LABEL', 'Month'),
    );

    return after != null && after != before;
  } finally {
    await socket.close();
  }
}

String _chrome() {
  for (final String path in <String>[
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ]) {
    if (File(path).existsSync()) {
      return path;
    }
  }

  stderr.writeln(
    'No Chrome found: install one, or set it up where this script looks.',
  );

  exit(1);
}
