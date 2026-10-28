import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';

import 'section.dart';

/// The first band: what the library is, what it buys, and the claim drawn once.
///
/// It is a sales page, so it does one thing: say what the library is for, show the
/// claim rather than describe it, and offer the two places to look. The copy is set
/// large and the room around it is wide, because that is what makes a page of plain
/// boxes read as a modern one — scale and space, not a second set of colours.
UINode buildHeroSection() {
  final MaterialPalette palette = ExamplePalette.material;

  return siteBand(
    background: palette.surface,
    vertical: 88,
    child: GridNode(
      minItemWidth: 400,
      maxColumns: 2,
      gap: 56,
      children: <UINode>[_sell(palette), _renderingPair(palette)],
    ),
  );
}

/// The claim, the two ways in, and the one line of proof under them.
UINode _sell(MaterialPalette palette) {
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
      // A grid rather than a row: two buttons of this length do not fit a phone
      // side by side, and a grid stacks them instead of overflowing.
      GridNode(
        minItemWidth: 180,
        maxColumns: 2,
        gap: 12,
        children: <UINode>[
          _natural(
            LinkNode(
              'web/listings/',
              child: MaterialButton.filled(
                label: const TextNode('Open the example'),
                onTap: () {},
              ),
            ),
          ),
          _natural(
            LinkNode(
              'flutter/listings/',
              child: MaterialButton.outlined(
                label: const TextNode('The Flutter build'),
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
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

/// The claim as a picture: one tree, and two cards drawn from it.
///
/// The two cards are the same nodes twice — the words differ only in the caption —
/// because that is the whole pitch, and a diagram that said it in more shapes would
/// be a second thing to keep in step with the first.
UINode _renderingPair(MaterialPalette palette) {
  return Box(
    backgroundColor: palette.surfaceContainerLow,
    borderRadius: 28,
    padding: const BoxSpacing.all(20),
    gap: 14,
    children: <UINode>[
      Box(
        direction: Axis.horizontal,
        mainAlign: MainAlign.spaceBetween,
        crossAlign: CrossAlign.center,
        children: <UINode>[
          TextNode('One tree', style: MaterialTypography.labelLarge),
          Box(
            padding: const BoxSpacing.symmetric(horizontal: 8, vertical: 2),
            borderRadius: 8,
            backgroundColor: palette.secondaryContainer,
            children: <UINode>[
              TextNode(
                'Dart',
                style: MaterialTypography.labelSmall.copyWith(
                  color: palette.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
      _rendering('HTML and CSS — the document', palette),
      _rendering('Flutter — the same tree', palette),
    ],
  );
}

/// One rendering of the card: a caption, a picture, and a line of listing.
UINode _rendering(String caption, MaterialPalette palette) {
  return Box(
    // The width the panel gives it, so the picture below has something definite to
    // fill: a box that hugs its content inside a column that hugs its content is a
    // percentage width with no answer on the web.
    width: double.infinity,
    backgroundColor: palette.surfaceContainerLowest,
    borderRadius: 18,
    border: BoxBorder(color: palette.outlineVariant),
    padding: const BoxSpacing.all(14),
    gap: 8,
    children: <UINode>[
      TextNode(
        caption,
        style: MaterialTypography.labelMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
      // The photo of the card, as a block: the example's cards show a real image,
      // and a hero that fetched one would be a network request before a word was
      // read.
      Box(
        width: double.infinity,
        height: 56,
        borderRadius: 12,
        backgroundColor: palette.surfaceContainerHigh,
      ),
      TextNode('Sunny flat, 62 m²', style: MaterialTypography.titleSmall),
      TextNode(
        '€1 850 a month · 2 rooms',
        style: MaterialTypography.bodySmall.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// Keeps [child] at its own size inside a grid track.
///
/// A track is as wide as its column and a box inside one fills that width, which
/// turns a pill into a banner; a row lays the control out at its natural size on
/// both targets and leaves the rest of the track empty.
UINode _natural(UINode child) => Box(
  direction: Axis.horizontal,
  crossAlign: CrossAlign.center,
  children: <UINode>[child],
);
