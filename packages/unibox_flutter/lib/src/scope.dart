import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

/// Hands the scope of a rendering to the boxes and texts inside it.
///
/// It is a scope and not a lookup: the scope arrives as an argument to `renderFlutter` and travels
/// down the widget tree, so nothing reads ambient state a host did not give, and every node below
/// resolves against the same value. A widget built outside a rendering finds no scope and resolves
/// against [core.UniboxScope.none], which fails loudly on the first colour role it meets.
///
/// The name carries `Widget` because `UniboxScope` is the model's value and a widget cannot take
/// that name — the one place in this package where a widget's name is not the node's.
class UniboxScopeWidget extends InheritedWidget {
  /// Creates the scope around [child].
  const UniboxScopeWidget({
    required this.scope,
    required super.child,
    super.key,
  });

  /// What the rendering is drawn against: its theme, its language and its direction.
  final core.UniboxScope scope;

  /// The scope in force, or [core.UniboxScope.none] when there is none.
  static core.UniboxScope of(BuildContext context) =>
      maybeOf(context) ?? core.UniboxScope.none;

  /// The scope in force, or `null` when there is none.
  static core.UniboxScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UniboxScopeWidget>()?.scope;

  @override
  bool updateShouldNotify(UniboxScopeWidget oldWidget) =>
      oldWidget.scope != scope;
}
