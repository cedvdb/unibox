/// Whether an application was handed a page, and when it has drawn it.
///
/// Two implementations behind one name, chosen by a conditional export rather than a runtime
/// check, so the browser's own state never reaches a build that has no browser.
///
/// A takeover is the one thing an application cannot know by itself: the document that booted it
/// said so in `window.unibox.takeover` before the bundle loaded, and the same object is what the
/// application answers through. A renderer reads both — the accessibility tree a canvas needs, and
/// the moment a waiting document may reveal it — so a host writes nothing at all.
library;

export 'unibox_ready_stub.dart'
    if (dart.library.js_interop) 'unibox_ready_web.dart';
