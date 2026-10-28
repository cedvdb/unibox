import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'gallery.dart';
import 'landing.dart';
import 'showcase.dart';

/// The pages the site publishes.
///
/// The paths are relative to the site root, because a project site is served from
/// a subdirectory (`/unibox/`) and an absolute `/showcase/` would leave it. A page
/// links to another one by walking up its own depth, which is why the depth is part
/// of the entry rather than a number written into each page.
enum SitePage {
  /// What the library is, and the two places to go next.
  home('Unibox', '', 0),

  /// The Material library: the type scale, the palette and the components.
  material('Material', 'material/', 1),

  /// The same node tree drawn by both renderers, side by side.
  showcase('Showcase', 'showcase/', 1);

  const SitePage(this.label, this.path, this.depth);

  /// The label of the destination in the bar.
  final String label;

  /// The path below the site root, empty for the root page.
  final String path;

  /// How many directories deep the page is served.
  final int depth;

  /// The href of this destination, from [from].
  String hrefFrom(SitePage from) {
    final String up = '../' * from.depth;
    return path.isEmpty ? (up.isEmpty ? './' : up) : '$up$path';
  }
}

/// The frame every page is drawn in: the bar and [page].
///
/// The frame is a node tree like any other page — the site is built with the
/// library it documents. [fill] gives the page the height of the window, which the
/// showcase needs for its two frames and the gallery does not.
UINode buildSiteFrame({
  required SitePage current,
  required UINode page,
  bool fill = false,
}) {
  final MaterialPalette palette = ExamplePalette.material;

  return Box(
    direction: Axis.vertical,
    width: double.infinity,
    height: fill ? double.infinity : null,
    backgroundColor: palette.surface,
    textStyle: MaterialTypography.bodyMedium.merge(
      BoxTextStyle(color: palette.onSurface),
    ),
    children: <UINode>[
      _bar(current, palette),
      if (fill)
        Box(flex: 1, width: double.infinity, children: <UINode>[page])
      else
        page,
    ],
  );
}

/// The bar above every page: the name of the site and its two destinations.
///
/// The hairline is a shadow with no blur, because a `BoxBorder` draws on all four
/// sides and a bar needs one line. The links are `LinkNode`s, so the website is
/// crawlable and works without JavaScript.
UINode _bar(SitePage current, MaterialPalette palette) {
  return Box(
    direction: Axis.horizontal,
    mainAlign: MainAlign.spaceBetween,
    crossAlign: CrossAlign.center,
    width: double.infinity,
    padding: const BoxSpacing.symmetric(horizontal: 24, vertical: 12),
    backgroundColor: palette.surface,
    semantics: const BoxSemantics(element: BoxElement.nav),
    shadow: BoxShadow(color: palette.outlineVariant, offsetY: 1, blurRadius: 0),
    children: <UINode>[
      LinkNode(
        SitePage.home.hrefFrom(current),
        child: TextNode('Unibox', style: MaterialTypography.titleMedium),
      ),
      Box(
        direction: Axis.horizontal,
        crossAlign: CrossAlign.center,
        gap: 4,
        children: <UINode>[
          for (final SitePage page in SitePage.values)
            if (page != SitePage.home)
              _navigationItem(
                page,
                current: page == current,
                from: current,
                palette: palette,
              ),
        ],
      ),
    ],
  );
}

/// One destination: a link, tinted while its page is open.
UINode _navigationItem(
  SitePage page, {
  required bool current,
  required SitePage from,
  required MaterialPalette palette,
}) {
  return LinkNode(
    page.hrefFrom(from),
    child: Box(
      padding: const BoxSpacing.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 8,
      backgroundColor: current ? palette.surfaceContainerHighest : null,
      children: <UINode>[
        TextNode(
          page.label,
          style: current
              ? MaterialTypography.labelLarge
              : MaterialTypography.bodyMedium,
        ),
      ],
    ),
  );
}

/// The page of the site [page] asks for, in the frame every page is drawn in.
///
/// The one thing this tree cannot describe is the frame of the showcase, so it
/// arrives as a [ShowcaseFrame] the host draws.
UINode buildSitePage(SitePage page, {required ShowcaseFrame frame}) {
  return buildSiteFrame(
    current: page,
    fill: page == SitePage.showcase,
    page: switch (page) {
      SitePage.home => buildLanding(),
      SitePage.material => buildMaterialGallery(),
      SitePage.showcase => buildShowcase(frame: frame),
    },
  );
}
