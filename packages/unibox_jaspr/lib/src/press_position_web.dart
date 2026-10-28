import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:unibox_core/unibox_core.dart' as core;
import 'package:universal_web/web.dart' as web;

import 'press_position.dart';

/// Where [event] landed inside the element that listens, in that element's pixels.
///
/// Every number is read through `dart:js_interop`, and for two different reasons.
/// `universal_web` declares `clientX` and `offsetX` as `int`, while a browser reports
/// a fractional coordinate as soon as the device pixel ratio is not one — so the
/// typed getter throws a `TypeError` and the press is lost. That is what made a press
/// on a label do nothing at all: a label is where fractional offsets appear, and the
/// box around it kept working. And a check like `target is web.Element` says nothing
/// about an interop value, so the rectangle is read the same way rather than casting.
core.BoxPoint? pressPositionOf(web.Event event) {
  final JSObject raw = event;
  final JSNumber? clientX = raw.getProperty<JSNumber?>('clientX'.toJS);
  final JSNumber? clientY = raw.getProperty<JSNumber?>('clientY'.toJS);

  if (clientX == null || clientY == null) {
    return null;
  }

  final JSObject? listener = raw.getProperty<JSObject?>('currentTarget'.toJS);

  return pressPointInside(
    clientX: clientX.toDartDouble,
    clientY: clientY.toDartDouble,
    originX: _edgeOf(listener, 'left'),
    originY: _edgeOf(listener, 'top'),
  );
}

/// The [side] of [element]'s border box in client coordinates, or zero when there
/// is no element to ask.
///
/// An element answers `getBoundingClientRect()` with its own rect, which is the
/// frame `clientX`/`clientY` are measured in.
double _edgeOf(JSObject? element, String side) {
  if (element == null) {
    return 0;
  }

  final JSObject rect = element.callMethod<JSObject>(
    'getBoundingClientRect'.toJS,
  );

  return rect.getProperty<JSNumber>(side.toJS).toDartDouble;
}
