import 'package:unibox_core/unibox_core.dart';

import 'seed_picker.dart';
import 'theme.dart';

/// What the bar can ask for: the page, and the sign-up form.
///
/// The names live here rather than in a host, because both hosts navigate the
/// same way: they keep what is open in their own state and pass the destination
/// that was asked for back into [buildExamplePage].
///
/// [signup] is not a destination of the bar: an account is a form that opens over
/// the page being read, so the bar offers it as a button and only [destinations]
/// are drawn as links. It stays a member because the state names it and because the
/// export still writes the document that shows the form open.
enum ExamplePage {
  /// The list of apartments.
  apartments('Apartments'),

  /// The sign-up form, shown as a dialog over the page.
  signup('Sign up');

  const ExamplePage(this.label);

  /// The label of the destination in the navigation bar.
  final String label;

  /// The destinations the bar offers, and the document each one names.
  ///
  /// A destination is a page, and every page is a document: the link's `href` is what
  /// a reader without the client runtime follows, and what a crawler reads as the way
  /// through the site. [signup] is deliberately absent — see `_signUp`.
  static const Map<ExamplePage, String> destinations = <ExamplePage, String>{
    apartments: ExampleRoutes.listings,
  };
}

/// The addresses of the example's documents, relative to any of them.
///
/// Every page is written into its own directory — `web/listings/` and `web/signup/`
/// — so a sibling link is the same string from every document, which is why the tree
/// can carry it without the host telling it where it is. It is also how a static page
/// does what a click cannot without a client runtime: follow a link and land on the
/// state the destination names.
abstract final class ExampleRoutes {
  /// The document that shows the listings.
  static const String listings = '../listings/';

  /// The document that shows the sign-up dialog open over the listings.
  ///
  /// Nothing in the markup links to it: the form is a button, not a place to go. It
  /// is written for a reader who arrives at its address, and for a crawler that
  /// finds the state described.
  static const String signup = '../signup/';
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
  ExampleSeed seed = ExampleSeed.defaultSeed,
}) {
  return Box(
    direction: Axis.vertical,
    width: double.infinity,
    height: double.infinity,
    backgroundColor: const BoxColor.role(ExampleColor.canvas),
    children: <UINode>[
      seedPicker(current: seed),
      _navigationBar(current: current, onNavigate: onNavigate),
      page,
      ?dialog,
    ],
  );
}

/// The bar above every page: the name of the example, its destinations, and the way
/// into an account.
///
/// The bar is a row that pushes its two ends apart, and the shadow with no blur is the
/// hairline under it: a `BoxBorder` draws on all four sides, while one offset pixel of
/// a shadow draws the single line a navigation bar needs, with the same two tokens in
/// both renderers.
///
/// Two things travel in it and they are not the same kind of thing. The destinations
/// are navigation, so they sit in a `<nav>` landmark together with the name and they
/// are links; the sign-up form is an action over whatever page is open, so it is a
/// button beside the landmark.
UINode _navigationBar({
  required ExamplePage current,
  required void Function(ExamplePage page) onNavigate,
}) {
  // The brand keeps its width and the destinations take the rest, so the bar can
  // never be wider than the page: the items are a grid inside that remainder, and a
  // grid folds its columns when the room runs out instead of overflowing.
  return Box(
    direction: Axis.horizontal,
    mainAlign: MainAlign.spaceBetween,
    crossAlign: CrossAlign.center,
    width: double.infinity,
    padding: const BoxSpacing.symmetric(horizontal: 24, vertical: 12),
    backgroundColor: const BoxColor.role(ExampleColor.panel),
    shadow: const BoxShadow(
      color: BoxColor(0x14000000),
      offsetY: 1,
      blurRadius: 0,
    ),
    textStyle: ExampleType.body,
    children: <UINode>[
      Box(
        // The navigation of the page, so the web renders a `<nav>`: the landmark a
        // reader jumps to, and the one a crawler reads the site's links from.
        semantics: const BoxSemantics(element: BoxElement.nav),
        direction: Axis.horizontal,
        crossAlign: CrossAlign.center,
        gap: 12,
        flex: 1,
        children: <UINode>[
          TextNode('Unibox', style: ExampleType.brand),
          Box(
            flex: 1,
            // A column, not a row: a grid inside a row is unbounded again, and an
            // unbounded grid is one column of whatever each item happens to be.
            crossAlign: CrossAlign.end,
            children: <UINode>[
              GridNode(
                // Wide enough for the longest label ('Apartments', 119 with its
                // padding): a track narrower than a row's smallest text overflows it.
                minItemWidth: 120,
                maxColumns: 2,
                gap: 4,
                children: <UINode>[
                  for (final MapEntry<ExamplePage, String> destination
                      in ExamplePage.destinations.entries)
                    _navigationItem(
                      destination.key,
                      url: destination.value,
                      current: destination.key == current,
                      onTap: () => onNavigate(destination.key),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
      _signUp(onTap: () => onNavigate(ExamplePage.signup)),
    ],
  );
}

/// One destination of the navigation: a link around a label, highlighted while its
/// page is open.
///
/// The link is the control. Its `href` is what makes the item work without a client
/// runtime — a static page follows it and lands on the document the destination
/// names — and its `onTap` is what happens instead once there is one: the store
/// switches the page and the browser does not load the document as well. The box
/// inside keeps its own role and `aria-current`, because the label is what a reader
/// and a screen reader see; the anchor is what is pressed.
UINode _navigationItem(
  ExamplePage page, {
  required String url,
  required bool current,
  required TapCallback onTap,
}) {
  return LinkNode(
    url,
    onTap: onTap,
    child: Box(
      direction: Axis.horizontal,
      mainAlign: MainAlign.center,
      padding: const BoxSpacing.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 8,
      backgroundColor: current
          ? BoxColor.role(ExampleColor.accentSurface)
          : null,
      textStyle: current ? ExampleType.navCurrent : ExampleType.nav,
      semantics: BoxSemantics(
        role: BoxRole.link,
        // The page the reader is on: `aria-current` on the web, the selected item of
        // a set in Flutter.
        current: current ? BoxCurrent.page : null,
      ),
      stateStyles: <BoxState, BoxStyle>{
        BoxState.hover: BoxStyle(
          backgroundColor: BoxColor.role(ExampleColor.accentSurface),
        ),
      },
      transition: ExampleType.transition,
      children: <UINode>[TextNode(page.label)],
    ),
  );
}

/// The way into an account: a button, beside the navigation and not inside it.
///
/// The sign-up form is a dialog over whatever page is being read, so the control is
/// a box that names the button role and carries an `onTap` — nothing more. A
/// `LinkNode` here would tell a crawler, a context menu and a reader without the
/// client runtime that an account is a document, and the browser would load
/// `/web/signup/` on top of the dialog the runtime had just opened.
///
/// It is also outside the `<nav>` landmark, because a landmark is the page's list of
/// places to go and this is an action.
UINode _signUp({required TapCallback onTap}) {
  return Box(
    onTap: onTap,
    direction: Axis.horizontal,
    mainAlign: MainAlign.center,
    padding: const BoxSpacing.symmetric(horizontal: 14, vertical: 8),
    borderRadius: 8,
    backgroundColor: BoxColor.role(ExampleColor.accent),
    textStyle: ExampleType.button,
    semantics: const BoxSemantics(role: BoxRole.button),
    stateStyles: <BoxState, BoxStyle>{
      BoxState.hover: BoxStyle(
        backgroundColor: BoxColor.role(ExampleColor.accentHover),
      ),
      BoxState.pressed: BoxStyle(
        backgroundColor: BoxColor.role(ExampleColor.accentPressed),
      ),
    },
    transition: ExampleType.transition,
    children: <UINode>[TextNode(ExamplePage.signup.label)],
  );
}
