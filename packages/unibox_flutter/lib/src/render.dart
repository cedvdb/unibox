import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'box.dart';
import 'embed_node.dart';
import 'grid_node.dart';
import 'image_node.dart';
import 'keys.dart';
import 'overlay_node.dart';
import 'stack_node.dart';
import 'stateful_node.dart';
import 'theme_scope.dart';
import 'text_input_node.dart';
import 'text_node.dart';
import 'text_style_scope.dart';
import 'values.dart';

/// Renders [node] as a Flutter [Widget].
///
/// ```dart
/// runApp(renderFlutter(myNode));
/// ```
///
/// In debug builds the tree is validated first: a tree that a renderer cannot
/// honour reports the offending nodes through [debugPrint], and an invalid one
/// throws a [StateError].
///
/// The tree is wrapped in the typography of the model
/// ([core.BoxTextStyle.defaults]), so a text that declares nothing is typeset the
/// way the web renderer typesets it instead of the way this host happens to
/// default. The wrapper only lays its style over the ambient one: a host that
/// provides a font family — through a `MaterialApp` theme, say — keeps it, and a
/// box in the tree can declare any token to override it.
///
/// Throws an [UnsupportedError] when [node] has no Flutter renderer yet.
///
/// A [core.PositionedNode] only carries offsets for an enclosing
/// [core.StackNode], so rendering one on its own renders its child.
///
/// Every widget is created with the key of its node, so reordering a list of
/// nodes preserves the state of each child instead of moving it to the node
/// that took over the position.
/// [theme] answers the colour roles the tree names. A tree that uses none renders
/// without one; a tree that names one and is given none fails with the role in the
/// message instead of painting nothing.
Widget renderFlutter(core.UINode node, {core.UniboxTheme? theme}) {
  _reportTreeIssues(node, theme);

  final Widget tree = renderNode(node);

  return _withDefaultTypography(
    theme == null ? tree : UniboxThemeScope(theme: theme, child: tree),
  );
}

/// Wraps [child] in the typography of the model, `BoxTextStyle.defaults`.
///
/// The web renderer answers the same question with a `:root` rule, so a text
/// that declares nothing looks the same on both targets instead of inheriting
/// each host's own default. `DefaultTextStyle.merge` only lays the tokens of the
/// default over the ambient style, so a host that brought a font family — through
/// a `MaterialApp` theme, say — keeps it: the model owns what a text looks like,
/// the application owns which font it is.
///
/// A `TextField` ignores the default text style and reads
/// [FlutterTextStyleScope] instead, so the default is installed in both: without
/// it a field would fall back to the Material input style while the `<input>` of
/// the web renderer inherits the tree's typography.
Widget _withDefaultTypography(Widget child) {
  return DefaultTextStyle.merge(
    style: toTextStyle(core.BoxTextStyle.defaults),
    child: FlutterTextStyleScope(
      style: core.BoxTextStyle.defaults,
      child: child,
    ),
  );
}

/// Renders [node] without validating its subtree.
///
/// The renderers use it for children, which were validated as part of the tree
/// their caller rendered. Prefer [renderFlutter].
///
/// [availableWidth] is the width, in logical pixels, of the layout box the node is
/// drawn in. A box hands it to the children that name a width threshold, which is
/// how a threshold measures the box it is drawn in rather than the window — the
/// same measurement the web renderer makes with a container query. `null` means the
/// width is unknown, and a threshold then reads as unbounded.
Widget renderNode(core.UINode node, {double? availableWidth}) {
  return switch (node) {
    final core.Box box => FlutterBox(
      box: box,
      availableWidth: availableWidth,
      key: toFlutterKey(box.key),
    ),
    final core.TextNode text => FlutterText(
      node: text,
      key: toFlutterKey(text.key),
    ),
    final core.ImageNode image => FlutterImage(
      node: image,
      key: toFlutterKey(image.key),
    ),
    final core.GridNode grid => FlutterGrid(
      node: grid,
      key: toFlutterKey(grid.key),
    ),
    final core.StackNode stack => FlutterStack(
      node: stack,
      key: toFlutterKey(stack.key),
    ),
    final core.PositionedNode positioned => KeyedSubtree(
      key: toFlutterKey(positioned.key),
      child: renderNode(positioned.child),
    ),
    final core.TextInputNode input => FlutterTextInput(
      node: input,
      key: toFlutterKey(input.key),
    ),
    final core.EmbedNode embed => KeyedSubtree(
      key: toFlutterKey(embed.key),
      child: _renderEmbed(embed),
    ),
    final core.OverlayNode overlay => FlutterOverlay(
      node: overlay,
      key: toFlutterKey(overlay.key),
    ),
    final core.StatefulNode<Object, core.Store<Object>> stateful =>
      FlutterStateful(node: stateful, key: toFlutterKey(stateful.key)),
    _ => throw UnsupportedError('No Flutter renderer for ${node.runtimeType}.'),
  };
}

/// Renders the implementation of [embed] this target can draw.
///
/// The model keeps the payloads opaque, so the choice is made here: the first
/// payload that is a [Widget] is drawn as it is, and the first that is a
/// [FlutterWidgetEmbedBuilder] receives the rendered child, because an effect that wraps
/// content needs the content. A node whose implementations this target cannot
/// draw, or that carries two of them, is reported instead of silently skipped —
/// a class the library has never seen renders here as long as it brings one of
/// these two shapes.
Widget _renderEmbed(core.EmbedNode embed) {
  final List<Object> implementations = embed.implementations;
  final List<Object> drawable = implementations
      .where((Object it) => it is Widget || it is FlutterWidgetEmbedBuilder)
      .toList(growable: false);

  if (drawable.isEmpty) {
    throw UnsupportedError(
      'No Flutter renderer for ${embed.runtimeType}: this target draws a Widget '
      'or a FlutterWidgetEmbedBuilder, and the node carries '
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

  if (implementation is Widget) {
    return implementation;
  }

  final core.UINode? child = embed.child;

  if (child == null) {
    throw StateError(
      '${embed.runtimeType} is drawn by a FlutterWidgetEmbedBuilder, which wraps the '
      'child of the embed, but the node has no child.',
    );
  }

  return (implementation as FlutterWidgetEmbedBuilder)(renderNode(child));
}

/// Reports the tree issues of [node], in debug builds only.
///
/// Warnings are printed, errors throw: a tree that no target can render has to
/// fail loudly while it is being built, not silently in production.
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
      debugPrint('Unibox warning: $issue');
    }

    return true;
  }());
}

/// Flutter rendering helpers for Unibox nodes.
extension UINodeFlutterRenderer on core.UINode {
  /// Renders this node as a Flutter [Widget].
  ///
  /// Shorthand for `renderFlutter(this, theme: theme)`, and it takes the theme
  /// for the same reason `renderFlutter` does: a tree built from colour roles
  /// names them, and validation rejects a role no theme answers before a widget
  /// is built. Without the argument the shorthand could not draw a themed tree
  /// at all — which is most of them.
  ///
  /// ```dart
  /// runApp(MaterialApp(home: page.toWidget(theme: palette)));
  /// ```
  Widget toWidget({core.UniboxTheme? theme}) =>
      renderFlutter(this, theme: theme);
}
