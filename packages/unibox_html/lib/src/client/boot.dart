/// The script that boots the application, and when it does.
///
/// A page can be two things in a row: a document a crawler reads, and the application that
/// takes it over. This is the handover, and the rule it follows is short: **the application
/// starts as early as it can, and never earlier than the first paint.**
///
/// **The download starts at once.** The document prefetches the bundle (`prefetch` on
/// `toDocument`), so its bytes arrive while the reader reads. Deferring the download as well
/// is how a page gets a good score and a two-second dead click.
///
/// **The boot starts at the first sign of a reader.** A pointer moving across the page is
/// already a reader who may press something, and it happens long before the press — so an
/// engine that starts then is warm by the time they get there. A press, a touch, a key or a
/// focus starts it too. That is [onMove], and it is on by default because waiting for the
/// press itself spends the engine's start-up inside the reader's first interaction.
///
/// **But never before the load.** An intent that arrives while the document is still arriving
/// is *remembered*, not acted on: a two megabyte engine parsing itself competes with the
/// largest paint. After the load, intent boots immediately.
///
/// **When nothing touches the page at all**, [whenIdle] decides: an application entry boots
/// when the browser is idle, a content page waits to be asked. That is the one choice only the
/// host can make, because only it knows which of the two it published.
library;

/// The script that loads [src] and boots the application.
///
/// [src] is a url relative to the document, and it is escaped both as a JavaScript string and
/// for a raw text element: a value containing `</script>` closes the element otherwise, which
/// is how a parameter becomes an injection.
///
/// [whenIdle] says whether a page nothing touches still boots once the browser is idle.
///
/// [onMove] says whether a pointer moving across the page is enough to start the application.
/// It is the difference between an application's front door and a document that happens to
/// offer one: a reader flicking the mouse across an article has not asked for an engine.
String bootScript(String src, {bool whenIdle = true, bool onMove = true}) =>
    _bootTemplate
        .replaceAll('%INTENT%', onMove ? _bootOnMove : _bootOnPress)
        .replaceAll('%IDLE%', whenIdle ? _bootWhenIdle : _chooseTheApplication)
        .replaceAll('%SRC%', _jsString(src));

/// The template, with the three parts a host chooses as placeholders.
///
/// Substituted rather than interpolated, so no JavaScript in it can be read as Dart.
const String _bootTemplate = '''
(function () {
  'use strict';
  var source = '%SRC%';
  var booted = false;
  var wanted = false;
  var loaded = document.readyState === 'complete';
  var unibox = window.unibox = window.unibox || {};

  // One boot however often it is asked for: a press during the download and the load event
  // that follows it must not start two applications.
  function boot() {
    if (booted) { return; }
    booted = true;

    var element = document.createElement('script');
    element.src = source;
    unibox.booted = true;
    document.body.appendChild(element);
  }

  // Intent before the load is remembered, not acted on: an engine that starts while the
  // document is still arriving competes with the largest paint.
  function want() {
    wanted = true;
    if (loaded) { boot(); }
  }

  unibox.boot = boot;
%INTENT%

  window.addEventListener('load', function () {
    loaded = true;
    unibox.loaded = true;
    if (wanted) { boot(); }
  });
%IDLE%
})();
''';

/// Intent: a pointer that moves, arrives, presses, touches, keys or focuses.
///
/// A pointer that moves is the earliest honest sign that a reader is here to do something
/// rather than to read, and it arrives long before the press it leads to.
const String _bootOnMove = '''
  // Intent, captured, so it is caught wherever it lands and whatever added it.
  var intent = [
    'pointermove',
    'pointerover',
    'pointerdown',
    'touchstart',
    'keydown',
    'focusin'
  ];

  for (var i = 0; i < intent.length; i++) {
    window.addEventListener(intent[i], want, {
      capture: true,
      once: true,
      passive: true
    });
  }''';

/// Intent, for a document that stays a document: a gesture, not a passing pointer.
const String _bootOnPress = '''
  // Only a gesture that means "do something": a press, a touch, a key or a focus. A pointer
  // crossing the page is a reader reading.
  var intent = ['pointerdown', 'touchstart', 'keydown', 'focusin'];

  for (var i = 0; i < intent.length; i++) {
    window.addEventListener(intent[i], want, {
      capture: true,
      once: true,
      passive: true
    });
  }''';

/// A page that boots when the browser is idle, whether or not it was touched.
const String _bootWhenIdle = '''
  // A reader who never touches the page still gets the application: after the load, when the
  // browser has nothing better to do.
  window.addEventListener('load', function () {
    var idle = window.requestIdleCallback ||
      function (run) { return setTimeout(run, 200); };
    idle(boot);
  });''';

/// A page that is a document, and offers the application only when asked.
const String _chooseTheApplication = '''
  // Nothing boots until the reader asks: this page is a document, and the application is
  // something they can choose.''';

/// [value] as a JavaScript string literal inside a raw text element.
///
/// The backslash and the quote keep the value a string; the escaped `</` keeps it from
/// closing the `<script>` element it sits in; a newline would end the literal otherwise.
String _jsString(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('</', r'<\/')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r');
