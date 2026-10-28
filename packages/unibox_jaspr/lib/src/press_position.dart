import 'package:unibox_core/unibox_core.dart' as core;

export 'press_position_stub.dart'
    if (dart.library.js_interop) 'press_position_web.dart';

/// Where a press landed inside the box that listens, in the box's own pixels.
///
/// Measured from the box, not from the element the pointer hit: `offsetX` and
/// `offsetY` are relative to the hit target, and a press on a label is reported in
/// the label's frame — which put an ink drop somewhere else entirely, or nowhere at
/// all once the drop was clipped to the well around it. These are the two pairs of
/// numbers a browser can give, so this is the arithmetic on its own, away from the
/// DOM, where a suite can pin it.
core.BoxPoint pressPointInside({
  required double clientX,
  required double clientY,
  required double originX,
  required double originY,
}) => core.BoxPoint(clientX - originX, clientY - originY);
