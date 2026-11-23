/// Server HTML and CSS from the same declarations Flutter renders as widgets.
///
/// Application state and interaction belong to the host. Optional server handover
/// helpers are also exposed through `package:unibox_html/handover.dart`.
library;

export 'src/client/all.dart' show uniboxClientScript;
export 'src/client/boot.dart' show BootPolicy, RevealPolicy, bootScript;
export 'src/client/keys.dart' show nodeKeyAttribute;
export 'src/client/scroll.dart' show scrollScript;
export 'src/client/press.dart'
    show pressKeyAttribute, pressRecordLimit, pressScript;
export 'src/css/css.dart';
export 'src/document.dart';
export 'src/document_head.dart';
export 'src/element/element.dart';
export 'src/embed_node.dart';
export 'src/escape.dart';
export 'src/render.dart';
export 'src/to_html.dart';
export 'src/takeover.dart';
export 'src/write.dart' show writeElement;
