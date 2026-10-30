import '../enums.dart';
import 'box_color.dart';
import 'unibox_theme.dart';

/// An immutable bundle of typography tokens.
///
/// Typography is the only axis Unibox inherits: a box passes its text style down
/// to its descendants, exactly like CSS font properties and Flutter's
/// `DefaultTextStyle`. Layout, spacing and alignment are never inherited, so a
/// text style can never move a box, only restyle the text inside it.
///
/// Every field is optional and `null` means "inherit". [merge] therefore keeps
/// the value of the base style whenever the overlay leaves a token unset, which
/// is what makes a shared style specialisable per box.
///
/// ```dart
/// const body = BoxTextStyle(fontSize: 16, color: BoxColor.black);
/// const muted = BoxTextStyle(color: BoxColor.rgb(0x6B, 0x72, 0x80));
///
/// final caption = body.merge(muted);
/// ```
final class BoxTextStyle {
  /// Creates a text style. Unspecified tokens stay `null`.
  const BoxTextStyle({
    this.fontSize,
    this.fontWeight,
    this.color,
    this.lineHeight,
    this.fontFamily,
    this.letterSpacing,
    this.decoration,
    this.decorationColor,
    this.decorationThickness,
  });

  /// The typography a text is typeset in when the tree says nothing else.
  ///
  /// Both renderers apply it to the root of the tree they render, so an
  /// undeclared text looks the same on both targets instead of inheriting each
  /// host's own idea of a default — which is not a detail the two share: Flutter
  /// falls back to 14 logical pixels of black, a browser to 16 pixels of
  /// `canvastext`, a colour that is not even fixed. A default that lives in the
  /// host cannot be the default of a library whose point is that one tree looks
  /// the same twice.
  ///
  /// The values are neutral rather than a design system: 16 pixels is the size a
  /// browser gives a document, 1.5 is the line height Material gives its body
  /// text, black is written down instead of inherited so that a dark theme cannot
  /// change it behind the model's back, and the letter spacing is pinned to zero
  /// so that a host theme cannot stretch the text by a fraction of a pixel per
  /// character.
  ///
  /// [fontFamily] is the only token without a value, because a font file is an
  /// asset of the application and not of the model. Unset means the platform's
  /// UI font on both targets: the engine default in Flutter, the generic
  /// `system-ui` family in CSS.
  static const BoxTextStyle defaults = BoxTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: BoxColor.black,
    lineHeight: 1.5,
    letterSpacing: 0,
  );

  /// The font size in logical pixels, `px` on the web.
  final double? fontSize;

  /// The weight of the font.
  final FontWeight? fontWeight;

  /// The color of the text.
  final BoxColor? color;

  /// The line height as a multiple of [fontSize].
  ///
  /// The unitless form is the only one CSS and Flutter agree on: `line-height:
  /// 1.5` and `TextStyle(height: 1.5)` both scale with the font size.
  final double? lineHeight;

  /// The font family name, resolved by the host application.
  ///
  /// Flutter falls back to the platform font when the family is unavailable,
  /// CSS does the same, so an unknown family never breaks a layout.
  final String? fontFamily;

  /// Extra space between characters in logical pixels.
  final double? letterSpacing;

  /// The line drawn across the text, or `null` to inherit one.
  ///
  /// A struck through price used to need a `StackNode` and a one pixel box
  /// positioned over the middle of a line — geometry that breaks the moment the
  /// type scale changes — because a line through a run of text is a typography
  /// token, not a shape.
  final TextDecoration? decoration;

  /// The colour of [decoration], or `null` for the colour of the glyphs.
  ///
  /// Unset is the one answer both targets already give: CSS draws a decoration
  /// in `currentColor` and Flutter in the text colour, so leaving it out is not a
  /// default the model has to write down.
  final BoxColor? decorationColor;

  /// How thick [decoration] is in logical pixels, or `null` for the thickness the
  /// font itself asks for.
  ///
  /// Resolved by the text engine — CSS calls it `from-font` and Flutter asks the
  /// font — so the number a renderer writes and the number it paints are only
  /// equal when this is set.
  final double? decorationThickness;

  /// Whether no token is set.
  bool get isEmpty => this == const BoxTextStyle();

  /// Creates a copy of this style with the given tokens replaced.
  ///
  /// Passing `null` keeps the current value; use a fresh [BoxTextStyle] to clear
  /// tokens.
  /// This typography with its role colour looked up in [theme].
  BoxTextStyle resolve(UniboxTheme theme) {
    final BoxColor? current = color;
    final BoxColor? line = decorationColor;

    if ((current == null || !current.isRole) &&
        (line == null || !line.isRole)) {
      return this;
    }

    return copyWith(
      color: current == null ? null : theme.resolve(current),
      decorationColor: line == null ? null : theme.resolve(line),
    );
  }

  BoxTextStyle copyWith({
    double? fontSize,
    FontWeight? fontWeight,
    BoxColor? color,
    double? lineHeight,
    String? fontFamily,
    double? letterSpacing,
    TextDecoration? decoration,
    BoxColor? decorationColor,
    double? decorationThickness,
  }) {
    return BoxTextStyle(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      color: color ?? this.color,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationThickness: decorationThickness ?? this.decorationThickness,
    );
  }

  /// Overlays [other] on top of this style.
  ///
  /// Tokens that are `null` in [other] keep the value from this style, all
  /// other tokens take precedence:
  ///
  /// ```dart
  /// final label = body.merge(const BoxTextStyle(fontWeight: FontWeight.bold));
  /// ```
  BoxTextStyle merge(BoxTextStyle? other) {
    if (other == null) {
      return this;
    }
    return BoxTextStyle(
      fontSize: other.fontSize ?? fontSize,
      fontWeight: other.fontWeight ?? fontWeight,
      color: other.color ?? color,
      lineHeight: other.lineHeight ?? lineHeight,
      fontFamily: other.fontFamily ?? fontFamily,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      decorationThickness: other.decorationThickness ?? decorationThickness,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BoxTextStyle &&
      other.fontSize == fontSize &&
      other.fontWeight == fontWeight &&
      other.color == color &&
      other.lineHeight == lineHeight &&
      other.fontFamily == fontFamily &&
      other.letterSpacing == letterSpacing &&
      other.decoration == decoration &&
      other.decorationColor == decorationColor &&
      other.decorationThickness == decorationThickness;

  @override
  int get hashCode => Object.hash(
    fontSize,
    fontWeight,
    color,
    lineHeight,
    fontFamily,
    letterSpacing,
    decoration,
    decorationColor,
    decorationThickness,
  );

  @override
  String toString() {
    final tokens = <String>[
      if (fontSize != null) 'fontSize: $fontSize',
      if (fontWeight != null) 'fontWeight: $fontWeight',
      if (color != null) 'color: $color',
      if (lineHeight != null) 'lineHeight: $lineHeight',
      if (fontFamily != null) 'fontFamily: $fontFamily',
      if (letterSpacing != null) 'letterSpacing: $letterSpacing',
      if (decoration != null) 'decoration: $decoration',
      if (decorationColor != null) 'decorationColor: $decorationColor',
      if (decorationThickness != null)
        'decorationThickness: $decorationThickness',
    ];
    return 'BoxTextStyle(${tokens.join(', ')})';
  }
}
