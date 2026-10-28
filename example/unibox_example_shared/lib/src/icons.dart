/// The glyphs the example draws, from boxes.
///
/// An icon font is a host asset — it has to be subsetted, declared in `fonts:` or
/// with an `@font-face`, and shipped by both hosts — so the example draws the few
/// small pictures it needs instead. Each is boxes, radii and transforms, which means
/// both renderers draw the same shape without an asset and without a codepoint map.
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

/// [child] in the middle of the stack that holds it.
UINode _centred(UINode child) =>
    PositionedNode(alignment: BoxAlignment.center, child: child);
