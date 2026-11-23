/// Optional document-to-Flutter handover support.
///
/// Hosts decide when routing, data and layout are ready; this library restores
/// the document position and reveals the application at that explicit boundary.
library;

export 'src/document_scroll.dart' show documentScrollFromPage;
export 'src/handover.dart' show FlutterHandover;
export 'src/page_press.dart' show pressesFromPage;
export 'src/page_scroll.dart' show scrollOffsetsFromPage;
export 'src/unibox_ready.dart'
    show uniboxReady, wasTakenOver, awaitsHostReadiness;
