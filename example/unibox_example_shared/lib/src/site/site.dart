import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';

import 'gallery.dart';
import 'hero.dart';
import 'section.dart';
import 'showcase.dart';

/// The repository, which the header and the footer point at.
const String repositoryUrl = 'https://github.com/cedvdb/unibox';

/// The site as one page: the claim, the same screen drawn twice, and the values and
/// nodes the whole thing is built from.
///
/// It used to be three documents with a bar between them, and one page is the honest
/// shape: a reader scrolls the claim and its evidence, and the evidence *is* the
/// page. There is also nothing left to route — a single page has no destination a
/// click could take a reader to, so a static document loses nothing it had.
///
/// The order is the argument. The hero makes the claim and shows it as a picture; the
/// comparison proves it with two live renderings of one tree; the catalogue shows the
/// design system both sides are drawn with. A reader who stops after the comparison
/// has still seen the claim settled.
UINode buildSitePage({required ShowcaseFrame frame}) {
  final MaterialPalette palette = ExamplePalette.material;

  return Box(
    direction: Axis.vertical,
    width: double.infinity,
    backgroundColor: palette.surface,
    textStyle: MaterialTypography.bodyMedium.merge(
      BoxTextStyle(color: palette.onSurface),
    ),
    children: <UINode>[
      _header(palette),
      // The bands are the content of the page, so the web renders a `<main>`
      // around them: a landmark is what a reader can jump to, and it says which
      // region the header and the footer are not.
      Box(
        width: double.infinity,
        semantics: const BoxSemantics(element: BoxElement.main),
        children: <UINode>[
          buildHeroSection(),
          buildShowcaseSection(frame: frame),
          buildMaterialSection(),
        ],
      ),
      _footer(palette),
    ],
  );
}

/// The band above the page: the name of the site and the two places to go from it.
///
/// It is a `header` landmark and its links are `LinkNode`s, so the page keeps its
/// outline and a reader without JavaScript can still follow them. The hairline is a
/// shadow with no blur, because a `BoxBorder` draws on all four sides.
UINode _header(MaterialPalette palette) {
  return Box(
    width: double.infinity,
    backgroundColor: palette.surface,
    semantics: const BoxSemantics(element: BoxElement.header),
    shadow: BoxShadow(color: palette.outlineVariant, offsetY: 1, blurRadius: 0),
    children: <UINode>[
      siteBand(
        vertical: 14,
        child: Box(
          width: double.infinity,
          direction: Axis.horizontal,
          mainAlign: MainAlign.spaceBetween,
          crossAlign: CrossAlign.center,
          children: <UINode>[
            LinkNode(
              './',
              child: TextNode('Unibox', style: MaterialTypography.titleMedium),
            ),
            Box(
              direction: Axis.horizontal,
              crossAlign: CrossAlign.center,
              gap: 8,
              children: <UINode>[
                _siteLink('The example', 'web/listings/', palette),
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
    shadow: BoxShadow(
      color: palette.outlineVariant,
      offsetY: -1,
      blurRadius: 0,
    ),
    children: <UINode>[
      siteBand(
        vertical: 28,
        child: Box(
          width: double.infinity,
          gap: 8,
          children: <UINode>[
            TextNode(
              'Unibox — one tree, two renderers. This page is drawn with the library '
              'it documents.',
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
