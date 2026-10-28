import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'box.dart';
import 'default_typography.dart';
import 'embed_node.dart';
import 'grid_node.dart';
import 'image_node.dart';
import 'keys.dart';
import 'link_node.dart';
import 'overlay_node.dart';
import 'stack_node.dart';
import 'stateful_node.dart';
import 'stylesheet.dart';
import 'text_input_node.dart';
import 'text_node.dart';

/// Renders [node] as a Jaspr [Component].
///
/// In debug builds the tree is validated first: a tree that a renderer cannot
/// honour is printed to stdout, and an invalid one throws a [StateError].
///
/// The tree is preceded by the typography of the model
/// ([core.BoxTextStyle.defaults]) as a `:root` rule, so a text that declares
/// nothing is typeset the way the Flutter renderer typesets it instead of the way
/// a browser happens to default. The rule states only what the model declares: a
/// host that sets a `font-family` keeps it, and a box in the tree can declare any
/// token to override the default for its subtree.
///
/// Node types without a web renderer yet throw an [UnsupportedError] so a
/// partially rendered tree can never be shipped silently.
///
/// Every component is created with the key of its node, so reordering a list of
/// nodes keeps each element (and the DOM state it owns) attached to the node it
/// belongs to.
///
/// The declarations of the whole tree are collected into one stylesheet
/// (`UniboxStylesheet`): an element carries a class, never an inline style, so a
/// page repeats a look once however many elements wear it, and a host can
/// override any of it — with a CSS custom property, a `@media` block or a
/// stylesheet of its own. Rendering a component on its own, without
/// [renderJaspr], writes the declarations inline instead.
/// [theme] answers the colour roles the tree names: the roles are written as
/// custom properties and the theme itself as one `:root` block, which is what lets
/// a host stylesheet or a dark-mode block outrank the tree. A tree that names a
/// role and is given no theme fails with the role in the message.
///
/// Every element the tree draws carries the name of the node that drew it
/// (`data-unibox-node="material-card"`), so an inspector reads the tree instead
/// of a wall of hashes. It changes nothing else — the same classes, the same
/// rules, the same elements — and it is not a switch, because an attribute that
/// carries no look has nothing to turn off.
Component renderJaspr(core.UINode node, {core.UniboxTheme? theme}) {
  _reportTreeIssues(node, theme);

  final UniboxStylesheet sheet = UniboxStylesheet();
  final Component tree = UniboxStylesheetScope(
    sheet: sheet,
    child: renderNode(node),
  );

  return Component.fragment(<Component>[
    const JasprDefaultTypography(),
    if (theme == null) tree else JasprThemeScope(theme: theme, child: tree),
    // After the tree: every component has registered its class by the time this
    // is built. CSS applies wherever the element sits, so the `<style>` is one
    // element regardless of the page it lands in.
    JasprStylesheet(sheet: sheet, theme: theme),
  ]);
}

/// Renders [node] without validating its subtree.
///
/// The renderers use it for children, which were validated as part of the tree
/// their caller rendered. Prefer [renderJaspr].
Component renderNode(core.UINode node) {
  return switch (node) {
    final core.Box box => JasprBox(box: box, key: toJasprKey(box.key)),
    final core.ImageNode image => JasprImage(
      node: image,
      key: toJasprKey(image.key),
    ),
    final core.GridNode grid => JasprGrid(
      node: grid,
      key: toJasprKey(grid.key),
    ),
    final core.LinkNode link => JasprLink(
      node: link,
      key: toJasprKey(link.key),
    ),
    final core.StackNode stack => JasprStack(
      node: stack,
      key: toJasprKey(stack.key),
    ),
    final core.PositionedNode positioned => Component.fragment(<Component>[
      renderNode(positioned.child),
    ], key: toJasprKey(positioned.key)),
    final core.TextInputNode textInput => JasprTextInput(
      node: textInput,
      key: toJasprKey(textInput.key),
    ),
    final core.TextNode text => JasprText(
      node: text,
      key: toJasprKey(text.key),
    ),
    final core.EmbedNode embed => Component.fragment(<Component>[
      _renderEmbed(embed),
    ], key: toJasprKey(embed.key)),
    final core.OverlayNode overlay => JasprOverlay(
      node: overlay,
      key: toJasprKey(overlay.key),
    ),
    final core.StatefulNode<Object, core.Store<Object>> stateful =>
      statefulView(stateful),
    _ => throw UnsupportedError('No Jaspr renderer for ${node.runtimeType}.'),
  };
}

/// Renders the implementation of [embed] this target can draw.
///
/// The model keeps the payloads opaque, so the choice is made here: the first
/// payload that is a [Component] is rendered as it is, and the first that is a
/// [JasprComponentEmbedBuilder] receives the rendered child, because an effect that
/// wraps content needs the content. A node whose implementations this target
/// cannot draw, or that carries two of them, is reported instead of silently
/// skipped — a class the library has never seen renders here as long as it brings
/// one of these two shapes.
Component _renderEmbed(core.EmbedNode embed) {
  final List<Object> implementations = embed.implementations;
  final List<Object> drawable = implementations
      .where((Object it) => it is Component || it is JasprComponentEmbedBuilder)
      .toList(growable: false);

  if (drawable.isEmpty) {
    throw UnsupportedError(
      'No Jaspr renderer for ${embed.runtimeType}: this target draws a Component '
      'or a JasprComponentEmbedBuilder, and the node carries '
      '${implementations.map((Object it) => it.runtimeType).join(', ')}.',
    );
  }

  if (drawable.length > 1) {
    throw StateError(
      '${embed.runtimeType} carries ${drawable.length} implementations this '
      'target can draw, so the tree is ambiguous: keep one payload per renderer.',
    );
  }

  final Object implementation = drawable.single;

  if (implementation is Component) {
    return implementation;
  }

  final core.UINode? child = embed.child;

  if (child == null) {
    throw StateError(
      '${embed.runtimeType} is drawn by a JasprComponentEmbedBuilder, which wraps the '
      'child of the embed, but the node has no child.',
    );
  }

  return (implementation as JasprComponentEmbedBuilder)(renderNode(child));
}

/// Reports the tree issues of [node], in debug builds only.
///
/// Server rendering has no widget inspector, so warnings go to stdout next to
/// the request log, while errors throw to stop the response before it is wrong.
void _reportTreeIssues(core.UINode node, core.UniboxTheme? theme) {
  assert(() {
    final List<core.TreeIssue> issues = core.validateTree(node, theme: theme);
    final List<core.TreeIssue> errors = issues
        .where((core.TreeIssue issue) => issue.isError)
        .toList(growable: false);

    if (errors.isNotEmpty) {
      throw StateError(
        'Unibox: the node tree cannot be rendered:\n${errors.join('\n')}',
      );
    }

    for (final core.TreeIssue issue in issues) {
      // ignore: avoid_print
      print('Unibox warning: $issue');
    }

    return true;
  }());
}

/// Renders any Unibox node as a Jaspr [Component].
extension UINodeJasprRenderer on core.UINode {
  /// Returns the Jaspr component for this node.
  ///
  /// ```dart
  /// runApp(const Box(padding: BoxSpacing.all(16)).toComponent());
  /// ```
  Component toComponent({core.UniboxTheme? theme}) =>
      renderJaspr(this, theme: theme);
}
