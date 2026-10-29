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
/// thing twice: the claim ended in a picture of two cards captioned *the web* and
/// *Flutter*, and the band under it drew those same two cards for real, under the same
/// two captions. A reader now meets the claim and the rendering that settles it in one
/// scroll, and each of the two names is on the page once.
///
/// The copy above the frames is set large and the room around it is wide, because that
/// is what makes a page of plain boxes read as a modern one — scale and space, not a
/// second set of colours.
UINode buildHeroSection({
  required ShowcaseFrame frame,
  ExampleSeed seed = ExampleSeed.defaultSeed,
}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return siteBand(
    background: palette.surface,
    vertical: 88,
    child: Box(
      width: double.infinity,
      gap: 44,
      children: <UINode>[
        _claim(palette),
        _reasons(palette),
        _comparison(palette, frame, seed),
      ],
    ),
  );
}

/// The measure the band's copy is set to.
///
/// One measure, and every text block in the band ends on it: the claim at 57 pixels
/// breaks where a line is worth reading, the paragraph under it ends where the headline
/// does, and the comparison's heading is the same column rather than a second layout.
/// Without it the band is four blocks with four right edges, which reads as two
/// sections that were stapled together.
const double _copyMeasure = 640;

/// The claim, on the one measure the rest of the band's copy shares.
UINode _claim(MaterialPalette palette) {
  return Box(
    width: double.infinity,
    maxWidth: _copyMeasure,
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
      TextNode(
        'The page a search engine reads and the screen in your app, from one '
        'Dart tree — so there is no second design to keep in step.',
        style: MaterialTypography.titleMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// Why the library exists, in three lines: the argument the frames underneath settle.
///
/// They sit in the hero rather than in a band of their own because a page that argues for
/// itself has one place to argue: a reader who scrolls past the claim meets the three
/// reasons and then the evidence, without a section that repeats the claim in three cards.
/// Each line is one reason a reader would give for adopting it, not one feature of the
/// model — a feature list is what the catalogue further down is for.
UINode _reasons(MaterialPalette palette) {
  return GridNode(
    minItemWidth: 280,
    maxColumns: 3,
    gap: 24,
    children: <UINode>[
      _reason(
        palette,
        title: 'One tree',
        line:
            'The screen is written once: Flutter draws it in the app, HTML and CSS '
            'draw it in the browser.',
      ),
      _reason(
        palette,
        title: 'Found, not crawled hollow',
        line:
            'Real text, real links, real headings. What a crawler reads is the page a '
            'reader lands on, not a canvas and a title.',
      ),
      _reason(
        palette,
        title: 'Deploy it your way',
        line:
            'Flutter can take the page over, or the page can run on its own — no engine, '
            'and a bundle you can measure in kilobytes.',
      ),
    ],
  );
}

/// One reason: a line to remember, and the sentence that earns it.
UINode _reason(
  MaterialPalette palette, {
  required String title,
  required String line,
}) {
  return Box(
    width: double.infinity,
    gap: 6,
    children: <UINode>[
      TextNode(
        title,
        style: MaterialTypography.titleSmall.copyWith(color: palette.primary),
      ),
      TextNode(
        line,
        style: MaterialTypography.bodyMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// The claim settled: the same node tree in two frames, side by side.
///
/// Two frames rather than two links, because the point is the comparison: narrow the
/// window and both answer the same breakpoint, on the same node tree. The heading and
/// the captions are boxes and texts like everything else here; the frames are the one
/// thing the model cannot describe, so they arrive through [ShowcaseFrame].
UINode _comparison(
  MaterialPalette palette,
  ShowcaseFrame frame,
  ExampleSeed seed,
) {
  return Box(
    width: double.infinity,
    gap: 20,
    children: <UINode>[
      // A label for the frames, not a second title: the band makes one claim, and this
      // says what is drawn under it. It stays an `h2` so the page keeps its outline and
      // a crawler keeps its heading — it is set small because the next heading down the
      // page is a real section.
      TextNode(
        'The same tree, drawn twice',
        style: MaterialTypography.titleMedium,
        headingLevel: 2,
      ),
      GridNode(
        minItemWidth: 380,
        maxColumns: 2,
        gap: 20,
        children: <UINode>[
          _panel(
            title: 'HTML and CSS — the document',
            src: 'web/listings/?seed=${seed.name}',
            palette: palette,
            frame: frame,
          ),
          _panel(
            title: 'Flutter — the same tree',
            src: 'flutter/listings/?seed=${seed.name}',
            palette: palette,
            frame: frame,
          ),
        ],
      ),
      // Two footnotes, read after the evidence: what the frames show, and what the page
      // is made of. There is no link here — the example is shown in the frames and
      // nowhere else.
      Box(
        gap: 6,
        children: <UINode>[
          TextNode(
            'Narrow the window: both frames answer the same breakpoint.',
            style: MaterialTypography.labelSmall.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
          TextNode(
            'Pure Dart · the core has no dependencies · both renderers measured '
            'against one table',
            style: MaterialTypography.labelSmall.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
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
