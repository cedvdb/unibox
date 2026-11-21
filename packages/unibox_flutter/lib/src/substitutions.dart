import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

/// Builds the widget drawn in place of a node.
///
/// [content] is what this renderer would draw inside the node — its children, laid out
/// with the direction, the gap, the alignment and the padding the node asked for — or
/// `null` for a node with no inside, which is an image and every other leaf. A builder
/// that is a surface (a card, a sheet) wraps [content]; a builder that is a whole control
/// (a platform's navigation bar, which lays its own destinations out) ignores it.
typedef NodeSubstitution = Widget Function(
  BuildContext context,
  core.UINode node,
  Widget? content,
);

/// The widgets an application asks this renderer to draw instead of its own.
///
/// A tree describes a screen for two renderers. Most of the time that means the model's
/// values are the look, and both targets draw them — which is what keeps a page and an
/// application the same screen. Sometimes an application would rather have the platform's
/// own component: a Flutter app that already uses `Card` or `NavigationBar` keeps their
/// behaviour (the ink, the click, the text scaling, the accessibility work a widget carries
/// and a token cannot) if the app draws them.
///
/// That is what a substitution is for, and it is deliberately narrow:
///
/// - **Keyed by the exact runtime type of the node.** A substitution for `MaterialCard`
///   draws cards; it does not draw every `Box`, and it cannot quietly take over a tree.
/// - **Refused for the structural nodes** — the ones that carry the model's layout and
///   text. A box, a text, a stack, a grid: substituting one of those is not a component
///   preference, it is a second renderer, and it would end the promise that one tree looks
///   the same on both targets.
/// - **Paint only.** What a substitution may change is how a component looks and behaves.
///   What it may not change is the information: the same text, the same order, the same
///   links, the same semantics and the same tap targets. A page and an app that disagree
///   about content were never the same screen.
///
/// The document renderer has no substitutions and needs none: it draws the values, always.
///
/// ```dart
/// renderFlutter(page, substitutions: UniboxSubstitutions(<Type, NodeSubstitution>{
///   MaterialCard: (BuildContext context, core.UINode node, Widget? content) =>
///       Card(child: content),
/// }));
/// ```
final class UniboxSubstitutions {
  /// No substitutions: every node is drawn by this renderer, which is the default.
  const UniboxSubstitutions.none()
    : _builders = const <Type, NodeSubstitution>{};

  /// The substitutions in [builders], keyed by the exact runtime type of the node.
  ///
  /// Throws an [ArgumentError] for a structural node, which is the one thing a
  /// substitution may not do: see the class documentation.
  factory UniboxSubstitutions(Map<Type, NodeSubstitution> builders) {
    for (final Type type in builders.keys) {
      if (_structural.contains(type)) {
        throw ArgumentError.value(
          type,
          'builders',
          'A structural node cannot be substituted: it carries the layout and the text '
              'both renderers owe, so replacing it would end the parity the tree '
              'promises. Substitute a component instead.',
        );
      }
    }

    return UniboxSubstitutions._(
      Map<Type, NodeSubstitution>.unmodifiable(builders),
    );
  }

  const UniboxSubstitutions._(this._builders);

  final Map<Type, NodeSubstitution> _builders;

  /// The nodes this map refuses, because they are the model rather than a component.
  ///
  /// The list is by exact type, which is the rule a substitution is keyed by: a component
  /// that extends a box is its own type and is still substitutable, while the box itself is
  /// not.
  static const Set<Type> _structural = <Type>{
    core.Box,
    core.TextNode,
    core.LinkNode,
    core.PagerNode,
    core.StackNode,
    core.PositionedNode,
    core.GridNode,
    core.TextInputNode,
    core.OverlayNode,
    core.EmbedNode,
  };

  /// The substitution for [node], or `null` when the application asked for none.
  NodeSubstitution? forNode(core.UINode node) => _builders[node.runtimeType];

  /// Whether any node is substituted at all.
  bool get isEmpty => _builders.isEmpty;

  /// Whether [node]'s own type is substituted.
  bool contains(core.UINode node) => _builders.containsKey(node.runtimeType);

  @override
  bool operator ==(Object other) =>
      other is UniboxSubstitutions && identical(_builders, other._builders);

  @override
  int get hashCode => identityHashCode(_builders);

  @override
  String toString() => 'UniboxSubstitutions(${_builders.length} node types)';
}

/// Hands the substitutions of a rendering to the nodes inside it.
///
/// It travels with the widgets rather than as an argument because the nodes are built from
/// the tree's own build methods, at every depth: a card inside a card inside a list is drawn
/// by the same renderer, and each of them has to find the map. A rendering without
/// substitutions is a rendering without this widget around it, which is the default and
/// costs nothing.
class UniboxSubstitutionsWidget extends InheritedWidget {
  /// Creates the scope around [child].
  const UniboxSubstitutionsWidget({
    required this.substitutions,
    required super.child,
    super.key,
  });

  /// The substitutions in force below this widget.
  final UniboxSubstitutions substitutions;

  /// The substitutions in force, or `null` when the host asked for none.
  static UniboxSubstitutions? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<UniboxSubstitutionsWidget>()
      ?.substitutions;

  /// The widget to draw in place of [node], or `null` when nothing is substituted for it.
  ///
  /// [content] is the node's inside, as this renderer built it.
  static Widget? substitute(
    BuildContext context,
    core.UINode node,
    Widget? content,
  ) => maybeOf(context)?.forNode(node)?.call(context, node, content);

  @override
  bool updateShouldNotify(UniboxSubstitutionsWidget oldWidget) =>
      oldWidget.substitutions != substitutions;
}
