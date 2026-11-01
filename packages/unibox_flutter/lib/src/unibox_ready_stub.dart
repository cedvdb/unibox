// The answer for a target with no document in front of the application.
//
// A phone, a test, a desktop build: nothing booted this application from a page, so nothing is
// waiting to hear that it has drawn, and no accessibility tree has to be kept alive on its behalf.
library;

/// Whether the document this application was loaded from booted it as a takeover.
bool get wasTakenOver => false;

/// Tells the document the application is ready to be shown.
///
/// Does nothing here: there is no document listening. A host calls it from an application that
/// waits for data, and on every other target the call is free.
void uniboxReady() {}
