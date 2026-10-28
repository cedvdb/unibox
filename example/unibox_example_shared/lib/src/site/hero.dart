import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';

import 'section.dart';

/// A frame of the comparison: the node that draws [src], which the host supplies.
///
/// A frame is an `EmbedNode` — an `<iframe>` on the web — which is the one thing this
/// tree cannot describe, so it arrives as a builder instead of as an import.
typedef ShowcaseFrame = UINode Function({
  required String src,
  required String title,
});

/// The first band: what the library is, what it buys, and the claim drawn twice.
///
/// The claim and its evidence share one band because, split in two, they said the same
/// thing twice: the claim ended in a picture of two cards captioned *Jaspr* and
/// *Flutter*, and the band under it drew those same two cards for real, under the same
/// two captions. A reader now meets the claim and the rendering that settles it in one
/// scroll, and each of the two names is on the page once.
///
/// The copy above the frames is set large and the room around it is wide, because that
/// is what makes a page of plain boxes read as a modern one — scale and space, not a
/// second set of colours.
UINode buildHeroSection({required ShowcaseFrame frame}) {
  final MaterialPalette palette = ExamplePalette.material;

  return siteBand(
    background: palette.surface,
    vertical: 88,
    child: Box(
      width: double.infinity,
      gap: 52,
      children: <UINode>[_claim(palette), _comparison(palette, frame)],
    ),
  );
}

/// The claim, the two ways in, and the one line of proof under them.
UINode _claim(MaterialPalette palette) {
  return Box(
    gap: 24,
    children: <UINode>[
      Box(
        direction: Axis.horizontal,
        children: <UINode>[
          Box(
            padding: const BoxSpacing.symmetric(horizontal: 10, vertical: 4),
            borderRadius: 14,
            backgroundColor: palette.secondaryContainer,
            children: <UINode>[
              TextNode(
                'Dart · one tree · two renderers',
                style: MaterialTypography.labelMedium.copyWith(
                  color: palette.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
      TextNode(
        'Describe a screen once.',
        style: MaterialTypography.displayLarge,
        headingLevel: 1,
      ),
      Box(
        maxWidth: 560,
        children: <UINode>[
          TextNode(
            'The page a search engine reads and the screen in your app, from one '
            'Dart tree — so there is no second design to keep in step.',
            style: MaterialTypography.titleMedium.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ],
  );
}

/// The claim settled: the same node tree in two frames, side by side.
///
/// Two frames rather than two links, because the point is the comparison: resize the
/// window and both answer the same breakpoint, on the same node tree. The heading and
/// the captions are boxes and texts like everything else here; the frames are the one
/// thing the model cannot describe, so they arrive through [ShowcaseFrame].
UINode _comparison(MaterialPalette palette, ShowcaseFrame frame) {
  return Box(
    width: double.infinity,
    gap: 24,
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
      // The one line of small print the claim used to carry, where it is read last:
      // under the evidence rather than between the claim and it. There is no link
      // here either — the example is shown in the frames and nowhere else.
      TextNode(
        'Pure Dart · the core has no dependencies · both renderers measured '
        'against one table',
        style: MaterialTypography.labelSmall.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// One half of the comparison: a caption and the frame.
///
/// There is no link beside the caption: the frame is the only way the example is
/// reached from this page, and the page it draws is not a destination of its own.
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
      TextNode(
        title,
        style: MaterialTypography.labelLarge.copyWith(
          color: palette.onSurfaceVariant,
        ),
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
