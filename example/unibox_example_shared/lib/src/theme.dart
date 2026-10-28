import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The colour roles of the example.
///
/// A role is what a tree names; the palette below says what it is worth. Keeping
/// the two apart is what lets a host restyle the page — the exported document
/// overrides three of these roles in a `prefers-color-scheme: dark` block — and it
/// is why the same names are readable from CSS (`--unibox-color-canvas`) and from
/// the Flutter theme built from this palette.
enum ExampleColor {
  /// The accent of the banner, the button and the checkbox.
  accent,

  /// The accent while the pointer is over the button.
  accentHover,

  /// The accent while the button is pressed.
  accentPressed,

  /// The tint behind the navigation item that is open.
  accentSurface,

  /// The background of a raised panel: a card, the navigation bar, a field.
  panel,

  /// The colour of the page behind the card.
  canvas,

  /// The default text colour.
  text,

  /// The colour of supporting text.
  muted,

  /// The colour of borders.
  border,
}

/// The palette of the example, grown from one seed.
///
/// The example is branded with a single colour. Material's colour algorithm turns
/// that colour into the twenty roles, and the roles the example names of its own —
/// its accent, its borders, its success — are read out of the palette it grows, so
/// [ExamplePalette.seed] is the only colour written down in this file and a
/// different brand is a different seed.
///
/// The values are `final` and not `const`, because a palette grown from a seed is
/// computed once when the page is built rather than typed into the source. That is
/// the price of one seed instead of twenty hex values, and it is why the styles
/// below are `final` too.
abstract final class ExamplePalette {
  /// The one colour the example is branded with.
  static const BoxColor seed = BoxColor.rgb(0x2D, 0x6C, 0xF3);

  /// The seed of the confirmation message.
  ///
  /// Material's roles carry an error and no success, so the example seeds a palette
  /// of its own for the second one: the same call, another colour.
  static const BoxColor successSeed = BoxColor.rgb(0x15, 0x80, 0x3D);

  /// The palette the page is drawn with.
  ///
  /// `tonalSpot` is Material You's own scheme and it spends a saturated brand
  /// colour on a low chroma palette, so the accent below is quieter than the seed.
  /// [MaterialSchemeVariant.fidelity] would keep the seed's own chroma instead.
  static final MaterialPalette material = MaterialPalette.fromSeed(seed);

  /// The palette the confirmation message is drawn with.
  static final MaterialPalette confirmation = MaterialPalette.fromSeed(
    successSeed,
  );

  /// The values of [ExampleColor], as one theme both hosts hand to the renderer.
  ///
  /// This is the single place the example's colours are read: the tree names a
  /// role, the web renderer writes the theme into `:root`, and the Flutter
  /// renderer resolves the same map. A host that wants a dark page overrides the
  /// variables or passes another theme; it does not touch the tree.
  ///
  /// The page also uses components from `unibox_material`, which name
  /// `MaterialColorRole`s of their own, so the generated scheme is merged in: two
  /// vocabularies, one theme, and the roles the example defines still win.
  static final UniboxTheme theme = UniboxTheme(
    colors: <ExampleColor, BoxColor>{
      ExampleColor.accent: accent,
      ExampleColor.accentHover: accentHover,
      ExampleColor.accentPressed: accentPressed,
      ExampleColor.accentSurface: accentSurface,
      ExampleColor.panel: panel,
      ExampleColor.canvas: canvas,
      ExampleColor.text: text,
      ExampleColor.muted: muted,
      ExampleColor.border: border,
    },
  ).merge(material.theme);

  /// The accent of the banner, the button and the checkbox.
  static final BoxColor accent = material.primary;

  /// The accent while the pointer is over the button.
  ///
  /// Material paints a hover as a translucent layer over the fill, and a box paints
  /// one opaque colour, so the layer the palette states is mixed into the accent.
  static final BoxColor accentHover = _paintedOver(accent, material.hoverLayer);

  /// The accent while the button is pressed.
  static final BoxColor accentPressed = _paintedOver(
    accent,
    material.pressedLayer,
  );

  /// The tint behind the navigation item that is open.
  ///
  /// Material's own indicator for a chosen destination is the secondary container,
  /// and it is the right role here for a second reason: it stays a container
  /// whatever variant the seed is spent on, while the primary container can be the
  /// seed itself.
  static final BoxColor accentSurface = material.secondaryContainer;

  /// The background of a raised panel: a card, the navigation bar, a field — and the
  /// white that contrasts with [accent], which is why a button's label is drawn in it.
  ///
  /// It is not named `surface`, because `unibox_material` already has a role with that
  /// name and both vocabularies share one `:root` block on the web: two roles writing
  /// `--unibox-color-surface` would leave one of them silently unused there while
  /// Flutter resolved both, which is exactly the divergence the roles exist to prevent.
  static final BoxColor panel = material.surfaceContainerLowest;

  /// The color of the page behind the card.
  ///
  /// A container tone rather than the surface itself, because the example paints
  /// white cards on it: Material's ladder puts the page at `surface` and a panel a
  /// step above it at `surfaceContainerLowest`, and the example reads better with
  /// the two the other way round.
  static final BoxColor canvas = material.surfaceContainerLow;

  /// The default text color.
  static final BoxColor text = material.onSurface;

  /// The color of supporting text.
  static final BoxColor muted = material.onSurfaceVariant;

  /// The color of borders, and of the button while it is not ready.
  static final BoxColor border = material.outlineVariant;

  /// The color of a field that is wrong, and of the message under it.
  ///
  /// Error is the one accent Material derives without the seed, because a failure
  /// is a convention rather than a brand.
  static final BoxColor danger = material.error;

  /// The color of the confirmation message.
  static final BoxColor success = confirmation.primary;

  /// The background of the confirmation message.
  static final BoxColor successSurface = confirmation.secondaryContainer;

  /// The tint of the square that stands in for the photo of a listing.
  ///
  /// These are illustration rather than palette: they stand in for photographs that
  /// a listing would carry, so they are the six tints a photographer would pick and
  /// not a family the brand derives.
  static const List<BoxColor> listingTints = <BoxColor>[
    BoxColor.rgb(0xFD, 0xE8, 0xD3),
    BoxColor.rgb(0xE1, 0xEB, 0xFA),
    BoxColor.rgb(0xF3, 0xE3, 0xF1),
    BoxColor.rgb(0xE3, 0xF2, 0xE8),
    BoxColor.rgb(0xFA, 0xF0, 0xD5),
    BoxColor.rgb(0xE8, 0xE6, 0xF7),
  ];

  /// [base] with [layer] painted over it, as Material paints a state.
  ///
  /// [layer] is a translucent colour — [MaterialPalette.hoverLayer] is the
  /// on-surface colour at 8% — so the mix is its opacity against the channels of
  /// [base], which is what the browser and Flutter composite when they paint the
  /// layer themselves.
  static BoxColor _paintedOver(BoxColor base, BoxColor layer) {
    int mix(int channel, int over) =>
        (channel + (over - channel) * layer.opacity).round();

    return BoxColor.rgb(
      mix(base.red, layer.red),
      mix(base.green, layer.green),
      mix(base.blue, layer.blue),
    );
  }
}

/// The typography of the example.
///
/// Typography is the one thing a box passes down to its children, so a page
/// states it once per area and the text nodes only repeat a token they
/// override. The result is identical in Flutter and on the web: a
/// `DefaultTextStyle` on one side, plain CSS inheritance on the other.
abstract final class ExampleType {
  /// How a hover or a press changes the look of a control.
  ///
  /// One duration for the whole example, so a nav item, a card and a button all
  /// settle at the same speed: fast enough to feel like feedback rather than an
  /// animation.
  static const BoxTransition transition = BoxTransition(
    duration: Duration(milliseconds: 150),
  );

  /// The line height of the example, as a multiple of the font size.
  ///
  /// The unitless form is the only one that means the same thing in CSS and in
  /// Flutter, so every text of the example gets the same leading on both
  /// targets. A font *family* is deliberately left out: a family is a host
  /// decision — the Flutter app inherits the platform font from its theme, the
  /// web app declares a stack on the document — and both platforms end up on
  /// their own UI font, which is the closest a family can get across two
  /// applications.
  static const double lineHeight = 1.45;

  /// The body text of the example.
  ///
  /// This is the style a page installs, so everything below it inherits the
  /// line height and only overrides size, weight and colour.
  static final BoxTextStyle body = BoxTextStyle(
    fontSize: 14,
    color: ExamplePalette.text,
    lineHeight: lineHeight,
  );

  /// Supporting text, such as hints and the status line.
  static final BoxTextStyle muted = BoxTextStyle(
    fontSize: 13,
    color: ExamplePalette.muted,
  );

  /// The title of a card or of a page.
  static final BoxTextStyle title = BoxTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: ExamplePalette.text,
  );

  /// The name of the example, at the start of the navigation bar.
  static final BoxTextStyle brand = BoxTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ExamplePalette.text,
  );

  /// A navigation item that is not open.
  static final BoxTextStyle nav = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.medium,
    color: ExamplePalette.muted,
  );

  /// The navigation item that is open.
  static final BoxTextStyle navCurrent = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.semiBold,
    color: ExamplePalette.accent,
  );

  /// The label of the primary button.
  static final BoxTextStyle button = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.semiBold,
    color: ExamplePalette.panel,
  );

  /// The link under the button.
  static final BoxTextStyle link = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.medium,
    color: ExamplePalette.accent,
  );

  /// The name of a listing.
  static final BoxTextStyle listingName = BoxTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.semiBold,
    color: ExamplePalette.text,
  );

  /// The rent of a listing.
  static final BoxTextStyle listingPrice = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.semiBold,
    color: ExamplePalette.accent,
  );
}
