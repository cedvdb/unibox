import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'press_replay.dart';
import 'render.dart';
import 'scope.dart';
import 'substitutions.dart';

/// Renders a [core.StatefulNode]: one store and the tree of its state.
///
/// The widget creates the store once, when it is mounted, subscribes to it,
/// calls [core.Store.onMount] and disposes it on unmount — so a rebuild with a
/// node of the same type and key keeps the state, and a different key starts
/// again. The node drawn again is the parameter the store cannot see: it hands the
/// store to [core.StatefulNode.update] before building, which is how a component
/// whose state copied a parameter stays right.
///
/// The view is rendered in place, so it inherits the typography and the layout
/// of the boxes around it. A view draws one tree, and an overlay it returns is
/// presented on the root overlay.
class FlutterStateful extends StatefulWidget {
  /// Creates a renderer for [node].
  ///
  /// [scope] answers the colour roles the tree names, the way it does for
  /// `renderFlutter`: a host that roots its application in a stateful node writes it
  /// once here instead of remembering a scope around it — which is also the scope an
  /// overlay reads when it hands the theme on.
  const FlutterStateful({
    required this.node,
    this.scope = core.UniboxScope.none,
    this.substitutions = const UniboxSubstitutions.none(),
    this.presses = const <core.BoxPress>[],
    super.key,
  });

  /// The node being rendered.
  final core.StatefulNode<Object, core.Store<Object>> node;

  /// What the rendering is drawn against, and what the roles of the tree stand for.
  final core.UniboxScope scope;

  /// The components the host would rather draw with the platform's own widget.
  ///
  /// It travels here for the reason [scope] does: the view is built inside this widget, so a
  /// host that roots its application in a stateful node has nowhere else to say it. Empty by
  /// default, which draws every node from the model's values.
  final UniboxSubstitutions substitutions;

  /// The presses a page recorded before this node existed.
  ///
  /// They are answered once, after the first frame, by *pressing* the widgets that wear their
  /// keys: a recorded press is a pointer that went down somewhere, so the widget's own
  /// recogniser answers it — a box, a platform `FilledButton`, anything an application wrote.
  /// A key that matches no widget, matches two, or is not on screen is reported rather than
  /// guessed at; see `pressRecorded`.
  final List<core.BoxPress> presses;

  @override
  State<FlutterStateful> createState() => FlutterStatefulState();
}

class FlutterStatefulState extends State<FlutterStateful> {
  late core.Store<Object> _store;

  /// Whether the recorded presses have been answered, which happens once per mounting.
  bool _replayed = false;

  @override
  void initState() {
    super.initState();
    _store = widget.node.createStore()..addListener(_changed);
    _store.onMount();

    // A press a page recorded before this application existed is answered once the first frame
    // has laid the tree out, because a press is a pointer and needs a box to aim at: the widget
    // that wears the key answers it, which is how a platform button answers at all.
    if (widget.presses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _replayed) {
          return;
        }

        _replayed = true;
        pressRecorded(widget.presses, root: context);
      });
    }
  }

  @override
  void didUpdateWidget(FlutterStateful oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The same place in the tree drew this component again, so this is the store it
    // keeps — and the node is where the parameters that changed are. A publish from the
    // reconciliation reaches `setState` like any other, before the build that follows.
    if (!identical(oldWidget.node, widget.node)) {
      widget.node.updateFor(_store.state, _store);
    }
  }

  @override
  void dispose() {
    _store.onUnmount();
    _store.removeListener(_changed);
    _store.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // A component the host draws with its own widget takes the whole node, the way a box is
    // taken: a field, a tab set and a spinner are stateful, and none of them is drawn from a
    // surface the way a card is.
    final Widget? substituted = UniboxSubstitutionsWidget.substitute(
      context,
      widget.node,
      null,
    );

    if (substituted != null) {
      return substituted;
    }

    final core.UINode view = widget.node.viewFor(_store.state, _store);

    final Widget drawn = renderNode(view);
    final Widget tree = widget.substitutions.isEmpty
        ? drawn
        : UniboxSubstitutionsWidget(
            substitutions: widget.substitutions,
            child: drawn,
          );
    final core.UniboxScope scope = widget.scope;

    return scope == core.UniboxScope.none
        ? tree
        : UniboxScopeWidget(scope: scope, child: tree);
  }
}
