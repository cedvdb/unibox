/// The address the page this application was loaded into is served at.
///
/// Two implementations behind one name, chosen by a conditional export rather than a
/// runtime check, so the browser's own state never reaches a build that has no browser.
///
/// It is deliberately not `Uri.base`: that is the document's *base*, which
/// `flutter build web` writes as the build's root so that a copy of `index.html` in a
/// subdirectory can still resolve its assets. Routing needs the document's own address,
/// because `/flutter/` and `/flutter/listings/` are two addresses of one build and the two
/// documents are the same file.
library;

export 'page_address_stub.dart'
    if (dart.library.js_interop) 'page_address_web.dart';
