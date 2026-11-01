import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'render.dart';
import 'scope.dart';
import 'unibox_ready.dart';

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
    this.presses = const <core.BoxPress>[],
    super.key,
  });

  /// The node being rendered.
  final core.StatefulNode<Object, core.Store<Object>> node;

  /// What the rendering is drawn against, and what the roles of the tree stand for.
  final core.UniboxScope scope;

  /// The presses a page recorded before this node existed.
  ///
  /// They are answered once, against the first view this node builds — which is the only place
  /// their callbacks exist: the view is a function of the store, and the store is created when
  /// this widget mounts. A press whose key matches no node, or two of them, is dropped rather
  /// than guessed at; see `replayPresses`.
  final List<core.BoxPress> presses;

  @override
  State<FlutterStateful> createState() => FlutterStatefulState();
}

class FlutterStatefulState extends State<FlutterStateful> {
  late core.Store<Object> _store;

  /// Whether the recorded presses have been answered, which happens once per mounting.
  bool _replayed = false;

  /// An accessibility tree, when a document handed this application the page.
  ///
  /// Flutter ships semantics off on the web, so a canvas that arrives by takeover has exactly one
  /// focusable thing in it until something asks for a tree. The handle is kept for the life of
  /// this state because letting it go turns the tree off again.
  SemanticsHandle? _semantics;

  @override
  void initState() {
    super.initState();
    _store = widget.node.createStore()..addListener(_changed);
    _store.onMount();

    // A page that was handed over is read with a screen reader and watched by a document waiting
    // to be sure the application has drawn: both are answered here, so a host writes nothing.
    if (wasTakenOver) {
      _semantics = SemanticsBinding.instance.ensureSemantics();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          uniboxReady();
        }
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
    _semantics?.dispose();
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
    final core.UINode view = widget.node.viewFor(_store.state, _store);

    // A press is answered where its callback is: the view just built, with the store it closed
    // over. Once, so a rebuild does not press again.
    if (!_replayed && widget.presses.isNotEmpty) {
      _replayed = true;
      core.replayPresses(view, widget.presses);
    }

    final Widget tree = renderNode(view);
    final core.UniboxScope scope = widget.scope;

    return scope == core.UniboxScope.none
        ? tree
        : UniboxScopeWidget(scope: scope, child: tree);
  }
}
