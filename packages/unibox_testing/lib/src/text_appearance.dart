import 'package:unibox_core/unibox_core.dart' as core;

import 'token_difference.dart';

/// How a text node is typeset once it has been rendered.
///
/// The two renderers produce different kinds of output — a `Text` widget on one
/// side, a `<span>` with declarations on the other — so the only thing that can be
/// compared is what the output asks for. Both are asked for the same thing: one
/// font size, weight, colour, line height, letter spacing, family, decoration,
/// alignment and truncation per node, written as `TextStyle` fields on one side and
/// as CSS properties on the other.
///
/// Only the tokens a renderer *declared* for the node are part of this, which is
/// the same line the box contract draws. Everything else is inherited, and the
/// two hosts inherit from different places: Flutter falls back to 14 logical
/// pixels of black, a browser to 16 pixels of `canvastext`. A tree that declares
/// its typography is therefore typeset the same way on both targets, while a tree
/// that leaves the font to the host is typeset by that host — no renderer can
/// repair a difference between `MaterialApp`'s text theme and a `<body>`.
///
/// What this can promise is that a token reaches both outputs unchanged. What it
/// cannot promise is the pixels: glyph shapes, hinting, kerning and line breaking
/// belong to the text engine — Skia in Flutter, the browser's own on the web — and
/// they part company wherever the two measure a font differently, wherever a
/// family is installed on one side only, and wherever a line has to wrap. One
/// line box is the exception, because both sides compute it from the same two
/// numbers: `fontSize * lineHeight` when [lineHeight] is set, and the font's own
/// metrics when it is not — which is why a layout that has to line up should
/// always set it.
///
/// An absent token means the node said nothing, so it is compared as `null` and
/// not as the value the host would have resolved it to.
final class TextAppearance {
  /// Creates a description of the typography of a rendered text node.
  const TextAppearance({
    this.fontSize,
    this.fontWeight,
    this.color,
    this.lineHeight,
    this.fontFamily,
    this.letterSpacing,
    this.decoration,
    this.decorationColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// The font size in logical pixels, `px` on the web.
  final double? fontSize;

  /// The weight of the font.
  ///
  /// Both targets express it as one of the five weights the model has — `300` in
  /// CSS, [FontWeight.w300] in Flutter — so a renderer that rounded a weight up
  /// or down is visible here.
  final core.FontWeight? fontWeight;

  /// The colour of the glyphs.
  final core.BoxColor? color;

  /// The line height as a multiple of [fontSize].
  ///
  /// Unitless on both sides, which is what makes the line box comparable: CSS
  /// multiplies the unitless `line-height` by the font size at layout time, and so
  /// does Flutter with `TextStyle.height`.
  final double? lineHeight;

  /// The name of the font family.
  final String? fontFamily;

  /// Extra space between characters in logical pixels.
  final double? letterSpacing;

  /// The line drawn across the text, or `null` when it draws none of its own.
  final core.TextDecoration? decoration;

  /// The colour of [decoration], or `null` when the line is the colour of the
  /// glyphs — which is what both targets do with an unset colour, so this is
  /// compared as "said nothing" rather than as the resolved value.
  final core.BoxColor? decorationColor;

  /// The horizontal alignment of the lines in the space the text is given.
  final core.TextAlign? textAlign;

  /// The number of lines the text is allowed to occupy, or `null` for any number.
  final int? maxLines;

  /// How text that does not fit its lines is truncated.
  ///
  /// CSS reaches the same two outcomes by other means — `text-overflow` and, for
  /// a [maxLines], a `-webkit-line-clamp` box — which is why the renderers are
  /// compared by the outcome rather than by the declarations that produce it.
  final core.TextOverflow? overflow;

  /// The tokens this appearance presents differently from [expected].
  ///
  /// Empty when the two describe the same typesetting, which is what a renderer
  /// suite asserts. Comparing token by token is what makes a failure readable:
  /// the map names the token that drifted and shows what each side did with it.
  Map<String, TokenDifference> differencesFrom(TextAppearance expected) {
    final Map<String, TokenDifference> differences =
        <String, TokenDifference>{};

    void compare(String token, Object? actualValue, Object? expectedValue) {
      if (actualValue != expectedValue) {
        differences[token] = (actual: actualValue, expected: expectedValue);
      }
    }

    compare('fontSize', fontSize, expected.fontSize);
    compare('fontWeight', fontWeight, expected.fontWeight);
    compare('color', color, expected.color);
    compare('lineHeight', lineHeight, expected.lineHeight);
    compare('fontFamily', fontFamily, expected.fontFamily);
    compare('letterSpacing', letterSpacing, expected.letterSpacing);
    compare('decoration', decoration, expected.decoration);
    compare('decorationColor', decorationColor, expected.decorationColor);
    compare('textAlign', textAlign, expected.textAlign);
    compare('maxLines', maxLines, expected.maxLines);
    compare('overflow', overflow, expected.overflow);

    return differences;
  }

  /// A copy of this description with the given tokens replaced.
  ///
  /// Passing `null` keeps the current value, the same way
  /// [core.BoxTextStyle.copyWith] does; build a fresh appearance to clear one.
  TextAppearance copyWith({
    double? fontSize,
    core.FontWeight? fontWeight,
    core.BoxColor? color,
    double? lineHeight,
    String? fontFamily,
    double? letterSpacing,
    core.TextDecoration? decoration,
    core.BoxColor? decorationColor,
    core.TextAlign? textAlign,
    int? maxLines,
    core.TextOverflow? overflow,
  }) {
    return TextAppearance(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      color: color ?? this.color,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      textAlign: textAlign ?? this.textAlign,
      maxLines: maxLines ?? this.maxLines,
      overflow: overflow ?? this.overflow,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TextAppearance && differencesFrom(other).isEmpty;

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
    textAlign,
    maxLines,
    overflow,
  );

  @override
  String toString() {
    return 'TextAppearance('
        'fontSize: $fontSize, '
        'fontWeight: $fontWeight, '
        'color: $color, '
        'lineHeight: $lineHeight, '
        'fontFamily: $fontFamily, '
        'letterSpacing: $letterSpacing, '
        'decoration: $decoration, '
        'decorationColor: $decorationColor, '
        'textAlign: $textAlign, '
        'maxLines: $maxLines, '
        'overflow: $overflow'
        ')';
  }
}
