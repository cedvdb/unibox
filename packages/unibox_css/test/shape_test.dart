import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

/// A shape is a path in a view box, and the web draws it as one.
void main() {
  // The hexagon badge from `BoxShape`'s own documentation.
  const core.BoxShape hexagon = core.BoxShape(
    viewBoxWidth: 100,
    viewBoxHeight: 100,
    commands: <core.BoxPathCommand>[
      core.BoxPathMoveTo(50, 0),
      core.BoxPathLineTo(93, 25),
      core.BoxPathLineTo(93, 75),
      core.BoxPathLineTo(50, 100),
      core.BoxPathLineTo(7, 75),
      core.BoxPathLineTo(7, 25),
      core.BoxPathClose(),
    ],
  );

  group('a shape', () {
    test('is a path in the units it was authored in', () {
      // A reader can compare the markup with the model by eye.
      expect(
        cssShapePath(hexagon),
        'M50 0 L93 25 L93 75 L50 100 L7 75 L7 25 Z',
      );
    });

    test('is written in bounding box units for a clip', () {
      // `objectBoundingBox` is what makes one clip fit whatever element it is applied to; a
      // `clip-path: path()` would be in pixels and wrong at the next size.
      expect(
        cssShapeClipPath(hexagon),
        'M0.5 0 L0.93 0.25 L0.93 0.75 L0.5 1 L0.07 0.75 L0.07 0.25 Z',
      );
    });

    test('is named after its outline, so one shape is one definition', () {
      expect(cssShapeClipId(hexagon), startsWith('unibox-shape-'));
      expect(cssShapeClipId(hexagon), cssShapeClipId(hexagon));
    });

    test('names two outlines apart', () {
      const core.BoxShape triangle = core.BoxShape(
        viewBoxWidth: 10,
        viewBoxHeight: 10,
        commands: <core.BoxPathCommand>[
          core.BoxPathMoveTo(0, 0),
          core.BoxPathLineTo(10, 0),
          core.BoxPathLineTo(5, 10),
          core.BoxPathClose(),
        ],
      );

      expect(cssShapeClipId(hexagon), isNot(cssShapeClipId(triangle)));
    });

    test('follows the other commands SVG has', () {
      const core.BoxShape curves = core.BoxShape(
        viewBoxWidth: 10,
        viewBoxHeight: 10,
        commands: <core.BoxPathCommand>[
          core.BoxPathMoveTo(0, 0),
          core.BoxPathCubicTo(1, 2, 3, 4, 5, 6),
          core.BoxPathQuadraticTo(7, 8, 9, 10),
          core.BoxPathArcTo(1, 1, radiusX: 2, radiusY: 3),
          core.BoxPathClose(),
        ],
      );

      expect(
        cssShapePath(curves),
        'M0 0 C1 2 3 4 5 6 Q7 8 9 10 A2 3 0 0 1 1 1 Z',
      );
    });
  });

  group('a shaped box', () {
    test('sends its fill and stroke to the layer, not to the element', () {
      // The paint belongs to the path in the `<svg>`, so the colours arrive as custom
      // properties — which is what lets a state rule reach them.
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(
          shape: hexagon,
          backgroundColor: core.BoxColor(0xFF112233),
          border: core.BoxBorder(width: 2, color: core.BoxColor.white),
        ),
      );

      expect(declarations['--unibox-shape-fill'], '#112233');
      expect(declarations['--unibox-shape-stroke'], '#ffffff');
      expect(declarations['--unibox-shape-stroke-width'], '2px');
      // And a rectangle's paint is gone: one background, on the path.
      expect(declarations.has('background-color'), isFalse);
      expect(declarations.has('border'), isFalse);
      expect(declarations.has('border-radius'), isFalse);
    });

    test('carries the cap of an arc to the layer', () {
      // An arc is stroked, and its two ends are the ends of the stroke: the cap is what makes
      // Material's rounded ends reach the path at all.
      final CssDeclarations capped = boxDeclarations(
        const core.BoxStyle(
          shape: core.BoxShape(
            viewBoxWidth: 10,
            viewBoxHeight: 10,
            commands: <core.BoxPathCommand>[
              core.BoxPathMoveTo(5, 0),
              core.BoxPathArcTo(5, 10, radiusX: 5, radiusY: 5),
            ],
          ),
          border: core.BoxBorder(
            width: 2,
            color: core.BoxColor.white,
            cap: core.BoxStrokeCap.round,
          ),
        ),
      );
      final CssDeclarations square = boxDeclarations(
        const core.BoxStyle(
          border: core.BoxBorder(
            width: 2,
            color: core.BoxColor.white,
            cap: core.BoxStrokeCap.square,
          ),
        ),
      );

      expect(capped['--unibox-shape-stroke-cap'], 'round');
      // A rectangle has no ends, so no cap is written for it.
      expect(square.has('--unibox-shape-stroke-cap'), isFalse);
    });

    test('keeps the layer inside itself', () {
      // An absolutely positioned layer with `z-index: -1` would otherwise fall behind an
      // ancestor's background.
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(shape: hexagon),
      );

      expect(declarations['position'], 'relative');
      expect(declarations['isolation'], 'isolate');
      expect(declarations['--unibox-shape-fill'], 'none');
    });

    test('clips its content to the outline only when it says to', () {
      final CssDeclarations open = boxDeclarations(
        const core.BoxStyle(shape: hexagon),
      );
      final CssDeclarations clipped = boxDeclarations(
        const core.BoxStyle(shape: hexagon, overflow: core.Overflow.hidden),
      );

      expect(open.has('clip-path'), isFalse);
      expect(clipped['clip-path'], 'url(#${cssShapeClipId(hexagon)})');
    });
  });
}
