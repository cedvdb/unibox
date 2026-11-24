import 'package:unibox_core/unibox_core.dart';

/// Every node of [root], depth first.
List<UINode> flatten(UINode root) => <UINode>[
  root,
  for (final UINode child in root.children) ...flatten(child),
];

/// The text of every [TextNode] in [root], depth first.
List<String> textsIn(UINode root) =>
    flatten(root)
        .whereType<TextNode>()
        .map((TextNode node) => node.text)
        .toList();

/// The innermost box that contains a [TextNode] with [label].
Box boxAround(UINode root, String label) =>
    flatten(root)
        .whereType<Box>()
        .lastWhere((Box box) => textsIn(box).contains(label));
