/// Jaspr renderer for the Unibox node tree.
///
/// Exposes `renderJaspr(UINode)` together with the `UINode.toComponent()`
/// extension which turn platform agnostic Unibox nodes into server rendered
/// HTML/CSS components.
///
/// ```dart
/// import 'package:jaspr/jaspr.dart';
/// import 'package:unibox_core/unibox_core.dart';
/// import 'package:unibox_jaspr/unibox_jaspr.dart';
///
/// const card = Box(direction: Axis.vertical, gap: 8, children: [
///   TextNode('Hello'),
/// ]);
///
/// void main() => runApp(card.toComponent());
/// ```
///
/// Every node type also exposes the component it renders to (`JasprBox` for a
/// `Box`, `JasprText` for a `TextNode`, ...), which is what a test needs to address
/// a rendered node without depending on its position. The two renderer packages
/// export the same shape: the entry point, the extension, the embed, and one class
/// per node, named after its target.
library;

export 'src/box.dart' show JasprBox;
export 'src/default_typography.dart' show JasprDefaultTypography;
export 'src/embed_node.dart'
    show JasprComponentEmbedBuilder, JasprComponentNode;
export 'src/grid_node.dart' show JasprGrid;
export 'src/image_node.dart' show JasprImage;
export 'src/labels.dart' show nodeKeyAttribute, nodeLabelAttribute;
export 'src/link_node.dart' show JasprLink;
export 'src/render.dart';
export 'src/scroll_recorder.dart'
    show JasprScrollRecorder, scrollRecorderScript;
export 'src/stylesheet.dart' show JasprThemeScope, UniboxStylesheetScope;
export 'src/stack_node.dart' show JasprPositioned, JasprStack;
export 'src/stateful_component.dart' show JasprStateful, JasprStatefulNode;
export 'src/text_input_node.dart' show JasprTextInput;
export 'src/text_node.dart' show JasprText;
