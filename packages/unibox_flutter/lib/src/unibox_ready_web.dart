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

/// Waits until the document has actually revealed Flutter, or retained its fallback.
Future<bool> handoverRevealed() async {
  final JSObject? api = _unibox;
  if (api == null) return false;
  final JSAny? method = api.getProperty('whenRevealed'.toJS);
  if (method == null || !method.isA<JSFunction>()) return false;
  final JSAny? promise = api.callMethod('whenRevealed'.toJS);
  if (promise == null) return false;
  final JSBoolean result = await (promise as JSPromise<JSBoolean>).toDart;
  return result.toDart;
}

/// Whether this document requires an explicit host content-readiness signal.
bool get awaitsHostReadiness {
  final JSObject? api = _unibox;
  final JSAny? value = api?.getProperty('waitsForContent'.toJS);
  return value != null && value.isA<JSBoolean>() && (value as JSBoolean).toDart;
}

/// Cancels an unrevealed transition while retaining the document fallback.
void cancelPendingHandover() {
  final JSObject? api = _unibox;
  final JSAny? method = api?.getProperty('cancel'.toJS);
  if (api != null && method != null && method.isA<JSFunction>()) {
    api.callMethod('cancel'.toJS);
  }
}
