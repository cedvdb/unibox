import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_jaspr/unibox_jaspr.dart';

import 'support/harness.dart';

/// A triangle: the simplest outline that is not a rectangle.
const core.BoxShape triangle = core.BoxShape(
  viewBoxWidth: 100,
  viewBoxHeight: 100,
  commands: <core.BoxPathCommand>[
    core.BoxPathMoveTo(50, 0),
    core.BoxPathLineTo(100, 100),
    core.BoxPathLineTo(0, 100),
    core.BoxPathClose(),
  ],
);

/// The path in the markup, and the properties the box's rule sets for it.
void main() {
  group('pathDataOf', () {
    test('writes the commands as one d attribute', () {
      expect(
        pathDataOf(triangle),
        'M50 0 L100 100 L0 100 Z',
        reason: 'a reader should be able to compare the path with the commands',
      );
    });

    test('writes an arc with its two radii and its two flags', () {
      expect(
        pathDataOf(core.BoxShape.circle),
        'M50 0 A50 50 0 0 1 50 100 A50 50 0 0 1 50 0',
      );
    });

    test('writes the same outline in bounding box units for a clip', () {
      expect(
        clipPathDataOf(triangle),
        'M0.5 0 L1 1 L0 1 Z',
        reason: 'a clip in objectBoundingBox units scales with the element',
      );
    });

    test('names the clip after its outline, so two boxes share it', () {
      expect(clipIdOf(triangle), startsWith('unibox-shape-'));
      expect(clipIdOf(triangle), clipIdOf(triangle));
      expect(clipIdOf(triangle), isNot(clipIdOf(core.BoxShape.circle)));
    });
  });

  group('a shaped box', () {
    testComponents('paints an svg layer, and no rectangle behind it', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          shape: triangle,
          backgroundColor: core.BoxColor.rgb(0x2D, 0x6C, 0xF3),
          children: <core.UINode>[core.TextNode('Hi')],
        ),
      );

      expect(find.tag('svg'), findsOneComponent);
      expect(find.tag('path'), findsOneComponent);
      expect(find.text('Hi'), findsOneComponent);

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(
        styles['background-color'],
        isNull,
        reason: 'the fill belongs to the path, not to the element',
      );
      expect(styles['--unibox-shape-fill'], isNotNull);
      expect(styles['position'], 'relative');
      expect(
        styles['clip-path'],
        isNull,
        reason: 'a box clips to its shape only when it says overflow: hidden',
      );
    });

    testComponents('draws the outline and the svg view box from the shape', (
      tester,
    ) async {
      pumpNode(tester, const core.Box(width: 40, height: 40, shape: triangle));

      final Map<String, String> svg = attributesOf(find.tag('svg'));
      final Map<String, String> path = attributesOf(find.tag('path'));

      expect(svg['viewBox'], '0 0 100 100');
      expect(svg['preserveAspectRatio'], 'none');
      expect(path['d'], 'M50 0 L100 100 L0 100 Z');
      expect(path['fill-rule'], 'nonzero');
      expect(
        stylesOf(find.tag('path'))['fill'],
        contains('--unibox-shape-fill'),
      );
    });

    testComponents('punches the hole of an even-odd shape', (tester) async {
      const core.BoxShape ring = core.BoxShape(
        viewBoxWidth: 100,
        viewBoxHeight: 100,
        fillRule: core.BoxFillRule.evenOdd,
        commands: <core.BoxPathCommand>[
          core.BoxPathMoveTo(50, 0),
          core.BoxPathArcTo(50, 100, radiusX: 50, radiusY: 50),
          core.BoxPathArcTo(50, 0, radiusX: 50, radiusY: 50),
          core.BoxPathMoveTo(50, 25),
          core.BoxPathArcTo(50, 75, radiusX: 25, radiusY: 25),
          core.BoxPathArcTo(50, 25, radiusX: 25, radiusY: 25),
        ],
      );

      pumpNode(tester, const core.Box(width: 40, height: 40, shape: ring));

      expect(attributesOf(find.tag('path'))['fill-rule'], 'evenodd');
    });

    testComponents('clips its content to the outline when asked', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          shape: triangle,
          overflow: core.Overflow.hidden,
          children: <core.UINode>[core.TextNode('Hi')],
        ),
      );

      final String expected = 'url(#${clipIdOf(triangle)})';

      expect(stylesOf(find.tag('div'))['clip-path'], expected);
      expect(
        find.tag('clipPath'),
        findsOneComponent,
        reason: 'the definition the box points at',
      );
      expect(
        attributesOf(find.tag('clipPath'))['clipPathUnits'],
        'objectBoundingBox',
      );
      expect(attributesOf(find.tag('clipPath'))['id'], clipIdOf(triangle));
    });

    testComponents('draws a stroke along the outline, not a rectangle border', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          shape: triangle,
          backgroundColor: core.BoxColor.white,
          border: core.BoxBorder(
            width: 2,
            color: core.BoxColor.rgb(0x2D, 0x6C, 0xF3),
          ),
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['border'], isNull);
      expect(styles['--unibox-shape-stroke'], isNotNull);
      expect(styles['--unibox-shape-stroke-width'], '2px');
    });
  });
}
