/// Flutter renderer for the Unibox node tree.
///
/// Exposes `renderFlutter(UINode)` together with the `UINode.toWidget()`
/// extension which turn platform agnostic Unibox nodes into Flutter widgets.
///
/// ```dart
/// import 'package:unibox_core/unibox_core.dart';
/// import 'package:unibox_flutter/unibox_flutter.dart';
///
/// const card = Box(direction: Axis.vertical, gap: 8, children: [
///   TextNode('Hello'),
/// ]);
///
/// Widget widget = card.toWidget();
/// ```
///
/// Every node type also exposes the widget it renders to (`FlutterBox` for a
/// `Box`, `FlutterText` for a `TextNode`, ...), which is what a host or a test
/// needs to address a rendered node without depending on its position.
library;

export 'src/box.dart' show FlutterBox;
export 'src/embed_node.dart' show FlutterWidgetEmbedBuilder, FlutterWidgetNode;
export 'src/grid_node.dart' show FlutterGrid;
export 'src/image_node.dart' show FlutterImage;
export 'src/link_node.dart'
    show FlutterLinkOpener, FlutterLink, FlutterLinkScope;
export 'src/overlay_node.dart' show FlutterOverlay;
export 'src/render.dart';
export 'src/shape.dart' show pathOf;
export 'src/stack_node.dart' show FlutterStack;
export 'src/stateful_node.dart' show FlutterStateful;
export 'src/text_input_node.dart' show FlutterTextInput;
export 'src/text_node.dart' show FlutterText;
export 'src/text_style_scope.dart' show FlutterTextStyleScope;
export 'src/theme_scope.dart' show UniboxThemeScope;
