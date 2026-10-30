import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../seed_picker.dart';
import '../theme.dart';

import 'gallery.dart';
import 'hero.dart';
import 'indexable.dart';
import 'section.dart';
import 'vocabulary.dart';

/// The repository, which the header and the footer point at.
const String repositoryUrl = 'https://github.com/cedvdb/unibox';

/// The site as one page: the claim and the same screen drawn twice, the reason that
/// matters to a search engine, then the values and nodes the whole thing is built from.
///
/// It used to be three documents with a bar between them, and one page is the honest
/// shape: a reader scrolls the claim and its evidence, and the evidence *is* the page.
/// There is also nothing left to route — a single page has no destination a click could
/// take a reader to, so a static document loses nothing it had.
///
/// The order is the argument. The hero makes the claim, gives the three reasons for it, and
/// settles them with two live renderings of one tree; the band under it answers what the
/// HTML branch is for — a page a search engine can read — and says how little of an
/// application has to change for that; the vocabulary takes those renderings apart into the
/// four nodes they never put a name to; and the catalogue closes the page with the design
/// system every band above it is drawn with. A reader who stops after the second band has
/// seen the reason to adopt this and the evidence that it works, which is the whole of what
/// this page is for.
UINode buildSitePage({
  required ShowcaseFrame frame,
  ExampleSeed seed = ExampleSeed.defaultSeed,
}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return Box(
    direction: Axis.vertical,
    width: double.infinity,
    backgroundColor: palette.surface,
    textStyle: MaterialTypography.bodyMedium.merge(
      BoxTextStyle(color: palette.onSurface),
    ),
    children: <UINode>[
      _header(palette, seed),
      // The bands are the content of the page, so the web renders a `<main>`
      // around them: a landmark is what a reader can jump to, and it says which
      // region the header and the footer are not.
      Box(
        width: double.infinity,
        semantics: const BoxSemantics(element: BoxElement.main),
        children: <UINode>[
          buildHeroSection(frame: frame, seed: seed),
          // Directly under the claim: the HTML branch of the diagram is the reason most
          // readers are here, so the band that shows what a crawler is served comes
          // before the parts the page is made of.
          buildIndexableSection(seed: seed),
          // The vocabulary follows the claim directly: the hero frames a whole tree, and
          // these are the nodes it never names — drawn once, as one card, and taken apart
          // in a list beside it.
          buildVocabularySection(seed: seed),
          // The catalogue closes the page, because the design system is what every band
          // above it is drawn with.
          buildMaterialSection(seed: seed),
        ],
      ),
      _footer(palette),
    ],
  );
}

/// The band above the page: the name of the site and the one place to go from it.
///
/// It is a `header` landmark and its link is a `LinkNode`, so the page keeps its
/// outline and a reader without JavaScript can still follow it. The hairline is a
/// shadow with no blur, because a `BoxBorder` draws on all four sides.
UINode _header(MaterialPalette palette, ExampleSeed seed) {
  return Box(
    width: double.infinity,
    backgroundColor: palette.surface,
    semantics: const BoxSemantics(element: BoxElement.header),
    shadows: <BoxShadow>[
      BoxShadow(color: palette.outlineVariant, offsetY: 1, blurRadius: 0),
    ],
    children: <UINode>[
      siteBand(
        vertical: 14,
        child: Box(
          width: double.infinity,
          direction: Axis.horizontal,
          mainAlign: MainAlign.spaceBetween,
          crossAlign: CrossAlign.center,
          children: <UINode>[
            Box(
              direction: Axis.horizontal,
              crossAlign: CrossAlign.center,
              gap: 20,
              children: <UINode>[
                LinkNode(
                  './',
                  child: TextNode(
                    'Unibox',
                    style: MaterialTypography.titleMedium,
                  ),
                ),
                // The palette the page is drawn with, beside the name it belongs to:
                // a reader changes the whole page, not the catalogue at the bottom of it.
                seedPicker(current: seed),
              ],
            ),
            Box(
              direction: Axis.horizontal,
              crossAlign: CrossAlign.center,
              gap: 8,
              children: <UINode>[
                // The source is the one thing a reader of this page may want next: the
                // example is already a call to action in the hero, and the two frames
                // that show it are one scroll away.
                _siteLink('GitHub', repositoryUrl, palette, newTab: true),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

/// One link of the header or the footer: a label, tinted while the pointer is on it.
UINode _siteLink(
  String label,
  String url,
  MaterialPalette palette, {
  bool newTab = false,
}) {
  return LinkNode(
    url,
    newTab: newTab,
    child: Box(
      padding: const BoxSpacing.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 8,
      transition: MaterialInkWell.defaultTransition,
      hoverStyle: BoxStyle(backgroundColor: palette.surfaceContainer),
      children: <UINode>[
        TextNode(
          label,
          style: MaterialTypography.labelLarge.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

/// The band under the page: what it is, and where to read the rest.
UINode _footer(MaterialPalette palette) {
  return Box(
    width: double.infinity,
    backgroundColor: palette.surface,
    semantics: const BoxSemantics(element: BoxElement.footer),
    shadows: <BoxShadow>[
      BoxShadow(color: palette.outlineVariant, offsetY: -1, blurRadius: 0),
    ],
    children: <UINode>[
      siteBand(
        vertical: 28,
        child: Box(
          width: double.infinity,
          gap: 8,
          children: <UINode>[
            TextNode(
              'Unibox — Flutter UI, searchable HTML. This page is drawn with the '
              'library it documents.',
              style: MaterialTypography.labelMedium.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
            Box(
              direction: Axis.horizontal,
              gap: 8,
              children: <UINode>[
                _siteLink('Source', repositoryUrl, palette, newTab: true),
                _siteLink(
                  'README',
                  '$repositoryUrl#readme',
                  palette,
                  newTab: true,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
