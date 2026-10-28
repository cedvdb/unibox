import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'render.dart';
import 'theme_scope.dart';

/// Renders a [core.StatefulNode]: one store and the tree of its state.
///
/// The widget creates the store once, when it is mounted, subscribes to it,
/// calls [core.Store.onMount] and disposes it on unmount — so a rebuild with a
/// node of the same type and key keeps the state, and a different key starts
/// again.
///
/// The view is rendered in place, so it inherits the typography and the layout
/// of the boxes around it. A view draws one tree, and an overlay it returns is
/// presented on the root overlay.
class FlutterStateful extends StatefulWidget {
  /// Creates a renderer for [node].
  ///
  /// [theme] answers the colour roles the tree names, the way it does for
  /// `renderFlutter`: a host that roots its application in a stateful node writes it
  /// once here instead of remembering a scope around it — which is also the scope an
  /// overlay reads when it hands the theme on.
  const FlutterStateful({required this.node, this.theme, super.key});

  /// The node being rendered.
  final core.StatefulNode<Object, core.Store<Object>> node;

  /// The values the roles of the tree stand for, or `null` when the tree names none.
  final core.UniboxTheme? theme;

  @override
  State<FlutterStateful> createState() => FlutterStatefulState();
}

class FlutterStatefulState extends State<FlutterStateful> {
  late core.Store<Object> _store;

  @override
  void initState() {
    super.initState();
    _store = widget.node.createStore()..addListener(_changed);
    _store.onMount();
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
    final Widget tree = renderNode(widget.node.viewFor(_store.state, _store));
    final core.UniboxTheme? theme = widget.theme;

    return theme == null ? tree : UniboxThemeScope(theme: theme, child: tree);
  }
}
