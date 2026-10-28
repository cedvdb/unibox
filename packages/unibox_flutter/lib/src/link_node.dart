import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'render.dart';

/// Follows the destination of a [core.LinkNode].
typedef FlutterLinkOpener = FutureOr<void> Function(String url);

/// Configures how [core.LinkNode]s open their destination on Flutter.
///
/// Flutter has no built-in browser, so the host application decides what
/// following a link means, e.g. with `url_launcher`:
///
/// ```dart
/// FlutterLinkScope(
///   open: (String url) => launchUrl(Uri.parse(url)),
///   child: renderFlutter(node),
/// );
/// ```
///
/// Without a scope, a link only calls its own [core.LinkNode.onTap]. A link
/// with neither a scope nor an `onTap` would look tappable and do nothing on
/// tap, so rendering one is reported as a host configuration error in debug
/// builds.
/// [core.LinkNode.newTab] only affects the web renderer.
class FlutterLinkScope extends InheritedWidget {
  /// Creates a scope that opens links with [open].
  const FlutterLinkScope({required this.open, required super.child, super.key});

  /// Follows the url a link points at, the way the host application navigates.
  final FlutterLinkOpener open;

  /// The opener of the closest enclosing scope, or `null` when there is none.
  static FlutterLinkOpener? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlutterLinkScope>()?.open;
  }

  @override
  bool updateShouldNotify(FlutterLinkScope oldWidget) => open != oldWidget.open;
}

/// Renders a [core.LinkNode] as a tappable region around its child.
///
/// A press is answered once. A node that carries an [core.LinkNode.onTap] names the
/// handler for it, so that handler runs and the opener is not called: on the web the
/// same rule cancels the navigation, and a dialog the tree opens is not replaced by
/// a page load. A node without one is what the enclosing [FlutterLinkScope] is for.
class FlutterLink extends StatelessWidget {
  /// Creates a renderer for [node].
  const FlutterLink({required this.node, super.key});

  /// The node being rendered.
  final core.LinkNode node;

  @override
  Widget build(BuildContext context) {
    final FlutterLinkOpener? open = FlutterLinkScope.maybeOf(context);

    assert(
      open != null || node.onTap != null,
      'Unibox: "${node.url}" is rendered as a link, but no FlutterLinkScope is '
      'above it and the node has no onTap, so tapping it does nothing. Wrap '
      'the tree in an FlutterLinkScope(open: ...) or give the LinkNode an '
      'onTap callback.',
    );

    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final core.TapCallback? onTap = node.onTap;

            if (onTap != null) {
              onTap();
            } else {
              open?.call(node.url);
            }
          },
          child: renderNode(node.child),
        ),
      ),
    );
  }
}
