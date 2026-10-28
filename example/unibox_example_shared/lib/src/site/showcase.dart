import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';

import 'section.dart';

/// A frame of the showcase: the node that draws [src], which the host supplies.
///
/// A frame is an `EmbedNode` — an `<iframe>` on the web — which is the one thing
/// this tree cannot describe, so it arrives as a builder instead of as an import.
typedef ShowcaseFrame = UINode Function({
  required String src,
  required String title,
});

/// The second band: the same node tree, drawn twice, side by side.
///
/// Two frames rather than two links, because the point is the comparison: resize the
/// window and both answer the same breakpoint, on the same node tree. The band is a
/// node tree as well — the heading and the two captions are boxes and texts, and the
/// frames are the one thing the model cannot describe, so they arrive through
/// [ShowcaseFrame].
///
/// It comes before the catalogue on purpose: the claim is that the two renderings
/// agree, and a reader should meet the evidence before the design system the
/// evidence is drawn with.
UINode buildShowcaseSection({required ShowcaseFrame frame}) {
  final MaterialPalette palette = ExamplePalette.material;

  return siteBand(
    background: palette.surfaceContainerLow,
    child: Box(
      width: double.infinity,
      gap: 32,
      children: <UINode>[
        siteHeading(
          title: 'The same tree, drawn twice',
          lead:
              'Left, the page Jaspr serves; right, the same node tree built by '
              'Flutter. Drag a frame narrower and both answer the same breakpoint.',
        ),
        GridNode(
          minItemWidth: 380,
          maxColumns: 2,
          gap: 20,
          children: <UINode>[
            _panel(
              title: 'Jaspr — HTML and CSS',
              src: 'web/listings/',
              palette: palette,
              frame: frame,
            ),
            _panel(
              title: 'Flutter — the same tree',
              src: 'flutter/listings/',
              palette: palette,
              frame: frame,
            ),
          ],
        ),
      ],
    ),
  );
}

/// One half of the comparison: a caption, a way to open it alone, and the frame.
UINode _panel({
  required String title,
  required String src,
  required MaterialPalette palette,
  required ShowcaseFrame frame,
}) {
  return Box(
    width: double.infinity,
    gap: 10,
    children: <UINode>[
      Box(
        direction: Axis.horizontal,
        mainAlign: MainAlign.spaceBetween,
        crossAlign: CrossAlign.center,
        width: double.infinity,
        children: <UINode>[
          TextNode(
            title,
            style: MaterialTypography.labelLarge.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
          LinkNode(
            src,
            child: Box(
              padding: const BoxSpacing.symmetric(horizontal: 8, vertical: 4),
              borderRadius: 8,
              children: <UINode>[
                TextNode(
                  'Open',
                  style: MaterialTypography.labelLarge.copyWith(
                    color: palette.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // A frame needs a height of its own: it is a window, not a paragraph, and an
      // iframe with no height is a sliver.
      Box(
        width: double.infinity,
        height: 560,
        borderRadius: 18,
        overflow: Overflow.hidden,
        border: BoxBorder(color: palette.outlineVariant),
        backgroundColor: palette.surface,
        children: <UINode>[frame(src: src, title: title)],
      ),
    ],
  );
}
