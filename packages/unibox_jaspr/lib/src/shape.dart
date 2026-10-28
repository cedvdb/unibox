import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'stylesheet.dart';

/// The `d` attribute of [shape], in its own view box units.
///
/// One command after another, the way SVG writes them, so the path in the markup
/// is the shape the model states and a reader can compare the two by eye.
String pathDataOf(core.BoxShape shape) =>
    _pathData(shape, scaleX: 1, scaleY: 1);

/// The `d` attribute of [shape] in bounding box units, for a `clipPath`.
///
/// `clipPathUnits="objectBoundingBox"` is what lets one clip scale with whatever
/// element it is applied to — the reason a clip is written this way instead of
/// with `clip-path: path()`, whose numbers are pixels and would be wrong the
/// moment the box changed size.
String clipPathDataOf(core.BoxShape shape) => _pathData(
  shape,
  scaleX: shape.viewBoxWidth == 0 ? 0 : 1 / shape.viewBoxWidth,
  scaleY: shape.viewBoxHeight == 0 ? 0 : 1 / shape.viewBoxHeight,
);

/// The id of the `clipPath` [shape] writes, derived from its outline.
///
/// The same outline gets the same id, so a page that draws one shape ten times
/// writes the same definition ten times instead of needing a registry: `url(#…)`
/// resolves to the first of them, and they are identical.
String clipIdOf(core.BoxShape shape) =>
    'unibox-shape-${fnv1a(clipPathDataOf(shape))}';

/// Renders the outline of a [core.BoxShape] as the paint layer of a box.
///
/// An `<svg>` stretched over the box, so the outline scales with it, with one
/// `<path>` inside. The path carries no colour of its own: `fill`, `stroke` and
/// `stroke-width` read three custom properties, which is what makes a shape
/// paintable by a state rule — a hover that changes the background changes
/// `--unibox-shape-fill`, exactly as it changes `background-color` on a
/// rectangle.
///
/// The layer sits behind the content (`z-index: -1`) and takes no pointer events,
/// so a shaped box behaves like a painted one: the children are what a pointer
/// finds.
class JasprShape extends StatelessComponent {
  /// Creates the paint layer of [shape].
  const JasprShape({required this.shape, required this.clip, super.key});

  /// The outline to paint.
  final core.BoxShape shape;

  /// Whether the box clips its content to the outline, which needs the definition.
  final bool clip;

  @override
  Component build(BuildContext context) {
    final String? svgClass = _classOf(context, 'shape', _svgStyles);
    final String? pathClass = _classOf(context, 'shape-path', _pathStyles);

    return svg(
      <Component>[
        if (clip) _clipDefinition(),
        Component.element(
          tag: 'path',
          attributes: <String, String>{
            'd': pathDataOf(shape),
            'fill-rule': shape.fillRule == core.BoxFillRule.evenOdd
                ? 'evenodd'
                : 'nonzero',
          },
          classes: pathClass,
          styles: pathClass == null ? _pathStyles : null,
        ),
      ],
      viewBox:
          '0 0 ${_number(shape.viewBoxWidth)} ${_number(shape.viewBoxHeight)}',
      attributes: <String, String>{'preserveAspectRatio': 'none'},
      classes: svgClass,
      styles: svgClass == null ? _svgStyles : null,
    );
  }

  /// The `clipPath` the box's `clip-path` points at.
  Component _clipDefinition() => Component.element(
    tag: 'defs',
    children: <Component>[
      Component.element(
        tag: 'clipPath',
        attributes: <String, String>{
          'id': clipIdOf(shape),
          'clipPathUnits': 'objectBoundingBox',
        },
        children: <Component>[
          Component.element(
            tag: 'path',
            attributes: <String, String>{'d': clipPathDataOf(shape)},
          ),
        ],
      ),
    ],
  );

  /// The class of [styles] in the rendering in progress, or `null` without a sheet.
  String? _classOf(BuildContext context, String kind, Styles styles) =>
      UniboxStylesheetScope.of(context)?.classFor(
        kind,
        declarationsOf(styles),
        (String name) => <StyleRule>[
          StyleRule(selector: Selector.className(name), styles: styles),
        ],
      );
}

/// The layer over the box: absolute, behind the content, never a hit target.
///
/// `overflow: visible` is what lets a stroke centred on the outline hang over the
/// box's edge, the way Flutter paints it outside the canvas bounds.
final Styles _svgStyles = Styles(
  raw: <String, String>{
    'position': 'absolute',
    'inset': '0',
    'width': '100%',
    'height': '100%',
    'overflow': 'visible',
    'z-index': '-1',
    'pointer-events': 'none',
  },
);

/// The path reads the three properties the box's own rule sets.
final Styles _pathStyles = Styles(
  raw: <String, String>{
    'fill': 'var(--unibox-shape-fill, none)',
    'stroke': 'var(--unibox-shape-stroke, none)',
    'stroke-width': 'var(--unibox-shape-stroke-width, 0)',
  },
);

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

/// [value] as CSS writes it: a whole number keeps no decimal point.
String _number(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e9) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
