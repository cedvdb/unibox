import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// A Material 3 scaffold: an app bar that stays, and a body under it.
///
/// ```dart
/// MaterialScaffold(
///   appBar: MaterialAppBar(title: const TextNode('Apartments')),
///   body: Box(
///     // The body fills the room the bar leaves: `double.infinity` is a share of the
///     // screen, which is `height: 100%` on the page and an `Expanded` in Flutter.
///     height: double.infinity,
///     overflow: Overflow.scroll,
///     children: <UINode>[
///       MaterialAppBar(title: const TextNode('Two rooms'), pin: BoxPin.start),
///       for (final Flat flat in flats) MaterialListTile(title: TextNode(flat.name)),
///     ],
///   ),
/// )
/// ```
///
/// It adds no renderer work: it *is* a box — the bar, then the body, on one surface — so both
/// targets draw it with the renderer they already have. What the class buys is the composition
/// every Material screen starts from, and the surface that makes it hold together.
///
/// **The app bar is the scaffold's, and it does not move.** That is what a scaffold is for: the
/// bar sits outside the scroll, so it needs no `pin` and no `pinOffset` — and a bar *inside* the
/// body pins at the body's own top edge, which is already under the app bar, without any inset. A
/// bar that should scroll away and come to rest at the edge is not a scaffold: it is a band inside
/// a scrolling box, which is what `pin: BoxPin.start` states.
///
/// **The page and the bar are two colours.** The scaffold paints
/// [MaterialScaffold.surface] — Material's `surface`, the page a screen is drawn on — and the bar
/// paints `MaterialAppBar.surface`, one step up the container ladder. That is what makes a bar
/// read as a band rather than as the first row of a list, and it is Material's own arrangement:
/// a top app bar states `surfaceContainer`, the screen behind it states `surface`.
///
/// **A pull reveals the page.** A pull past either end of the body opens a gap of the scaffold's
/// colour, so a body with no background of its own shows the page under its content and the pull
/// reads as the screen moving rather than as a strip of something else.
///
/// **The body fills, or it does not.** `height: double.infinity` is the whole of the rest of the
/// screen — the form a scrolling body takes — and a body that states nothing takes its own height,
/// which is what a screen that fits wants. The scaffold does not size it for the caller: a flex
/// child would have to hand the body an unbounded axis, and a scrolling box cannot be laid out in
/// one.
final class MaterialScaffold extends Box {
  /// Creates a scaffold with [appBar] above [body].
  ///
  /// `color` is the page the screen is drawn on, and the rest are the scaffold's own tokens: the
  /// size it fills, its margin, and what it says to a reader.
  factory MaterialScaffold({
    Object? key,
    UINode? appBar,
    required UINode body,
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
        // A band and a body span the screen: the column stretches them instead of hugging
        // their content, so a bar with a short title is still as wide as the phone it is in.
        crossAlign: CrossAlign.stretch,
        children: <UINode>[?appBar, body],
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
  /// scaffold and the bar name different roles on purpose.
  static const BoxColor surface = BoxColor.role(MaterialColorRole.surface);
}
