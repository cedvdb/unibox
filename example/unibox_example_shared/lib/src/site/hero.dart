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

/// The first band: the claim, and the diagram that answers it.
///
/// A one-line claim and one chip that branches into the two things the tree becomes, each
/// branch carrying the live rendering it produces. That is the whole pitch in one screen:
/// a stranger reads *one tree*, sees it split into HTML and Flutter, and can type into
/// either half of the diagram to check that it is real.
///
/// The copy above the diagram is set large and the room around it is wide, because that
/// is what makes a page of plain boxes read as a modern one — scale and space, not a
/// second set of colours.
UINode buildHeroSection({
  required ShowcaseFrame frame,
  ExampleSeed seed = ExampleSeed.defaultSeed,
}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return siteBand(
    background: palette.surface,
    vertical: 80,
    child: Box(
      width: double.infinity,
      gap: 48,
      children: <UINode>[_claim(palette), _diagram(palette, frame, seed)],
    ),
  );
}

/// The measure the band's copy is set to.
///
/// One measure, and both text blocks of the claim end on it: the headline at 57 pixels
/// breaks where a line is worth reading, and the paragraph under it stops on the same
/// edge rather than running to the window. The diagram below is measured by the band
/// instead, because it is a picture of the whole, not a paragraph of the claim.
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
        'An immutable Dart tree. Flutter draws it as widgets; the web reads it '
        'as HTML — real text, real links, real headings, so the page a visitor '
        'lands on is the page a search engine ranks.',
        style: MaterialTypography.titleMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// The diagram the whole page turns on: one tree, and the two things it becomes.
///
/// It is the answer to *what is this*, drawn rather than described — a single chip where
/// the tree is, an arrow down each branch, and the live rendering each branch produces
/// directly under its own name. The frames are not a screenshot, so the diagram is not a
/// picture of an architecture: it *is* the architecture, and a reader can type into
/// either half of it.
///
/// The two branch names are the page's `h2`s, because they are what the page is about:
/// a crawler that reads *HTML and CSS* and *Flutter* as two sections of one document has
/// understood the library better than one that reads a slogan.
UINode _diagram(
  MaterialPalette palette,
  ShowcaseFrame frame,
  ExampleSeed seed,
) {
  return Box(
    width: double.infinity,
    gap: 16,
    children: <UINode>[
      // The root, centred over both branches.
      Box(
        width: double.infinity,
        direction: Axis.horizontal,
        mainAlign: MainAlign.center,
        children: <UINode>[_treeChip(palette)],
      ),
      GridNode(
        minItemWidth: 380,
        maxColumns: 2,
        gap: 20,
        children: <UINode>[
          _branch(
            palette,
            label: 'HTML and CSS',
            note: 'a document a crawler reads and a reader can act on',
            flowKey: 'hero-flow-html',
            src: 'web/listings/?seed=${seed.name}',
            frame: frame,
          ),
          _branch(
            palette,
            label: 'Flutter',
            note: 'the same tree as widgets, in the app',
            flowKey: 'hero-flow-flutter',
            src: 'flutter/listings/?seed=${seed.name}',
            frame: frame,
          ),
        ],
      ),
      // Read after the evidence: what the two frames show, and what the page is made of.
      // There is no link here — the example is shown in the frames and nowhere else.
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
            'Pure Dart · the core has no dependencies · every rendering measured '
            'against one table of expected appearance',
            style: MaterialTypography.labelSmall.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ],
  );
}

/// The tree, in one chip: where both branches start.
UINode _treeChip(MaterialPalette palette) {
  return Box(
    padding: const BoxSpacing.symmetric(horizontal: 20, vertical: 12),
    borderRadius: 30,
    backgroundColor: palette.surface,
    border: BoxBorder(color: palette.outlineVariant),
    // A soft drop shadow under the chip: the one place on the page where the tree is
    // drawn *above* the two things it becomes, rather than beside them.
    shadow: BoxShadow(
      color: palette.outlineVariant,
      offsetY: 4,
      blurRadius: 12,
    ),
    children: <UINode>[
      TextNode(
        'Unibox',
        style: MaterialTypography.titleMedium.copyWith(
          color: palette.onSurface,
        ),
      ),
    ],
  );
}

/// One branch: the arrow, the name of what the tree becomes, and that thing itself.
UINode _branch(
  MaterialPalette palette, {
  required String label,
  required String note,
  required String src,
  required String flowKey,
  required ShowcaseFrame frame,
}) {
  return Box(
    width: double.infinity,
    gap: 8,
    children: <UINode>[
      // Centred over its column: left-aligned, the arrows read as ornaments in the margin
      // rather than as the two branches of the chip above them.
      Box(
        width: double.infinity,
        direction: Axis.horizontal,
        mainAlign: MainAlign.center,
        children: <UINode>[
          // Keyed, because the site's stylesheet is what moves it: the arrow is the one thing
          // on the page whose `why` is motion, and a key is the hook a host already has for
          // naming an element without adding a class the model does not carry.
          TextNode(
            '↓',
            key: flowKey,
            style: MaterialTypography.titleLarge.copyWith(
              color: palette.primary,
            ),
          ),
        ],
      ),
      TextNode(label, style: MaterialTypography.titleLarge, headingLevel: 2),
      TextNode(
        note,
        style: MaterialTypography.bodySmall.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
      // A frame needs a height of its own: it is a window, not a paragraph, and an
      // iframe with no height is a sliver.
      Box(
        width: double.infinity,
        height: 540,
        margin: const BoxSpacing.only(top: 6),
        borderRadius: 18,
        overflow: Overflow.hidden,
        border: BoxBorder(color: palette.outlineVariant),
        backgroundColor: palette.surface,
        children: <UINode>[frame(src: src, title: label)],
      ),
    ],
  );
}
