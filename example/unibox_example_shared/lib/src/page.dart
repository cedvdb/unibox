import 'package:unibox_core/unibox_core.dart';

import 'theme.dart';

/// The destinations of the navigation bar.
///
/// The names live here rather than in a host, because both hosts navigate the
/// same way: they keep what is open in their own state and pass the destination
/// that was asked for back into [buildExamplePage].
///
/// [signup] is not a page: it is the sign-up form, which the frame shows as a
/// dialog over the listings. [apartments] is the page itself.
enum ExamplePage {
  /// The sign-up form, shown as a dialog over the page.
  signup('Sign up'),

  /// The list of apartments.
  apartments('Apartments'),

  /// The page a customer lands on: what a home costs, and what the rent covers.
  ///
  /// It is here because it is the kind of page this library exists for. A pricing
  /// page has to be found, so it is written once as a tree and served as HTML and
  /// CSS; the same tree is the screen in the app.
  pricing('Pricing');

  const ExamplePage(this.label);

  /// The label of the destination in the navigation bar.
  final String label;
}

/// The addresses of the example's documents, relative to any of them.
///
/// Every destination is written into its own directory — `web/listings/`,
/// `web/signup/`, and the same pair under `flutter/` — so a sibling link is the
/// same string from every document, which is why the tree can carry it without the
/// host telling it where it is. It is also how a static page does what a click on a
/// button cannot without a client runtime: follow a link and land on the state the
/// destination names.
abstract final class ExampleRoutes {
  /// The document that shows the listings.
  static const String listings = '../listings/';

  /// The document that shows the sign-up dialog open over the listings.
  static const String signup = '../signup/';

  /// The document that shows what the product costs.
  static const String pricing = '../pricing/';
}

/// The frame every page is drawn in: the canvas, the navigation bar, [page] and,
/// when it is open, [dialog].
///
/// [dialog] is an [OverlayNode] — `exampleView` builds it from `buildSignupDialog`
/// while the form is open and leaves it out when it is closed. Presence is
/// therefore the state of the page, exactly like the listings it is drawn over,
/// and the frame only places it.
///
/// The bar is part of the tree, not of a host. It is boxes and text like
/// everything else, and it changes what is open through `onTap`, exactly like the
/// newsletter opt-in toggles the form: the host owns the value, the tree asks for
/// a new one. That is what keeps the navigation identical in Flutter and on
/// the web instead of being a router on one side and a widget on the other.
///
/// [page] is expected to fill the space below the bar, which is what the listings
/// page does with `flex: 1`.
Box buildExamplePage({
  required ExamplePage current,
  required void Function(ExamplePage page) onNavigate,
  required UINode page,
  OverlayNode? dialog,
}) {
  return Box(
    direction: Axis.vertical,
    width: double.infinity,
    height: double.infinity,
    backgroundColor: const BoxColor.role(ExampleColor.canvas),
    children: <UINode>[
      _navigationBar(current: current, onNavigate: onNavigate),
      page,
      ?dialog,
    ],
  );
}

/// The bar above every page: the name of the example and one item per
/// destination.
///
/// The bar is a row that pushes its two ends apart, and the shadow with no blur
/// is the hairline under it: a `BoxBorder` draws on all four sides, while one
/// offset pixel of a shadow draws the single line a navigation bar needs, with
/// the same two tokens in both renderers.
UINode _navigationBar({
  required ExamplePage current,
  required void Function(ExamplePage page) onNavigate,
}) {
  // The brand keeps its width and the destinations take the rest, so the bar can
  // never be wider than the page: the items are a grid inside that remainder, and a
  // grid folds its columns when the room runs out instead of overflowing. A plain
  // row of three destinations overflowed by 68 pixels on a small surface, which is
  // what the suite caught when the bar gained one.
  return Box(
    direction: Axis.horizontal,
    mainAlign: MainAlign.spaceBetween,
    crossAlign: CrossAlign.center,
    width: double.infinity,
    padding: const BoxSpacing.symmetric(horizontal: 24, vertical: 12),
    // The bar is the navigation of the page, so the web renders a `<nav>`.
    semantics: const BoxSemantics(element: BoxElement.nav),
    backgroundColor: const BoxColor.role(ExampleColor.surface),
    shadow: const BoxShadow(
      color: BoxColor(0x14000000),
      offsetY: 1,
      blurRadius: 0,
    ),
    textStyle: ExampleType.body,
    children: <UINode>[
      const TextNode('Unibox', style: ExampleType.brand),
      Box(
        flex: 1,
        // A column, not a row: a grid inside a row is unbounded again, and an
        // unbounded grid is one column of whatever each item happens to be.
        crossAlign: CrossAlign.end,
        children: <UINode>[
          GridNode(
            // Wide enough for the longest label ('Apartments', 119 with its
            // padding): a track narrower than a row's smallest text overflows it,
            // which is what 84 did by 38 pixels.
            minItemWidth: 120,
            maxColumns: 3,
            gap: 4,
            children: <UINode>[
              for (final ExamplePage page in ExamplePage.values)
                _navigationItem(
                  page,
                  current: page == current,
                  onTap: () => onNavigate(page),
                ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// One item of the navigation: a link around a label, highlighted while its
/// destination is open.
///
/// The link is the control. Its `href` is what makes the item work without a client
/// runtime — a static page follows it and lands on the document the destination
/// names — and its `onTap` is what happens instead once there is one: the store
/// switches the page and the browser does not load the document as well. The box
/// inside keeps its own role and `aria-current`, because the label is what a reader
/// and a screen reader see; the anchor is what is pressed.
UINode _navigationItem(
  ExamplePage page, {
  required bool current,
  required TapCallback onTap,
}) {
  return LinkNode(
    // The href is the document of the destination, not of the page being drawn:
    // without it, adding a destination linked its item to the listings.
    switch (page) {
      ExamplePage.signup => ExampleRoutes.signup,
      ExamplePage.pricing => ExampleRoutes.pricing,
      ExamplePage.apartments => ExampleRoutes.listings,
    },
    onTap: onTap,
    child: Box(
      direction: Axis.horizontal,
      mainAlign: MainAlign.center,
      padding: const BoxSpacing.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 8,
      backgroundColor: current ? ExamplePalette.accentSurface : null,
      textStyle: current ? ExampleType.navCurrent : ExampleType.nav,
      semantics: BoxSemantics(
        role: page == ExamplePage.signup ? BoxRole.button : BoxRole.link,
        // The item of the page the reader is on: `aria-current` on the web, the
        // selected item of a set in Flutter. A dialog is not a document.
        current: current && page == ExamplePage.apartments
            ? BoxCurrent.page
            : null,
      ),
      stateStyles: const <BoxState, BoxStyle>{
        BoxState.hover: BoxStyle(backgroundColor: ExamplePalette.accentSurface),
      },
      transition: ExampleType.transition,
      children: <UINode>[TextNode(page.label)],
    ),
  );
}
