import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// A Material 3 scaffold: an app bar that stays, a body, and a bottom bar under it.
///
/// ```dart
/// MaterialScaffold(
///   appBar: MaterialAppBar(title: const TextNode('Apartments')),
///   bottomBar: MaterialNavigationBar(…),
///   body: Box(
///     // The body takes the room the two bars leave. `flex: 1` is the one spelling both targets
///     // read as "the rest": a `flex-grow` of one with a basis of zero in a browser, an
///     // `Expanded` in Flutter.
///     flex: 1,
///     overflow: Overflow.scroll,
///     children: <UINode>[
///       for (final Flat flat in flats) MaterialListTile(title: TextNode(flat.name)),
///     ],
///   ),
/// )
/// ```
///
/// It adds no renderer work: it *is* a box — the bar, the body and the bottom bar on one
/// surface — so both targets draw it with the renderer they already have. What the class buys is
/// the composition every Material screen starts from, and the surface that makes it hold together.
///
/// **Both bars are outside the scroll, and that is what a scaffold is for.** The body scrolls
/// between them, so neither bar moves, and neither needs a `pin` or a `pinOffset`. It is also what
/// keeps the pull honest: the strip a reader pulls open at either end of the body opens *inside*
/// the body, so it is the page that shows — never the edge of a bar that ended a moment ago. A bar
/// that shows its own edge on a pull is content that pins (`Box(pin: …)`), which is a different
/// composition and the one the catalogue's two screens demonstrate.
///
/// **The page and the bars are two colours.** The scaffold paints [MaterialScaffold.surface] —
/// Material's `surface`, the page a screen is drawn on — and the bars paint
/// `MaterialAppBar.surface`, one step up the container ladder. That is what makes a bar read as a
/// bar rather than as the first or last row of a list, and it is Material's own arrangement.
///
/// **A pull reveals the page.** A pull past either end of the body opens a gap of the scaffold's
/// colour, so a body with no background of its own shows the page under its content and the pull
/// reads as the screen moving rather than as a strip of something else.
///
/// **The body fills, or it does not.** Beside either bar, a body that must take the rest of the
/// screen states `flex: 1` — the two bars then keep the heights they state, and the body is what
/// grows. `height: double.infinity` is a share of the *whole* column instead: a browser resolves
/// it against a height the bars are already inside, and shrinks all three to fit, so the bars come
/// out shorter than they asked to be. The scaffold does not size the body for the caller — a flex
/// child would hand a scrolling box an unbounded axis, and a scroll view cannot be laid out in one
/// — so a screen that fits states nothing, and a screen that scrolls states `flex: 1`.
final class MaterialScaffold extends Box {
  /// Creates a scaffold with [appBar] above [body] and [bottomBar] under it.
  ///
  /// `color` is the page the screen is drawn on, and the rest are the scaffold's own tokens: the
  /// size it fills, its margin, and what it says to a reader.
  factory MaterialScaffold({
    Object? key,
    UINode? appBar,
    required UINode body,
    UINode? bottomBar,
    BoxColor color = surface,
    double width = double.infinity,
    double height = double.infinity,
    BoxSpacing? margin,
    BoxSemantics? semantics,
  }) {
    return MaterialScaffold._(
      key: key,
      box: Box(
        width: width,
        height: height,
        margin: margin,
        backgroundColor: color,
        semantics: semantics,
        // A bar and a body span the screen: the column stretches them instead of hugging
        // their content, so a bar with a short title is still as wide as the phone it is in.
        crossAlign: CrossAlign.stretch,
        children: <UINode>[?appBar, body, ?bottomBar],
      ),
    );
  }

  MaterialScaffold._({super.key, required Box box})
    : super(
        width: box.width,
        height: box.height,
        margin: box.margin,
        backgroundColor: box.backgroundColor,
        semantics: box.semantics,
        crossAlign: box.crossAlign,
        children: box.children,
      );

  /// The page a screen is drawn on, and the colour a pull past the body reveals.
  ///
  /// Material's `surface`: the screen's own background, one step below the container a top app
  /// bar paints. Stating the two as one colour is what made a bar disappear into its list, so the
  /// scaffold and the bars name different roles on purpose.
  static const BoxColor surface = BoxColor.role(MaterialColorRole.surface);
}
