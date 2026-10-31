/// The glyphs the example draws, from boxes.
///
/// An icon font is a host asset — it has to be subsetted, declared in `fonts:` or
/// with an `@font-face`, and shipped by both hosts — so the example draws the few
/// small pictures it needs instead. Each is boxes, radii and transforms — or, for a
/// logo, a path in a view box — which means both renderers draw the same shape
/// without an asset and without a codepoint map.
///
/// A check is the exception, and the reason it is not here: `unibox_material` already
/// draws one for the check of a chosen chip and segment (`MaterialCheckMark`), so the
/// example wears that rather than keeping a second tick that could drift from it.
///
/// `MaterialIcon` is the way in when an application *does* ship a font; this file is
/// the way in when it does not.
library;

import 'package:unibox_core/unibox_core.dart';

/// A cross: two bars at right angles, the close of an input chip.
UINode glyphClose(BoxColor color, {double size = 10}) {
  final double stroke = size / 5;

  return StackNode(
    width: size,
    height: size,
    children: <UINode>[
      _centred(
        Box(
          width: size,
          height: stroke,
          borderRadius: stroke / 2,
          backgroundColor: color,
          transform: const BoxTransform(rotation: 45),
        ),
      ),
      _centred(
        Box(
          width: size,
          height: stroke,
          borderRadius: stroke / 2,
          backgroundColor: color,
          transform: const BoxTransform(rotation: -45),
        ),
      ),
    ],
  );
}

/// The GitHub mark: the octocat silhouette, as one path in a 24 by 24 view box.
///
/// The one glyph here that is a shape rather than a pile of boxes, because a logo is a
/// silhouette: the outline is the picture, and the four curves of a tail do not survive
/// being spelled as rectangles. `BoxShape` is what the model has for exactly this — the
/// commands were taken from the published mark, so the value draws the outline GitHub
/// draws instead of an approximation of it.
UINode glyphGitHub(BoxColor color, {double size = 16}) =>
    Box(width: size, height: size, shape: _githubMark, backgroundColor: color);

/// A grid: four squares, the picture of a tiled view.
UINode glyphGrid(BoxColor color, {double size = 12}) {
  final double cell = (size - 2) / 2;

  return StackNode(
    width: size,
    height: size,
    children: <UINode>[
      for (final (double x, double y) in <(double, double)>[
        (-1, -1),
        (1, -1),
        (-1, 1),
        (1, 1),
      ])
        _centred(
          Box(
            width: cell,
            height: cell,
            borderRadius: 1,
            backgroundColor: color,
            transform: BoxTransform(
              offsetX: x * (cell / 2 + 1),
              offsetY: y * (cell / 2 + 1),
            ),
          ),
        ),
    ],
  );
}

/// A pin: a round head and a short stem, the picture of a place.
UINode glyphPin(BoxColor color, {double size = 12}) {
  return StackNode(
    width: size,
    height: size,
    children: <UINode>[
      _centred(
        Box(
          width: size * 0.75,
          height: size * 0.75,
          borderRadius: size,
          backgroundColor: color,
          transform: BoxTransform(offsetY: -size * 0.1),
        ),
      ),
      _centred(
        Box(
          width: size / 6,
          height: size * 0.3,
          borderRadius: 1,
          backgroundColor: color,
          transform: BoxTransform(offsetY: size * 0.35),
        ),
      ),
    ],
  );
}

/// A list: three bars, the picture of a column of rows.
UINode glyphList(BoxColor color, {double size = 12}) {
  return Box(
    width: size,
    direction: Axis.vertical,
    gap: 2,
    children: <UINode>[
      for (int i = 0; i < 3; i++)
        Box(width: size, height: 2, borderRadius: 1, backgroundColor: color),
    ],
  );
}

/// The GitHub mark, drawn in the view box it was published in.
///
/// The path is the mark's own, one cubic after another: it ends where it began, so it is
/// filled as a closed outline without a `close`, which is what the published one states.
const BoxShape _githubMark = BoxShape(
  viewBoxWidth: 24,
  viewBoxHeight: 24,
  commands: <BoxPathCommand>[
    BoxPathMoveTo(12, 0.297),
    BoxPathCubicTo(5.37, 0.297, 0, 5.67, 0, 12.297),
    BoxPathCubicTo(0, 17.6, 3.438, 22.097, 8.205, 23.682),
    BoxPathCubicTo(8.805, 23.795, 9.025, 23.424, 9.025, 23.105),
    BoxPathCubicTo(9.025, 22.82, 9.015, 22.065, 9.01, 21.065),
    BoxPathCubicTo(5.672, 21.789, 4.968, 19.455, 4.968, 19.455),
    BoxPathCubicTo(4.422, 18.07, 3.633, 17.7, 3.633, 17.7),
    BoxPathCubicTo(2.546, 16.956, 3.717, 16.971, 3.717, 16.971),
    BoxPathCubicTo(4.922, 17.055, 5.555, 18.207, 5.555, 18.207),
    BoxPathCubicTo(6.625, 20.042, 8.364, 19.512, 9.05, 19.205),
    BoxPathCubicTo(9.158, 18.429, 9.467, 17.9, 9.81, 17.6),
    BoxPathCubicTo(7.145, 17.3, 4.344, 16.268, 4.344, 11.67),
    BoxPathCubicTo(4.344, 10.36, 4.809, 9.29, 5.579, 8.45),
    BoxPathCubicTo(5.444, 8.147, 5.039, 6.927, 5.684, 5.274),
    BoxPathCubicTo(5.684, 5.274, 6.689, 4.952, 8.984, 6.504),
    BoxPathCubicTo(9.944, 6.237, 10.964, 6.105, 11.984, 6.099),
    BoxPathCubicTo(13.004, 6.105, 14.024, 6.237, 14.989, 6.504),
    BoxPathCubicTo(17.269, 4.952, 18.274, 5.274, 18.274, 5.274),
    BoxPathCubicTo(18.919, 6.927, 18.514, 8.147, 18.394, 8.45),
    BoxPathCubicTo(19.159, 9.29, 19.624, 10.36, 19.624, 11.67),
    BoxPathCubicTo(19.624, 16.28, 16.819, 17.295, 14.149, 17.59),
    BoxPathCubicTo(14.569, 17.95, 14.959, 18.686, 14.959, 19.81),
    BoxPathCubicTo(14.959, 21.416, 14.944, 22.706, 14.944, 23.096),
    BoxPathCubicTo(14.944, 23.411, 15.154, 23.786, 15.769, 23.666),
    BoxPathCubicTo(20.565, 22.092, 24, 17.592, 24, 12.297),
    BoxPathCubicTo(24, 5.67, 18.627, 0.297, 12, 0.297),
  ],
);

/// [child] in the middle of the stack that holds it.
UINode _centred(UINode child) =>
    PositionedNode(alignment: BoxAlignment.center, child: child);
