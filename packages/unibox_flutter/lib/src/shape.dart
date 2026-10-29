import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'values.dart';

/// The path of [shape], stretched to a box of [size].
///
/// The commands are written in the shape's view box and scaled here, which is what
/// CSS does with an SVG `viewBox` and `preserveAspectRatio="none"`: one value draws
/// the same silhouette at any size, and a non-square box stretches it rather than
/// keeping its aspect ratio.
///
/// An arc keeps its two radii as separate axes, the way SVG's `A` command does, so
/// both renderers build the same curve from the same numbers. That equivalence is
/// exact for an unrotated arc; a *rotated* ellipse in a non-square box is an affine
/// image that neither `arcToPoint` nor SVG's radii can state exactly, so both draw
/// the same approximation rather than one of them being right.
Path pathOf(core.BoxShape shape, Size size) {
  final Path path = Path();
  final double scaleX = shape.viewBoxWidth == 0
      ? 1
      : size.width / shape.viewBoxWidth;
  final double scaleY = shape.viewBoxHeight == 0
      ? 1
      : size.height / shape.viewBoxHeight;

  for (final core.BoxPathCommand command in shape.commands) {
    switch (command) {
      case core.BoxPathMoveTo(:final double x, :final double y):
        path.moveTo(x * scaleX, y * scaleY);
      case core.BoxPathLineTo(:final double x, :final double y):
        path.lineTo(x * scaleX, y * scaleY);
      case core.BoxPathCubicTo():
        path.cubicTo(
          command.control1X * scaleX,
          command.control1Y * scaleY,
          command.control2X * scaleX,
          command.control2Y * scaleY,
          command.x * scaleX,
          command.y * scaleY,
        );
      case core.BoxPathQuadraticTo():
        path.quadraticBezierTo(
          command.controlX * scaleX,
          command.controlY * scaleY,
          command.x * scaleX,
          command.y * scaleY,
        );
      case core.BoxPathArcTo():
        path.arcToPoint(
          Offset(command.x * scaleX, command.y * scaleY),
          radius: Radius.elliptical(
            command.radiusX * scaleX,
            command.radiusY * scaleY,
          ),
          rotation: command.rotation,
          largeArc: command.largeArc,
          clockwise: command.clockwise,
        );
      case core.BoxPathClose():
        path.close();
    }
  }

  path.fillType = shape.fillRule == core.BoxFillRule.evenOdd
      ? PathFillType.evenOdd
      : PathFillType.nonZero;

  return path;
}

/// Converts a Unibox [core.BoxStrokeCap] to a Flutter [StrokeCap].
///
/// The three are the ones CSS and Skia define with the same geometry, so a cap is the
/// same half disc or half square on both targets — and the mapping is exhaustive, which
/// is what makes a fourth cap a compile error rather than a silent default.
StrokeCap toStrokeCap(core.BoxStrokeCap cap) => switch (cap) {
  core.BoxStrokeCap.butt => StrokeCap.butt,
  core.BoxStrokeCap.round => StrokeCap.round,
  core.BoxStrokeCap.square => StrokeCap.square,
};

/// Paints the background and the border of a shaped box.
///
/// The fill is the box's `backgroundColor` and the border is a stroke along the
/// same path, which is what the web writes as `fill` and `stroke` on one `<path>`.
/// The stroke is centred on the outline, so half of it lies outside the box when
/// the outline touches the box's edge — as it does in CSS, where the shape's
/// `overflow` is visible.
class UniboxShapePainter extends CustomPainter {
  /// Creates a painter for [shape] filled with [fill] and stroked with [border].
  const UniboxShapePainter({required this.shape, this.fill, this.border});

  /// The outline to paint.
  final core.BoxShape shape;

  /// The colour the outline is filled with, or `null` for no fill.
  final core.BoxColor? fill;

  /// The border drawn along the outline, or `null` for no stroke.
  final core.BoxBorder? border;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = pathOf(shape, size);
    final core.BoxColor? fill = this.fill;

    if (fill != null) {
      canvas.drawPath(path, Paint()..color = toColor(fill));
    }

    final core.BoxBorder? border = this.border;

    if (border != null && border.isVisible) {
      canvas.drawPath(
        path,
        Paint()
          ..color = toColor(border.color)
          ..style = PaintingStyle.stroke
          ..strokeWidth = border.width
          // The ends of an open outline — an arc — are the ends of the stroke, so the
          // cap the border states is what draws them: round for Material's indicator.
          ..strokeCap = toStrokeCap(border.cap),
      );
    }
  }

  @override
  bool shouldRepaint(UniboxShapePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.fill != fill ||
      oldDelegate.border != border;
}

/// Clips a shaped box to its outline, the way `overflow: hidden` clips to a
/// `border-radius`.
class UniboxShapeClipper extends CustomClipper<Path> {
  /// Creates a clipper for [shape].
  const UniboxShapeClipper(this.shape);

  /// The outline to clip to.
  final core.BoxShape shape;

  @override
  Path getClip(Size size) => pathOf(shape, size);

  @override
  bool shouldReclip(UniboxShapeClipper oldClipper) => oldClipper.shape != shape;
}
