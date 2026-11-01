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
/// There are three, and each names a kind of page rather than an event:
///
/// | Policy | The page | What a reader pays |
/// | --- | --- | --- |
/// | [immediately] | the page *is* the application — a dashboard, a tool behind a login | the engine, from the first moment |
/// | [onPointer] | an application's front door — the document is a nicer first frame | the engine, as soon as they move |
/// | [onIntent] | a page that is *shown* beside something else — a comparison, a preview | the engine, once they touch the page that holds it |
///
/// None of them boots before the load: an engine parsing two megabytes competes with the largest
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

  /// On the same signals as [onPointer], read from the page that *holds* this one — and never
  /// unbidden.
  ///
  /// For a page that is shown rather than arrived at: the right-hand half of a comparison, a
  /// preview inside someone else's page. [onPointer]'s idle boot is what a front door wants —
  /// a reader who landed here to do something gets the application whether or not they move —
  /// and it is exactly wrong for a frame, because the frame is a window in a page the reader
  /// came for, and the engine it starts competes with that page's own reading. A frame that
  /// waits costs its own document and nothing else until the reader signals interest.
  ///
  /// The signals come from the top document when it is the same origin, because a pointer in
  /// the middle of the page holding a frame never reaches the frame's window — and from the
  /// frame's own window as well, so a reader who moves over the frame itself is answered. A
  /// cross-origin frame cannot read its host, so it falls back to its own window.
  ///
  /// **Looking, not using.** A pointer that moves, a scroll and a touch are a reader looking at
  /// the page; a key, a focus move and a press are a reader *using* it, and those are
  /// deliberately not signals. The document is the accessible rendering — real headings, real
  /// links, real fields, and interactive through the client renderer — while the application is
  /// a canvas whose semantics a screen reader has to ask for. So a keyboard reader, and a reader
  /// whose assistive technology moves the focus around, keeps the document; booting on their
  /// keystrokes would replace the page they are reading with something it takes them more work
  /// to read. For the same reason the boot waits while the frame holds the focus: it replaces
  /// every element in the document, so it would take away the element a reader is on — and a
  /// field would lose what was typed into it.
  onIntent,
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
        .replaceAll('%GUARD%', _guardOf(policy))
        .replaceAll('%IDLE%', _idleOf(policy))
        .replaceAll('%SRC%', _jsString(src));

/// What the script does as soon as it runs.
String _startOf(BootPolicy policy) =>
    policy == BootPolicy.immediately ? 'boot();' : '';

/// Which events mean a reader is here to do something.
String _intentOf(BootPolicy policy) => switch (policy) {
  BootPolicy.immediately => _noIntent,
  BootPolicy.onPointer => _pointerIntent,
  BootPolicy.onIntent => _hostIntent,
};

/// Whether the boot waits for the focus to leave the document.
///
/// It does for [BootPolicy.onIntent], where the document is the accessible rendering a reader is
/// meant to be able to use: replacing it under the element they are on would take that element
/// away and empty a field they had typed into. A front door is the other way round — the document
/// is a first frame and the application is the page — so [BootPolicy.onPointer] boots regardless,
/// and an application that arrives a frame later than a Tab is the smaller surprise there.
String _guardOf(BootPolicy policy) => switch (policy) {
  BootPolicy.immediately || BootPolicy.onPointer => '',
  BootPolicy.onIntent => _focusGuard,
};

/// What happens once the document has loaded.
String _idleOf(BootPolicy policy) => switch (policy) {
  BootPolicy.immediately => _nothingMore,
  BootPolicy.onPointer => _bootWhenIdle,
  BootPolicy.onIntent => _nothingMore,
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

  // The boot replaces every element in this document, so it must not happen under a reader who
  // is on one: the element they were on would go, and a field would lose what was typed into it.
  function ready() {
    if (booted) { return; }
%GUARD%
    boot();
  }

  // Intent before the load is remembered, not acted on: an engine that starts while the
  // document is still arriving competes with the largest paint.
  function want() {
    wanted = true;
    if (loaded) { ready(); }
  }

  unibox.boot = boot;%INTENT%

  window.addEventListener('load', function () {
    loaded = true;
    unibox.loaded = true;
    if (wanted) { ready(); }
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

/// The boot waits while the reader's focus is inside this document.
///
/// The application replaces every element a page holds, so a boot that lands while a reader is on
/// one takes it away: they are left on the body with no announcement, and a field they had typed
/// into is empty. Nothing is focused before anybody touches the page, which is why a reader who has
/// not interacted at all boots at once — and `focusout` is what carries the boot to the moment they
/// leave, whether they tab away or the focus leaves the frame.
const String _focusGuard = '''
    var active = document.activeElement;

    if (active && active !== document.body) {
      document.addEventListener('focusout', function () {
        setTimeout(ready, 0);
      }, { once: true });

      return;
    }
''';

/// Intent, read from the page that holds this one.
///
/// A frame's own window sees the pointer only while it is over the frame. A reader who moves
/// across the page around it has signalled as much, so the listeners go on the top window when it
/// is the same origin, and on this one when it is not: a cross-origin frame is not allowed to read
/// its host, and a boot that threw instead would never happen. They go on this window either way,
/// so a reader who moves over the frame itself is answered too.
///
/// The events are the ones that mean *looking*: a pointer that moves, a scroll, and the touch that
/// begins a scroll on a phone. A press, a key and a focus move are a reader *using* the document,
/// and the document is the accessible rendering — see the `onIntent` doc comment for why that
/// matters, and note what the list costs: a phone with a screen reader on does not deliver its
/// gestures to the page, so the frame stays the document there, which is the outcome we want.
const String _hostIntent = '''

  function holder() {
    try {
      if (window.top && window.top !== window && window.top.document) {
        return window.top;
      }
    } catch (error) {}

    return window;
  }

  // Captured, so a signal is caught wherever it lands and whatever added it.
  var intent = [
    'pointermove',
    'pointerover',
    'touchstart',
    'wheel'
  ];
  var target = holder();

  function listen(where) {
    for (var i = 0; i < intent.length; i++) {
      where.addEventListener(intent[i], want, {
        capture: true,
        once: true,
        passive: true
      });
    }
  }

  listen(window);

  if (target !== window) {
    listen(target);
  }''';

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
