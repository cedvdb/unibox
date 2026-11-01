// The answer for an application a document handed the page to.
//
// Two facts, both written by `bootScript` in `unibox_html` before the bundle loads:
// `window.unibox.takeover`, which says this page was taken over rather than opened, and
// `window.unibox.ready`, which the application calls when it is worth showing.
//
// `dart:js_interop` only: the application does not need `package:web` to read two members of one
// object it did not create.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Whether the document this application was loaded from booted it as a takeover.
///
/// An application opened at its own address answers `false` — nothing was handed to it — which is
/// what keeps a renderer from enabling anything it was not asked to.
bool get wasTakenOver {
  final JSObject? unibox = _unibox;

  if (unibox == null) {
    return false;
  }

  final JSAny? flag = unibox.getProperty('takeover'.toJS);

  return flag != null && flag.isA<JSBoolean>() && (flag as JSBoolean).toDart;
}

/// Tells the document that the application is ready to be shown.
///
/// It is what `RevealPolicy.onReady` waits for. A renderer that draws the state it was given calls
/// it once, after that first frame; an application that waits for data calls it `uniboxReady()`
/// when the data is in.
void uniboxReady() {
  final JSObject? unibox = _unibox;

  if (unibox == null) {
    return;
  }

  final JSAny? ready = unibox.getProperty('ready'.toJS);

  if (ready != null && ready.isA<JSFunction>()) {
    unibox.callMethod('ready'.toJS);
  }
}

/// The object `bootScript` leaves on the page, when this application was booted from a document.
JSObject? get _unibox {
  final JSAny? unibox = _window.getProperty('unibox'.toJS);

  return unibox != null && unibox.isA<JSObject>() ? unibox as JSObject : null;
}

@JS('window')
external JSObject get _window;
