// Measures how long a document takes to become the application, in real time.
//
// `tool/boot_check.sh` proves that the page boots by dumping the DOM, and it cannot say how long
// that took: the dump runs under `--virtual-time-budget`, which advances the page's clock faster
// than the wall clock, so a `performance.now()` delta taken there is virtual. This drives Chrome
// over the DevTools protocol instead — no virtual time, a real browser in real time — and reads
// the moment the page marked its first frame.
//
// Usage:
//   dart run tool/boot_time.dart http://127.0.0.1:8765/web/boot-check/
//
// The page has to carry the mark: `tool/boot_check.sh` writes one that listens for
// `flutter-first-frame` and stamps `data-unibox-boot-ms` on the document element.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// How long to wait for a first frame before calling it a failure, in real time.
const Duration timeout = Duration(seconds: 60);

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run tool/boot_time.dart <url>');

    exit(2);
  }

  final String url = arguments.first;
  final Directory profile = Directory.systemTemp.createTempSync('unibox-boot');

  // Its own profile: Chrome on macOS attaches to a running instance without one, and then the
  // measurement waits for a browser somebody else is using.
  final Process chrome = await Process.start(_chrome(), <String>[
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--remote-debugging-port=0',
    '--user-data-dir=${profile.path}',
    'about:blank',
  ]);

  final Completer<int> debuggingPort = Completer<int>();

  // Chrome announces the port it chose on stderr, which is how `--remote-debugging-port=0` works.
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
    profile.deleteSync(recursive: true);
    stderr.writeln('Chrome did not open a debugging port.');

    exit(1);
  }

  try {
    final String target = await _pageTarget(port);
    final Duration measured = await _measure(target, url);

    stdout.writeln(
      '${measured.inMilliseconds} ms from navigation to the first frame '
      '(real time, unthrottled, this machine)',
    );
  } finally {
    chrome.kill();

    // Chrome writes to its profile while it shuts down, so the directory is only removable once
    // the process is gone — and a temp directory left behind is not worth failing a measurement.
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
    final HttpClientRequest request = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/json/list'),
    );
    final HttpClientResponse response = await request.close();
    final Object? targets = jsonDecode(
      await response.transform(utf8.decoder).join(),
    );

    for (final Object? target in targets! as List<Object?>) {
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

/// How long [url] takes to paint its first Flutter frame.
Future<Duration> _measure(String socketUrl, String url) async {
  final WebSocket socket = await WebSocket.connect(socketUrl);
  final Stream<Map<String, Object?>> answers = socket
      .map(
        (Object? message) =>
            jsonDecode(message! as String) as Map<String, Object?>,
      )
      .asBroadcastStream();
  final Stopwatch clock = Stopwatch();
  int nextId = 0;

  Future<Map<String, Object?>> send(
    String method, [
    Map<String, Object?>? params,
  ]) {
    final int id = nextId++;
    socket.add(
      jsonEncode(<String, Object?>{
        'id': id,
        'method': method,
        'params': ?params,
      }),
    );

    return answers.firstWhere(
      (Map<String, Object?> answer) => answer['id'] == id,
    );
  }

  try {
    await send('Page.enable');
    // The clock starts with the navigation, which is the moment a reader's starts.
    clock.start();
    await send('Page.navigate', <String, Object?>{'url': url});

    while (clock.elapsed < timeout) {
      final Map<String, Object?> answer = await send(
        'Runtime.evaluate',
        <String, Object?>{
          // The mark the probe writes, read through the protocol: under real time there is no
          // cheap way to wait for a paint from outside the page.
          'expression': "document.documentElement.getAttribute('data-unibox-boot-ms') || ''",
          'returnByValue': true,
        },
      );
      final Map<String, Object?>? result =
          answer['result'] as Map<String, Object?>?;
      final Object? value =
          (result?['result'] as Map<String, Object?>?)?['value'];

      if (value is String && value.isNotEmpty) {
        return Duration(milliseconds: int.parse(value));
      }

      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  } finally {
    await socket.close();
  }

  throw TimeoutException('No first frame within ${timeout.inSeconds} s.');
}

/// The Chrome binary, by the name each platform installs it under.
String _chrome() {
  const String absolute =
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

  return File(absolute).existsSync() ? absolute : 'google-chrome';
}
