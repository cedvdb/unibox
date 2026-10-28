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

  /// The colour of a field that is wrong, and of the message under it.
  danger,

  /// The colour of the confirmation message.
  success,

  /// The background of the confirmation message.
  successSurface,
}

/// The seeds the example can be drawn with.
///
/// One colour each: Material's algorithm grows the rest of the palette from it, so
/// the accent, the cards, the page and the muted text all change together.
/// [defaultSeed] is the one the example is branded with unless the address asks for
/// another (`?seed=blue`), and the order of this enum is the order the picker draws
/// them in, so the seed in force at `/` is the first of the row.
enum ExampleSeed {
  /// The pink the example is branded with: a warm accent on a near-white page.
  rose('Rose', BoxColor.rgb(0xB3, 0x26, 0x5E)),

  /// A blue: the colour the example was branded with before it could be picked.
  blue('Blue', BoxColor.rgb(0x2D, 0x6C, 0xF3)),

  /// A violet, close to Material's own baseline seed.
  violet('Violet', BoxColor.rgb(0x67, 0x50, 0xA4)),

  /// A teal: a green that leans to the blue side.
  teal('Teal', BoxColor.rgb(0x00, 0x6D, 0x77)),

  /// A leaf green.
  green('Green', BoxColor.rgb(0x2E, 0x7D, 0x32)),

  /// An amber, the warmest of the six.
  amber('Amber', BoxColor.rgb(0xA8, 0x60, 0x00));

  const ExampleSeed(this.label, this.color);

  /// The seed the example is branded with, which is what an address without one gets.
  static const ExampleSeed defaultSeed = rose;

  /// The name of the seed, which is what a screen reader reads out.
  final String label;

  /// The colour the palette is grown from.
  final BoxColor color;

  /// The accent this seed grows, which is what its swatch is painted with.
  ///
  /// The swatches show the *result*, not the seed: the tonal spot scheme lowers a
  /// saturated colour's chroma, and a picker that showed the seed would promise a
  /// colour the page will not use.
  BoxColor get accent => ExamplePalette.materialFor(this).primary;

  /// The seed [name] names, or [defaultSeed] when the address names none of them.
  ///
  /// An address is written by hand as often as by the picker, so a name the example
  /// does not know falls back to the one it is branded with instead of failing.
  static ExampleSeed fromName(String? name) {
    for (final ExampleSeed seed in values) {
      if (seed.name == name) {
        return seed;
      }
    }
    return defaultSeed;
  }
}

/// The palettes of the example, one per seed.
///
/// A seed is one colour; Material's algorithm turns it into the twenty roles, and the
/// roles the example names of its own — its accent, its panel, its success — are read
/// out of that palette. [themeFor] is therefore the whole vocabulary in one call: a
/// tree names [ExampleColor]s, and the theme answers them with the palette of the seed
/// the page was drawn with.
///
/// The tree never holds a colour of its own, which is what makes the picker possible:
/// choosing another seed rebuilds nothing, it installs another theme.
abstract final class ExamplePalette {
  /// The seed of the confirmation message.
  ///
  /// Material's roles carry an error and no success, so the example seeds a palette
  /// of its own for the second one: the same call, another colour, and the same
  /// palette for every brand seed — a confirmation is a convention, not a brand.
  static const BoxColor successSeed = BoxColor.rgb(0x15, 0x80, 0x3D);

  /// The palette the confirmation message is drawn with.
  static final MaterialPalette _confirmation = MaterialPalette.fromSeed(
    successSeed,
  );

  /// The palette each seed grows, computed once.
  ///
  /// `tonalSpot` is Material You's own scheme and it spends a saturated brand colour
  /// on a low chroma palette, which is why a swatch is painted with `primary` and not
  /// with the seed: the page uses the palette, not the colour that asked for it.
  /// [MaterialSchemeVariant.fidelity] would keep the seed's own chroma instead.
  static final Map<ExampleSeed, MaterialPalette> _material =
      <ExampleSeed, MaterialPalette>{
        for (final ExampleSeed seed in ExampleSeed.values)
          seed: MaterialPalette.fromSeed(seed.color),
      };

  /// The themes, one per seed, computed once so a redraw reuses the same values.
  static final Map<ExampleSeed, UniboxTheme> _themes =
      <ExampleSeed, UniboxTheme>{
        for (final MapEntry<ExampleSeed, MaterialPalette> entry
            in _material.entries)
          entry.key: _themeOf(entry.value),
      };

  /// The palette [seed] grows.
  static MaterialPalette materialFor(ExampleSeed seed) => _material[seed]!;

  /// The values of [ExampleColor] for [seed], as the theme a host installs.
  ///
  /// The example's own roles are answered here, and the palette Material grew is
  /// merged in behind them, so the components of `unibox_material` resolve their
  /// `MaterialColorRole`s in the same theme: two vocabularies, one theme, and the
  /// roles the example defines still win.
  static UniboxTheme themeFor(ExampleSeed seed) => _themes[seed]!;

  /// Builds the theme of one generated palette.
  static UniboxTheme _themeOf(MaterialPalette material) {
    final BoxColor accent = material.primary;

    return UniboxTheme(
      colors: <ExampleColor, BoxColor>{
        // The accent of the button, the banner and the checkbox, and the two states
        // Material paints as a translucent layer over it — mixed in, because a box
        // paints one opaque colour.
        ExampleColor.accent: accent,
        ExampleColor.accentHover: _paintedOver(accent, material.hoverLayer),
        ExampleColor.accentPressed: _paintedOver(accent, material.pressedLayer),
        // Material's own indicator for a chosen destination, and the one container
        // that stays a container whatever variant the seed is spent on.
        ExampleColor.accentSurface: material.secondaryContainer,
        // The white a card, the bar and a field are painted with — and the colour a
        // button's label is drawn in, because it contrasts with the accent.
        ExampleColor.panel: material.surfaceContainerLowest,
        // A container tone rather than the surface itself: the example paints white
        // cards, and Material's ladder puts the page one step below a panel.
        ExampleColor.canvas: material.surfaceContainerLow,
        ExampleColor.text: material.onSurface,
        ExampleColor.muted: material.onSurfaceVariant,
        ExampleColor.border: material.outlineVariant,
        // Error is the one accent Material derives without the seed, because a
        // failure is a convention rather than a brand.
        ExampleColor.danger: material.error,
        ExampleColor.success: _confirmation.primary,
        ExampleColor.successSurface: _confirmation.secondaryContainer,
      },
    ).merge(material.theme);
  }

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
  static const BoxTextStyle body = BoxTextStyle(
    fontSize: 14,
    color: BoxColor.role(ExampleColor.text),
    lineHeight: lineHeight,
  );

  /// Supporting text, such as hints and the status line.
  static const BoxTextStyle muted = BoxTextStyle(
    fontSize: 13,
    color: BoxColor.role(ExampleColor.muted),
  );

  /// The title of a card or of a page.
  static const BoxTextStyle title = BoxTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: BoxColor.role(ExampleColor.text),
  );

  /// The name of the example, at the start of the navigation bar.
  static const BoxTextStyle brand = BoxTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: BoxColor.role(ExampleColor.text),
  );

  /// A navigation item that is not open.
  static const BoxTextStyle nav = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.medium,
    color: BoxColor.role(ExampleColor.muted),
  );

  /// The navigation item that is open.
  static const BoxTextStyle navCurrent = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.semiBold,
    color: BoxColor.role(ExampleColor.accent),
  );

  /// The label of the primary button.
  static const BoxTextStyle button = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.semiBold,
    color: BoxColor.role(ExampleColor.panel),
  );

  /// The link under the button.
  static const BoxTextStyle link = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.medium,
    color: BoxColor.role(ExampleColor.accent),
  );

  /// The name of a listing.
  static const BoxTextStyle listingName = BoxTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.semiBold,
    color: BoxColor.role(ExampleColor.text),
  );

  /// The rent of a listing.
  static const BoxTextStyle listingPrice = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.semiBold,
    color: BoxColor.role(ExampleColor.accent),
  );
}
