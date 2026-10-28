import '../enums.dart';
import '../tokens/box_color.dart';
import '../tokens/box_text_style.dart';
import 'ui_node.dart';

/// A run of text.
///
/// Every typography token this node leaves unset is inherited from the closest
/// enclosing `Box.textStyle`, the way CSS font properties and Flutter's
/// `DefaultTextStyle` are inherited. A text node therefore usually only carries
/// what makes it different.
class TextNode extends UINode {
  /// Creates a text node.
  ///
  /// [headingLevel] has to be between 1 and 6, the levels both HTML and the
  /// platform accessibility trees know.
  const TextNode(
    this.text, {
    super.key,
    this.headingLevel,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.lineHeight,
    this.fontFamily,
    this.letterSpacing,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  }) : assert(
         headingLevel == null || (headingLevel >= 1 && headingLevel <= 6),
         'headingLevel must be between 1 and 6.',
       );

  /// The text content.
  final String text;

  /// The level of the heading this text is, `1` to `6`, or `null` for body text.
  ///
  /// A heading is a text and not a container: it renders as `<h1>`–`<h6>` on the
  /// web and as `Semantics(header: true, headingLevel: level)` in Flutter, so the
  /// two targets state the same level. The element carries no look of its own —
  /// the renderer cancels the user agent's heading styles — so a heading is
  /// typeset by the tree like every other text, and a page that needs an outline
  /// gets it without giving up its typography.
  ///
  /// [BoxRole.heading] is the other spelling, for a heading that is not one run of
  /// text.
  final int? headingLevel;

  /// The font size in logical pixels.
  final double? fontSize;

  /// The weight of the font.
  final FontWeight? fontWeight;

  /// The text color.
  final BoxColor? color;

  /// The line height as a multiple of [fontSize].
  final double? lineHeight;

  /// The font family name, resolved by the host application.
  final String? fontFamily;

  /// Extra space between characters in logical pixels.
  final double? letterSpacing;

  /// The horizontal alignment of the text.
  final TextAlign? textAlign;

  /// The maximum number of lines to display.
  final int? maxLines;

  /// How text that does not fit is truncated.
  final TextOverflow? overflow;

  /// A reusable bundle of typography tokens, overridden by the flat tokens.
  final BoxTextStyle? style;

  /// The typography of this node.
  ///
  /// [style] provides the defaults and every flat token that is set overrides
  /// the matching token. Tokens that stay `null` are inherited by the renderer.
  BoxTextStyle get computedStyle => (style ?? const BoxTextStyle()).merge(
    BoxTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      lineHeight: lineHeight,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
    ),
  );

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'text';
}
