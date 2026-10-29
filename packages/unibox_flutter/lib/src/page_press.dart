/// Reads the presses a page recorded before the application arrived.
///
/// Two implementations behind one name, chosen by a conditional export rather than a runtime
/// check, so the JavaScript never reaches a build that cannot run it: a browser calls
/// `window.unibox.takePressed()`, and every other platform answers with nothing.
///
/// The record is data. Whether the tree can answer a press is [core.replayPresses]'s question.
library;

export 'page_press_stub.dart'
    if (dart.library.js_interop) 'page_press_web.dart';
