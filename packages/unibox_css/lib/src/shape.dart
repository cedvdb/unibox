import 'package:unibox_core/unibox_core.dart' as core;

import 'declarations.dart';

/// The `d` attribute of [shape], in the units it was authored in.
///
/// One command after another, the way SVG writes them, so the path in the markup is the shape
/// the model states and a reader can compare the two by eye.
String cssShapePath(core.BoxShape shape) =>
    _pathData(shape, scaleX: 1, scaleY: 1);

/// The `d` attribute of [shape] in bounding box units, for a `clipPath`.
///
/// `clipPathUnits="objectBoundingBox"` is what lets one clip scale with whatever element it is
/// applied to — the reason a clip is written this way rather than with `clip-path: path()`,
/// whose numbers are pixels and would be wrong the moment the box changed size.
String cssShapeClipPath(core.BoxShape shape) => _pathData(
  shape,
  scaleX: shape.viewBoxWidth == 0 ? 0 : 1 / shape.viewBoxWidth,
  scaleY: shape.viewBoxHeight == 0 ? 0 : 1 / shape.viewBoxHeight,
);

/// The id of the `clipPath` [shape] writes, derived from its outline.
///
/// The same outline gets the same id, so a page that draws one shape ten times writes the same
/// definition ten times instead of needing a registry: `url(#…)` resolves to the first of them,
/// and they are identical.
String cssShapeClipId(core.BoxShape shape) =>
    'unibox-shape-${fnv1a(cssShapeClipPath(shape))}';

/// [shape] as an SVG `d`, with every coordinate multiplied by the axis scales.
String _pathData(
  core.BoxShape shape, {
  required double scaleX,
  required double scaleY,
}) {
  final List<String> parts = <String>[];

  for (final core.BoxPathCommand command in shape.commands) {
    switch (command) {
      case core.BoxPathMoveTo(:final double x, :final double y):
        parts.add('M${_scaled(x, scaleX)} ${_scaled(y, scaleY)}');
      case core.BoxPathLineTo(:final double x, :final double y):
        parts.add('L${_scaled(x, scaleX)} ${_scaled(y, scaleY)}');
      case core.BoxPathCubicTo():
        parts.add(
          'C${_scaled(command.control1X, scaleX)} '
          '${_scaled(command.control1Y, scaleY)} '
          '${_scaled(command.control2X, scaleX)} '
          '${_scaled(command.control2Y, scaleY)} '
          '${_scaled(command.x, scaleX)} ${_scaled(command.y, scaleY)}',
        );
      case core.BoxPathQuadraticTo():
        parts.add(
          'Q${_scaled(command.controlX, scaleX)} '
          '${_scaled(command.controlY, scaleY)} '
          '${_scaled(command.x, scaleX)} ${_scaled(command.y, scaleY)}',
        );
      case core.BoxPathArcTo():
        parts.add(
          'A${_scaled(command.radiusX, scaleX)} '
          '${_scaled(command.radiusY, scaleY)} '
          '${_number(command.rotation)} '
          '${command.largeArc ? 1 : 0} ${command.clockwise ? 1 : 0} '
          '${_scaled(command.x, scaleX)} ${_scaled(command.y, scaleY)}',
        );
      case core.BoxPathClose():
        parts.add('Z');
    }
  }

  return parts.join(' ');
}

/// [value] multiplied by [scale], written the way CSS writes a number.
String _scaled(double value, double scale) => _number(value * scale);

/// [value] with four decimals at most, which is a pixel of a large view box.
///
/// A path's numbers are read by a browser and by a reader, and both prefer a short one: the
/// division that puts an outline in bounding box units produces long fractions otherwise.
String _number(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e9) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
