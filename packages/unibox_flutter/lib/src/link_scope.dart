import 'dart:async';

import 'package:flutter/widgets.dart';

/// Follows a destination the tree states: the `url` of a box that navigates.
typedef FlutterLinkOpener = FutureOr<void> Function(String url);

/// Configures how a tree opens the destination of a box that navigates.
///
/// Flutter has no built-in browser, so the host application decides what following a
/// destination means, e.g. with `url_launcher`:
///
/// ```dart
/// FlutterLinkScope(
///   open: (String url) => launchUrl(Uri.parse(url)),
///   child: renderFlutter(page),
/// );
/// ```
///
/// A box with a `url` calls it — unless the box has an `onTap`, which answers the press
/// itself, so one press has one answer: the rule the web renderer states by cancelling the
/// navigation instead of loading the document as well. A destination with neither a scope
/// nor an `onTap` would look tappable and do nothing, so rendering one is reported as a host
/// configuration error in debug builds. `Box.newTab` only affects the web renderer.
class FlutterLinkScope extends InheritedWidget {
  /// Creates a scope that opens destinations with [open].
  const FlutterLinkScope({required this.open, required super.child, super.key});

  /// Follows the url a node points at, the way the host application navigates.
  final FlutterLinkOpener open;

  /// The opener of the closest enclosing scope, or `null` when there is none.
  static FlutterLinkOpener? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlutterLinkScope>()?.open;
  }

  @override
  bool updateShouldNotify(FlutterLinkScope oldWidget) => open != oldWidget.open;
}
