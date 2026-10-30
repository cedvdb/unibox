import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The width a band of the page is measured to.
///
/// A measure, not the window: a paragraph, or a row of four buttons, stretched
/// across a 27 inch screen is unreadable however well it renders. Every band
/// centres a box of this width, so the page fills a phone and stays a column on a
/// desk.
const double siteMeasure = 1080;

/// A band of the page: a full width background, and its content measured to
/// [siteMeasure] and centred.
///
/// The page is a column of bands — the claim, the markup a crawler is served, the
/// vocabulary, the catalogue — so a band states its own background and its own vertical
/// room, and nothing about where it sits. On the web a band is a `section`: the page is
/// a document, and sectioning content is how a crawler and a screen reader learn where
/// one part of it ends and the next begins. A band that sits inside a landmark the tree
/// already named — the header, the footer — passes [BoxElement.div], because a `section`
/// in an element with no heading of its own only adds a box.
UINode siteBand({
  required UINode child,
  BoxColor? background,
  double vertical = 72,
  BoxElement element = BoxElement.section,
}) {
  return Box(
    width: double.infinity,
    backgroundColor: background,
    semantics: BoxSemantics(element: element),
    children: <UINode>[
      Box(
        width: double.infinity,
        direction: Axis.horizontal,
        mainAlign: MainAlign.center,
        padding: BoxSpacing.symmetric(horizontal: 32, vertical: vertical),
        children: <UINode>[
          Box(
            width: double.infinity,
            maxWidth: siteMeasure,
            children: <UINode>[child],
          ),
        ],
      ),
    ],
  );
}

/// The heading of a band: the line that names it, and the one that says what it
/// shows.
///
/// It is an `h2`, because the page has one `h1` — the claim in the hero — and the
/// outline a crawler and a screen reader build the page from is the reason a band
/// is a section rather than a pile of boxes.
UINode siteHeading(
  MaterialPalette palette, {
  required String title,
  required String lead,
}) {
  return Box(
    width: double.infinity,
    maxWidth: 760,
    gap: 12,
    children: <UINode>[
      TextNode(
        title,
        style: MaterialTypography.headlineMedium,
        headingLevel: 2,
      ),
      TextNode(
        lead,
        style: MaterialTypography.bodyLarge.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}
