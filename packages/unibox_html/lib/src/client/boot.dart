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
/// **When the boot starts is a property of the page**, and there are three honest answers —
/// see [BootPolicy]. They are one choice rather than three switches because they exclude each
/// other: a page that boots at once does not also wait for a pointer.
library;

/// When a page boots the application that takes it over.
///
/// There are two, and each names a kind of page rather than an event:
///
/// | Policy | The page | What a reader pays |
/// | --- | --- | --- |
/// | [immediately] | the page *is* the application — a dashboard, a tool behind a login | the engine, from the first moment |
/// | [onPointer] | an application's front door — the document is a nicer first frame | the engine, as soon as they move |
///
/// Neither boots before the load: an engine parsing two megabytes competes with the largest
/// paint, and no reader has ever wanted a slower first frame.
///
/// **There is deliberately no "only on a press" policy.** A document that must never boot
/// unbidden ships no boot script at all — the script is optional by design, and a page without
/// it is a page that stays a document. And an interaction that has to work without the
/// application is a link or a form, not a press that waits for an engine to arrive: the model
/// already says so, because a destination is a `url` on the box that carries it, and a page
/// load is free.
enum BootPolicy {
  /// At once, as the script runs: the page is the application.
  ///
  /// For a screen nobody arrives at by accident — a dashboard, a tool behind a login. The
  /// document is still worth rendering, because it is a faster first frame than an empty
  /// canvas, but nobody is here to read it.
  immediately,

  /// On a pointer that moves, presses, touches, keys or focuses; and, if nothing does, when
  /// the browser is idle after the load.
  ///
  /// The default, and the right one for an application's front door: a pointer moving across
  /// the page is the earliest honest sign that a reader is here to do something rather than
  /// to read, and it arrives long before the press it leads to — so the engine is already
  /// starting while they move towards the control.
  onPointer,
}

/// The script that loads [src] and boots the application.
///
/// [src] is a url relative to the document, and it is escaped both as a JavaScript string and
/// for a raw text element: a value containing `</script>` closes the element otherwise, which
/// is how a parameter becomes an injection.
///
/// [policy] decides when the boot happens — see [BootPolicy]. It is the one thing a host knows
/// and a document cannot: which of the three kinds of page it published.
String bootScript(String src, {BootPolicy policy = BootPolicy.onPointer}) =>
    _bootTemplate
        .replaceAll('%START%', _startOf(policy))
        .replaceAll('%INTENT%', _intentOf(policy))
        .replaceAll('%IDLE%', _idleOf(policy))
        .replaceAll('%SRC%', _jsString(src));

/// What the script does as soon as it runs.
String _startOf(BootPolicy policy) =>
    policy == BootPolicy.immediately ? 'boot();' : '';

/// Which events mean a reader is here to do something.
String _intentOf(BootPolicy policy) => switch (policy) {
  BootPolicy.immediately => _noIntent,
  BootPolicy.onPointer => _pointerIntent,
};

/// What happens once the document has loaded.
String _idleOf(BootPolicy policy) => switch (policy) {
  BootPolicy.immediately => _nothingMore,
  BootPolicy.onPointer => _bootWhenIdle,
};

/// The template, with the parts a host chooses as placeholders.
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

    // `body` does not exist yet when the script ran from the head.
    (document.body || document.documentElement).appendChild(element);
  }

  // Intent before the load is remembered, not acted on: an engine that starts while the
  // document is still arriving competes with the largest paint.
  function want() {
    wanted = true;
    if (loaded) { boot(); }
  }

  unibox.boot = boot;%INTENT%

  window.addEventListener('load', function () {
    loaded = true;
    unibox.loaded = true;
    if (wanted) { boot(); }
  });
%IDLE%

%START%
})();
''';

/// Intent: a pointer that moves, arrives, presses, touches, keys or focuses.
///
/// A pointer that moves is the earliest honest sign that a reader is here to do something
/// rather than to read, and it arrives long before the press it leads to.
const String _pointerIntent = '''

  // Captured, so a signal is caught wherever it lands and whatever added it.
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

/// A page that boots at once needs no signal: it has already started.
const String _noIntent = '';

/// A reader who never touches the page still gets the application, after the load.
const String _bootWhenIdle = '''

  // A reader who never touches the page still gets the application: after the load, when the
  // browser has nothing better to do.
  window.addEventListener('load', function () {
    var idle = window.requestIdleCallback ||
      function (run) { return setTimeout(run, 200); };
    idle(boot);
  });''';

/// A page that waits to be asked does nothing more at the load.
const String _nothingMore = '';

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
