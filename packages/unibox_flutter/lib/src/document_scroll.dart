/// Platform access to the document's current handover position.
library;

export 'document_scroll_stub.dart'
    if (dart.library.js_interop) 'document_scroll_web.dart';
