/// Reads the scroll offsets a page recorded before the application arrived.
///
/// Two implementations behind one name: a browser reads the record the client script left
/// on `window.unibox`, and every other platform answers with nothing, because there is no
/// page to read. A conditional export rather than a runtime check, so the JavaScript never
/// reaches a build that cannot run it.
library;

export 'page_scroll_stub.dart'
    if (dart.library.js_interop) 'page_scroll_web.dart';
