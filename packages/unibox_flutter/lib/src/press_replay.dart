import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'box.dart';

/// Answers the presses a page recorded, by pressing the widgets that wear their keys.
///
/// A press is not a callback: it is a pointer that went down somewhere. Replaying it as the
/// callback a node happens to carry is what made a component unreachable — a button keeps its
/// handler on the ink well inside it, so the node that wore the key had none to fire. Sending
/// the pointer instead is both simpler and truer: the widget's own recogniser answers, whether
/// it is a `Box`, a platform `FilledButton`, or something an application wrote.
///
/// It runs after the first frame, because a press needs a laid-out box to aim at. A key that
/// matches no widget, matches two, or is not on screen is left alone and reported: a press that
/// cannot be placed is not a press to invent a place for.
List<core.BoxPress> pressRecorded(
  Iterable<core.BoxPress> presses, {
  BuildContext? root,
}) {
  final Element? tree = root is Element
      ? root
      : WidgetsBinding.instance.rootElement;

  if (tree == null) {
    return const <core.BoxPress>[];
  }

  final List<core.BoxPress> answered = <core.BoxPress>[];
  int pointer = 0x554E;

  for (final core.BoxPress press in presses) {
    final List<Element> matches = <Element>[];
    _visitKeyed(tree, press.key, matches);

    if (matches.length != 1) {
      continue;
    }

    final Widget target = matches.single.widget;
    if (target is FlutterBox && !target.box.enabled) continue;

    final RenderObject? object =
        _tapSurface(matches.single) ?? matches.single.findRenderObject();

    if (object is! RenderBox || !object.hasSize || !object.attached) {
      continue;
    }

    final Offset centre = object.localToGlobal(object.size.center(Offset.zero));
    final view = View.of(matches.single);
    final Size viewport = view.physicalSize / view.devicePixelRatio;
    if (!(Offset.zero & viewport).contains(centre)) continue;
    final HitTestResult hit = HitTestResult();
    GestureBinding.instance.hitTestInView(hit, centre, view.viewId);
    if (!hit.path.any((HitTestEntry entry) {
      Object? target = entry.target;
      while (target is RenderObject) {
        if (identical(target, object)) return true;
        target = target.parent;
      }
      return false;
    })) {
      continue;
    }
    final int id = pointer++;

    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(position: centre, pointer: id, viewId: view.viewId),
    );
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(position: centre, pointer: id, viewId: view.viewId),
    );
    answered.add(press);
  }

  return answered;
}

/// Collects the elements below [node] whose widget wears [key].
void _visitKeyed(Element node, Object key, List<Element> found) {
  // Any `ValueKey` over the same value, whatever its type argument: a page's key is a name,
  // and `ValueKey<String>` and `ValueKey<Object>` are the same name to a reader.
  final Key? worn = node.widget.key;
  final Object? value = worn is ValueKey ? worn.value : worn;
  if (value == key ||
      ((value is String || value is int) && value.toString() == key)) {
    found.add(node);
  }

  node.visitChildren((Element child) => _visitKeyed(child, key, found));
}

// A native control may hug inside a larger keyed alignment wrapper. Its semantic
// tap surface gives replay the same hit target a reader presses, without invoking
// the callback directly or guessing a point in the wrapper's empty space.
RenderBox? _tapSurface(Element node) {
  final List<RenderBox> surfaces = <RenderBox>[];
  void visit(Element element) {
    final Widget widget = element.widget;
    if (widget is Semantics && widget.properties.onTap != null) {
      final RenderObject? object = element.findRenderObject();
      if (object is RenderBox && object.hasSize) surfaces.add(object);
      return;
    }
    element.visitChildren(visit);
  }

  visit(node);
  return surfaces.length == 1 ? surfaces.single : null;
}
