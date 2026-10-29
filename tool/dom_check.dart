// Presses a control in each built page and reports whether the page answered.
//
// `tool/boot_check.sh` asks whether a *takeover* document becomes the application. This asks the
// other question: whether the client rendering loaded and bound anything. Neither can see the
// other's failure, and no suite can see either — they start their own browser and read no build
// output. A page whose `main.client.js` is a 404 serves, scores well, and passes everything.
//
// The input path matters as much as the page: a synthetic `click` passes on a page where every real
// press is lost, so the press is dispatched the way a browser does — moved, pressed, released.
//
// Usage:
//   dart run tool/dom_check.dart http://127.0.0.1:8765/
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A page the check drives, and the control that proves it is alive.
final class Page {
  /// Describes one page of the build.
  const Page(this.path, this.label, this.expects);

  /// The path below the site root.
  final String path;

  /// The text of the control to press.
  final String label;

  /// What a working press changes: `segment` moves a chosen fill, `dialog` opens a dialog.
  final String expects;
}

/// Every page the build publishes that a reader can act on.
///
/// Both of them, because a page whose client never loads is silent: the example's document asked for
/// `web/main.client.js` from one directory down — a 404 — and every gate passed, because this check
/// only pressed a control on the front page.
const List<Page> pages = <Page>[
  Page('/', 'Month', 'segment'),
  Page('/web/listings/', 'Sign up', 'dialog'),
];

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run tool/dom_check.dart <base-url>');

    exit(2);
  }

  final String base = arguments.first.endsWith('/')
      ? arguments.first
      : '${arguments.first}/';
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
    final Device device = await Device.connect(await _pageTarget(port));
    final List<Page> dead = <Page>[];

    for (final Page page in pages) {
      final bool answered = await device.presses(
        '$base${page.path.substring(1)}',
        page,
      );

      stdout.writeln(
        '  ${answered ? 'ok  ' : 'FAIL'} ${page.path} — pressing “${page.label}” '
        '${answered ? 'was answered' : 'did nothing'}',
      );

      if (!answered) {
        dead.add(page);
      }
    }

    await device.close();

    if (dead.isNotEmpty) {
      stderr.writeln(
        '\nFAILED: ${dead.length} page(s) did not answer a press. Either their client rendering did\n'
        'not load — a wrong `src`, a 404 — or it bound nothing. Check the network panel and the\n'
        'console for each page above.',
      );

      exit(1);
    }

    stdout.writeln('\n==> The client answers a press on every page.');
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

/// A page target, driven over the DevTools protocol.
final class Device {
  Device._(this._socket);

  final WebSocket _socket;
  final Map<int, Completer<Map<String, Object?>>> _pending =
      <int, Completer<Map<String, Object?>>>{};
  int _id = 0;

  static Future<Device> connect(String socketUrl) async {
    final WebSocket socket = await WebSocket.connect(socketUrl);
    final Device device = Device._(socket);

    socket.listen((dynamic raw) {
      final Map<String, Object?> message =
          jsonDecode(raw as String) as Map<String, Object?>;
      device._pending.remove(message['id'])?.complete(message);
    });

    await device._send('Page.enable');

    return device;
  }

  Future<void> close() => _socket.close();

  Future<void> _send(String method, [Map<String, Object?>? params]) async {
    final int next = ++_id;
    final Completer<Map<String, Object?>> completer =
        Completer<Map<String, Object?>>();
    _pending[next] = completer;
    _socket.add(
      jsonEncode(<String, Object?>{
        'id': next,
        'method': method,
        'params': ?params,
      }),
    );
    await completer.future;
  }

  Future<Object?> _evaluate(String expression) async {
    final int next = ++_id;
    final Completer<Map<String, Object?>> completer =
        Completer<Map<String, Object?>>();
    _pending[next] = completer;
    _socket.add(
      jsonEncode(<String, Object?>{
        'id': next,
        'method': 'Runtime.evaluate',
        'params': <String, Object?>{
          'expression': expression,
          'returnByValue': true,
          'awaitPromise': true,
        },
      }),
    );

    final Map<String, Object?> result = await completer.future;
    final Object? inner =
        (result['result'] as Map<String, Object?>?)?['result'];

    return inner is Map ? inner['value'] : null;
  }

  /// Loads [url] and presses [page]'s control, answering whether the page responded.
  Future<bool> presses(String url, Page page) async {
    await _send('Page.navigate', <String, Object?>{'url': url});
    await Future<void>.delayed(const Duration(seconds: 4));

    final Object? before = await _evaluate(_state(page));

    if (before == null || before == 'missing') {
      return false;
    }

    final Object? point = await _evaluate(_centre(page.label));

    if (point == null || point == 'missing') {
      return false;
    }

    final Map<String, Object?> at =
        jsonDecode(point as String) as Map<String, Object?>;
    final Map<String, Object?> press = <String, Object?>{
      'x': at['x'],
      'y': at['y'],
      'button': 'left',
      'clickCount': 1,
    };

    await _send('Input.dispatchMouseEvent', <String, Object?>{
      'type': 'mouseMoved',
      ...press,
    });
    await _send('Input.dispatchMouseEvent', <String, Object?>{
      'type': 'mousePressed',
      ...press,
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _send('Input.dispatchMouseEvent', <String, Object?>{
      'type': 'mouseReleased',
      ...press,
    });

    // The store publishes, the boundary is planned again and the page patched — all before a frame is
    // due, so a short wait is enough on a fast machine and generous on a slow one.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final Object? after = await _evaluate(_state(page));

    // Like with like: a segmented button has answered when its chosen fill moved, a dialog when it
    // is open. Comparing a state with a bare "the control exists" would pass on a dead page, which
    // is how the first version of this check let a 404 through.
    return switch (page.expects) {
      'segment' => after != null && after != before,
      _ => after == 'open',
    };
  }
}

/// The element carrying [label], as JavaScript: the deepest node whose text is exactly that.
String _node(String label) =>
    "[...document.querySelectorAll('[data-unibox-node=\\\"text\\\"]')]"
    ".filter(function(n){return n.textContent==='$label'&&n.children.length===0})[0]";

/// The centre of [label]'s control, after scrolling it into view.
String _centre(String label) =>
    '(function(){var t=${_node(label)};if(!t){return "missing"}'
    't.scrollIntoView({block:"center"});var r=t.getBoundingClientRect();'
    'return JSON.stringify({x:Math.round(r.left+r.width/2),y:Math.round(r.top+r.height/2)})})()';

/// What a press should change, read before and after it.
String _state(Page page) => switch (page.expects) {
  'segment' =>
    "(function(){var t=${_node(page.label)};if(!t){return 'missing'}"
        'var b=t;for(var i=0;i<3;i++){b=b.parentElement}return b.className})()',
  _ =>
    "(function(){var d=document.querySelector('[role=dialog]');"
        "return d && !d.hasAttribute('hidden') ? 'open' : 'closed'})()",
};

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
