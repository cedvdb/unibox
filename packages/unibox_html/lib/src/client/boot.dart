/// The script that boots the application, when it does, and how the page is handed over.
///
/// A page can be two things in a row: a document a crawler reads, and the application that takes
/// it over. This library is that handover, and it has three moments rather than one:
///
/// ```text
/// document ──(a signal)──▶ booting ──(the application is ready)──▶ app
///     │                        │
///     └── the reader reads ────┴──(an error, or never ready)──▶ failed
/// ```
///
/// **Starting is not the same as showing.** [BootPolicy] decides when the engine starts, and
/// [RevealPolicy] decides when its pixels replace the document's. Until then the document is
/// still the page: readable, pressable, scrollable, and recording what the reader did so that the
/// application can replay it.
///
/// **The state is on the document element**, as `data-unibox-state`, so a host can style the
/// transition and a test can assert it: `document`, `booting`, `ready`, `app`, `failed`.
///
/// **The reveal is an accessibility event.** The document is the readable rendering and the
/// application is a canvas — Flutter ships its semantics tree off on the web — so the handover
/// moves focus into the application, announces the change, and only then takes the document out
/// of the page. It never happens under a reader: a reveal that would take away the element they
/// are on waits for them to leave it.
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
  /// deliberately not signals. The document is the page as text — real headings, real links, real
  /// fields, whatever the host wrote — while the application is a canvas whose semantics a screen
  /// reader has to ask for. So booting on a keystroke would replace what a reader is reading with
  /// something it takes them more work to read, and would do it under the element their focus is
  /// on. A reader who never moves a pointer is not stranded either: the page carries a control that
  /// opens the application when they choose it — see [bootScript]'s `openLabel`.
  onIntent,
}

/// When the application is worth showing.
///
/// Two answers, because from inside the document only two events are observable — and what
/// *ready* means is the application's business, which is what `unibox.ready()` is for.
enum RevealPolicy {
  /// At the engine's first frame: the canvas has painted, and it is shown.
  ///
  /// The default, because a host that has not taught its application to say when it is ready
  /// must not wait for a call that never comes. It can show a first frame that is still a page
  /// with holes in it.
  onFrame,

  /// When the application says it is ready — and, if it never does, after `readyTimeout`.
  ///
  /// The right answer for a takeover, where the application has a scroll offset and a press to
  /// replay: a first frame drawn before that replay is a page that jumps under the reader. An
  /// application drawn by `unibox_flutter` says it is ready at its first draw without being
  /// asked; one that waits for data calls `uniboxReady()` when the data is in.
  onReady,
}

/// The script that loads [src] and boots the application.
///
/// [src] is a url relative to the document, and it is escaped both as a JavaScript string and
/// for a raw text element: a value containing `</script>` closes the element otherwise, which
/// is how a parameter becomes an injection.
///
/// [policy] decides when the boot starts — see [BootPolicy]. It is the one thing a host knows
/// and a document cannot: which of the three kinds of page it published.
///
/// [reveal] decides when the application is shown — see [RevealPolicy]. [readyTimeout] bounds
/// the wait for [RevealPolicy.onReady]: a frame that is available is revealed when it expires, and
/// a page with no frame at all goes back to being a document rather than staying blank.
///
/// The three labels are the sentences the handover says to a reader, and they are the host's
/// because a library cannot write in a language it was not told about: [openLabel] names the
/// control that starts the application, [loadingLabel] replaces it while the engine loads, and
/// [readyLabel] is announced when the application has taken the page.
///
/// [debug] allows `?unibox=debug`, `?unibox=profile` and `?unibox=compare` — the three address
/// values that make a page *show* something the host did not publish. It is a build decision: a
/// visitor can never turn one on that the build did not allow. [query] turns off reading the
/// address at all, including `?unibox=document`, which is the one value that needs no flag
/// because it can only remove an application.
String bootScript(
  String src, {
  BootPolicy policy = BootPolicy.onPointer,
  String openLabel = 'Open the application',
  RevealPolicy reveal = RevealPolicy.onFrame,
  Duration readyTimeout = const Duration(seconds: 8),
  String loadingLabel = 'Opening the application…',
  String readyLabel = 'The application is ready',
  bool debug = false,
  bool query = true,
}) => _bootTemplate
    .replaceAll('%START%', _startOf(policy))
    .replaceAll('%INTENT%', _intentOf(policy))
    .replaceAll('%GUARD%', _guardOf(policy))
    .replaceAll('%IDLE%', _idleOf(policy))
    .replaceAll('%OPEN%', _openOf(policy, openLabel))
    .replaceAll('%LABEL%', _jsString(openLabel))
    .replaceAll('%INSPECT%', debug ? _inspect : '')
    .replaceAll('%ADDRESS%', query ? _address : '')
    .replaceAll('%REVEAL%', reveal == RevealPolicy.onReady ? 'ready' : 'frame')
    .replaceAll('%TIMEOUT%', '${readyTimeout.inMilliseconds}')
    .replaceAll('%LOADING%', _jsString(loadingLabel))
    .replaceAll('%READY%', _jsString(readyLabel))
    .replaceAll('%DEBUG%', debug ? 'true' : 'false')
    .replaceAll('%QUERY%', query ? 'true' : 'false')
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
///
/// The *reveal* is guarded on every policy, and separately: it is the moment the page changes
/// hands, so it is the one that must not happen under a reader wherever the page is.
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

/// Whether the page carries the control that opens the application.
///
/// It does for [BootPolicy.onIntent], and only there: it is the one policy whose signals a
/// keyboard and a screen reader never produce, so without a control the application would be
/// something those readers could not reach at all — which is not a trade a policy may make on an
/// application's behalf. A front door needs none: a key boots it, and so does the browser going
/// idle.
String _openOf(BootPolicy policy, String label) => switch (policy) {
  BootPolicy.immediately || BootPolicy.onPointer => '',
  BootPolicy.onIntent => _openControl.replaceAll('%LABEL%', _jsString(label)),
};

/// The control that opens the application, for a reader who never moves a pointer.
///
/// A real `<button>`, first in the body, so Tab meets it before anything else and a screen reader
/// announces it — and moved out of the page until it takes the focus, which is the skip control
/// every reader already knows. It says what it does rather than what it changes, and it is gone
/// once the application is there: the boot marks it busy instead of taking it away, because
/// removing the element a reader just pressed would drop their focus.
const String _openControl = '''

  function offer() {
    var ask = document.createElement('button');
    ask.type = 'button';
    ask.className = 'unibox-open';
    ask.textContent = '%LABEL%';
    ask.setAttribute('data-unibox-open', 'true');
    ask.style.cssText = [
      'position:absolute',
      'top:-100px',
      'left:8px',
      'z-index:2147483647',
      'padding:8px 12px',
      'font:inherit',
      'color:#000',
      'background:#fff',
      'border:2px solid #000',
      'border-radius:6px',
      'cursor:pointer'
    ].join(';');

    // Out of the way until it is asked for: a reader who does not need it never sees it, and one
    // who tabs into this document meets it first.
    ask.addEventListener('focus', function () {
      ask.style.top = '8px';
    });

    ask.addEventListener('blur', function () {
      ask.style.top = '-100px';
    });

    ask.addEventListener('click', function () {
      boot();
    });

    var body = document.body || document.documentElement;
    body.insertBefore(ask, body.firstChild);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', offer);
  } else {
    offer();
  }''';

/// The template, with the parts a host chooses as placeholders.
///
/// Substituted rather than interpolated, so no JavaScript in it can be read as Dart.
const String _bootTemplate = '''
(function () {
  'use strict';
  var source = '%SRC%';
  var wants = '%REVEAL%';
  var debug = %DEBUG%;
  var asks = '%QUERY%' === 'true';
  var root = document.documentElement;
  var unibox = window.unibox = window.unibox || {};
  var booted = false;
  var wanted = false;
  var loaded = document.readyState === 'complete';
  var state = 'document';
  var before = null;
  var host = null;
  var observer = null;
  var framed = false;
  var framedAt = 0;
  var held = 0;
  var timer = 0;
  var locked = null;
  var scrolled = false;
  var marks = [];
  var chosen = asks ? readAddress() : '';
  var profile = false;
  var compare = false;
  var inspecting = false;

  root.setAttribute('data-unibox-state', 'document');
  mark('navigation');

  // The address, and the one rule that keeps it safe: a value may only narrow what the build
  // allowed. Removing an application is always safe, so `document` needs no flag; the numbers,
  // and one rendering drawn over the other, are things the host agreed to at build time.
  if (chosen === 'document') {
    unibox.mode = 'document';
    return;
  }

  if (chosen !== 'debug' && chosen !== 'profile' && chosen !== 'compare') {
    chosen = '';
  }

  if (chosen !== '' && !debug) {
    chosen = '';
  }

  inspecting = chosen !== '';
  profile = chosen === 'profile';
  compare = chosen === 'compare';

  if (inspecting) {
    unibox.mode = chosen;
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { mark('document'); }, { once: true });
  } else {
    mark('document');
  }

  if (inspecting) {
    %INSPECT%
  }

  %ADDRESS%

  // The record of what happened: the marks a profile reads, and the sentence a host reads.
  function mark(name) {
    marks.push([name, Math.round(performance.now())]);

    if (!profile) {
      return;
    }

    try {
      performance.mark('unibox:' + name);

      if (marks.length > 1) {
        performance.measure(
          'unibox:' + marks[marks.length - 2][0],
          'unibox:' + marks[marks.length - 2][0],
          'unibox:' + name
        );
      }
    } catch (error) {}
  }

  function publish() {
    if (!inspecting) {
      return;
    }

    try {
      unibox.marks = marks;
      root.setAttribute('data-unibox-boot', JSON.stringify(marks));
    } catch (error) {}

    if (profile) {
      unibox.profile = marks;
    }
  }

  function report(sentence) {
    publish();

    if (window.console && console.warn) {
      console.warn('[unibox] ' + sentence);
    }
  }

  function to(next) {
    state = next;
    root.setAttribute('data-unibox-state', next);
    publish();
  }

  // What the page arrived with. Everything in `body` afterwards is the engine's, whatever this
  // Flutter version calls it — a name is a version dependency, a snapshot is not.
  function snapshot() {
    if (before !== null || !document.body) {
      return;
    }

    before = [].slice.call(document.body.children);
  }

  function inside(node) {
    if (before === null || !node) {
      return false;
    }

    for (var i = 0; i < before.length; i++) {
      if (before[i] === node || before[i].contains(node)) {
        return true;
      }
    }

    return false;
  }

  function adopt() {
    snapshot();

    if (before === null) {
      return;
    }

    var body = document.body;

    for (var i = 0; i < body.children.length; i++) {
      var child = body.children[i];

      if (before.indexOf(child) !== -1) {
        continue;
      }

      child.setAttribute('data-unibox-app', 'true');

      if (!child.hasAttribute('tabindex')) {
        child.setAttribute('tabindex', '-1');
      }

      if (host === null) {
        host = child;
      }
    }
  }

  function watch() {
    if (!document.body) {
      document.addEventListener('DOMContentLoaded', watch, { once: true });
      return;
    }

    snapshot();
    observer = new MutationObserver(adopt);
    observer.observe(document.body, { childList: true });
    adopt();
  }

  // The isolation, as one rule keyed on the state rather than as inline styles: the engine's host
  // is invisible and unreachable while it loads, and the document is the page. A host can animate
  // the change from its own stylesheet because nothing here wins by being inline.
  function style() {
    var sheet = document.createElement('style');
    sheet.setAttribute('data-unibox-handover', 'true');
    sheet.textContent = [
      '[data-unibox-compare] [data-unibox-app]{opacity:.5}',
      '[data-unibox-state="booting"] [data-unibox-app]{opacity:0;visibility:hidden;pointer-events:none}',
      '[data-unibox-app]:focus{outline:none}',
      '[data-unibox-status]{position:absolute;width:1px;height:1px;margin:-1px;padding:0;overflow:hidden;clip-path:inset(50%);white-space:nowrap;border:0}'
    ].join('');

    (document.head || root).appendChild(sheet);
  }

  function lock() {
    if (locked !== null) {
      return;
    }

    locked = root.style.overflow;
    root.style.overflow = 'hidden';

    if (document.body) {
      document.body.style.overflow = 'hidden';
    }
  }

  function unlock() {
    if (locked === null) {
      return;
    }

    root.style.overflow = locked;
    locked = null;

    if (document.body) {
      document.body.style.overflow = '';
    }
  }

  // One boot however often it is asked for: a press during the download and the load event that
  // follows it must not start two applications.
  function boot() {
    if (booted) { return; }

    booted = true;

    // The way in has been accepted, and it says so. The control stays where it is — taking focus
    // from the reader who pressed it is the one thing worse than waiting — and it goes with the
    // document at the reveal.
    var ask = document.querySelector('[data-unibox-open]');

    if (ask) {
      ask.setAttribute('aria-disabled', 'true');
      ask.textContent = '%LOADING%';
    }

    style();
    snapshot();
    mark('boot-start');
    to('booting');

    if (compare) {
      root.setAttribute('data-unibox-compare', '0.5');
    }

    unibox.booted = true;
    unibox.takeover = true;

    window.addEventListener('flutter-first-frame', onFrame, { once: true });

    var element = document.createElement('script');
    element.src = source;
    element.onerror = function () {
      fail('the bundle did not load: ' + source);
    };

    (document.body || document.documentElement).appendChild(element);
    mark('script-load');

    watch();
    timer = setTimeout(timeUp, %TIMEOUT%);
  }

  function onFrame() {
    framed = true;
    framedAt = Math.round(performance.now());
    mark('first-frame');

    if (wants === 'frame') {
      reveal();
    }
  }

  // What an application says when it is worth showing. A frame still has to arrive: a canvas that
  // has not painted is a blank page with extra steps.
  unibox.ready = function () {
    mark('ready');

    if (framed) {
      reveal();
    } else {
      wants = 'frame';
    }
  };

  // Never under a reader, then focus, then announce, then take the document out of the page — in
  // that order, because `inert` blurs whatever is inside it.
  function reveal() {
    if (state === 'app' || state === 'failed') {
      return;
    }

    if (document.activeElement !== document.body && inside(document.activeElement)) {
      document.addEventListener('focusout', function () {
        setTimeout(reveal, 0);
      }, { once: true });

      return;
    }

    if (!framed) {
      return;
    }

    clearTimeout(timer);
    timer = 0;
    held = framedAt === 0 ? 0 : Math.round(performance.now()) - framedAt;
    root.setAttribute('data-unibox-held', String(held));
    mark('reveal');
    to('ready');

    if (host && host.focus) {
      try {
        host.focus({ preventScroll: true });
      } catch (error) {
        host.focus();
      }
    }

    announce();
    lock();
    retire();
    to('app');
    check();
  }

  function announce() {
    var status = document.createElement('p');
    status.setAttribute('role', 'status');
    status.setAttribute('data-unibox-status', 'true');

    var lang = root.getAttribute('lang');

    if (lang) {
      status.setAttribute('lang', lang);
    }

    status.textContent = '%READY%';
    (document.body || root).appendChild(status);
  }

  function retire() {
    var ask = document.querySelector('[data-unibox-open]');

    if (ask && ask.parentNode) {
      ask.parentNode.removeChild(ask);
    }

    if (before === null) {
      return;
    }

    for (var i = 0; i < before.length; i++) {
      var child = before[i];
      child.setAttribute('aria-hidden', 'true');
      child.setAttribute('inert', '');

      // A comparison keeps the document — two renderings of one tree, one over the other, is the
      // cheapest way to see whether they agree — but it is out of the accessibility tree either
      // way, so a reader is never given both pages.
      if (!compare && child.parentNode) {
        child.parentNode.removeChild(child);
      }
    }
  }

  function check() {
    if (!inspecting || !host) {
      return;
    }

    var box = host.getBoundingClientRect();

    if (box.width < window.innerWidth - 1 || box.height < window.innerHeight - 1) {
      report('the engine host does not cover the viewport');
    }
  }

  function timeUp() {
    timer = 0;

    if (!framed) {
      fail('no frame after %TIMEOUT%ms');
      return;
    }

    if (state !== 'app' && state !== 'failed') {
      report('the application never said ready; revealed after %TIMEOUT%ms');
      reveal();
    }
  }

  // A page that cannot become an application is still a page: everything is undone, and the
  // reader keeps what they were reading.
  function fail(reason) {
    clearTimeout(timer);
    timer = 0;

    if (observer) {
      observer.disconnect();
      observer = null;
    }

    if (host && host.parentNode) {
      host.parentNode.removeChild(host);
    }

    var ask = document.querySelector('[data-unibox-open]');

    if (ask) {
      ask.removeAttribute('aria-disabled');
      ask.textContent = '%LABEL%';
    }

    if (before !== null) {
      for (var i = 0; i < before.length; i++) {
        before[i].removeAttribute('aria-hidden');
        before[i].removeAttribute('inert');
      }
    }

    unlock();
    mark('failed');
    to('failed');
    report(reason);
  }

  function ready() {
    if (booted) { return; }
%GUARD%
    boot();
  }

  // Intent before the load is remembered, not acted on: an engine that starts while the document
  // is still arriving competes with the largest paint.
  function want() {
    wanted = true;

    if (loaded) {
      ready();
    }
  }

  unibox.boot = boot;%INTENT%

  window.addEventListener('load', function () {
    loaded = true;
    unibox.loaded = true;

    if (wanted) { ready(); }
  });
%IDLE%
%OPEN%

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

/// The address reader, spliced in only when [bootScript]'s `query` is on.
///
/// A page whose query string is data rather than a choice carries none of this: no parameter
/// name, no parser, no way to switch an application off by editing a url.
const String _address = '''
  function readAddress() {
    try {
      return new URLSearchParams(window.location.search).get('unibox') || '';
    } catch (error) {
      return '';
    }
  }''';

/// The two checks a host cannot make for itself, and cannot see the result of.
///
/// They are spliced in only when [bootScript]'s `debug` is on, so a production page carries none
/// of this: a boot that promises to isolate two views and does not is invisible to everyone
/// except the reader it happens to, and this is the only place it can be said out loud.
const String _inspect = '''
    // A press that lands on the pre-boot document after the reveal means the isolation failed.
    document.addEventListener('pointerdown', function (event) {
      if (state === 'app' && inside(event.target)) {
        report('a press landed on the pre-boot document after the application was up');
      }
    }, { capture: true, passive: true });

    // The document scrolls under a canvas when the scroll lock did not take.
    document.addEventListener('scroll', function () {
      if (state !== 'app' || scrolled) {
        return;
      }

      scrolled = true;
      report('the document still scrolled after the application was up');
    }, { capture: true, passive: true });''';

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
