/// The script that boots the application, and when it does.
///
/// A page can be two things in a row: a document a crawler reads, and the application that
/// takes it over. This is the handover: the document is on screen, the bundle is already
/// downloaded, and the boot waits for a moment when paying for it is what the reader wants.
///
/// **Defer the execution, not the download.** The document prefetches the bundle (`prefetch`
/// on `toDocument`), so its bytes arrive while the reader reads. What waits is the boot. A
/// deferred boot with a cold cache is the worst of both worlds: a good score and a
/// two-second dead click.
///
/// **When to boot is a property of the page.** A content page waits for intent — a pointer,
/// a touch, a key, a focus — and otherwise boots when the browser is idle after the load, so
/// a reader who only reads never pays for the application. An application entry, whose reader
/// came for the application and will always need it, boots when idle regardless: making them
/// press something first is slower, not faster. That is [whenIdle].
library;

/// The script that loads [src] and boots the application.
///
/// [src] is a url relative to the document, and it is escaped both as a JavaScript string
/// and for a raw text element: a value containing `</script>` closes the element otherwise,
/// which is how a parameter becomes an injection.
///
/// [whenIdle] says whether a page no one touches still boots once the browser is idle. It is
/// the difference between a content page and an application entry, and it is a parameter
/// rather than a rule because only the host knows which one it published.
String bootScript(String src, {bool whenIdle = true}) => _bootTemplate
    .replaceAll('%IDLE%', whenIdle ? _bootWhenIdle : _chooseTheApplication)
    .replaceAll('%SRC%', _jsString(src));

/// The template, with the two parts a host chooses as placeholders.
///
/// Substituted rather than interpolated, so no JavaScript in it can be read as Dart.
const String _bootTemplate = '''
(function () {
  'use strict';
  var source = '%SRC%';
  var booted = false;
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

  unibox.boot = boot;

  // Intent, captured, so it is caught wherever it lands and whatever added it.
  var intent = ['pointerover', 'touchstart', 'keydown', 'focusin'];

  for (var i = 0; i < intent.length; i++) {
    window.addEventListener(intent[i], boot, {
      capture: true,
      once: true,
      passive: true
    });
  }
%IDLE%
})();
''';

/// A page that boots when the browser is idle, whether or not it was touched.
const String _bootWhenIdle = '''
  // A reader who never touches the page still gets the application: after the load, when
  // the browser has nothing better to do, so the boot never competes with the first paint.
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
