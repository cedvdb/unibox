import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// A Material icon: one glyph of an icon font, centred in a square [Box].
///
/// ```dart
/// MaterialIcon.codePoint(Symbols.home.codePoint);   // by codepoint
/// MaterialIcon.ligature('home');                     // by ligature name
/// MaterialIcon.ligature('delete', color: palette.error, label: 'Delete');
/// ```
///
/// An icon is text set in an icon font, so it needs no node of its own and no
/// embed: both renderers already draw a text with a family, a size and a colour,
/// and the glyph follows the same tokens as any other text. That is also why the
/// icon recolours with `color` and scales with `size`, which an image cannot.
///
/// **The font is the host's.** Like any font file it is an asset the model does
/// not carry: declare the family in the application — `fonts:` in the Flutter
/// pubspec, an `@font-face` for the web — and name it with [fontFamily]. A host
/// without the font draws the character of the glyph as plain text.
///
/// **Tree shaking wants codepoints, not ligatures.** Flutter's
/// `--tree-shake-icons` reads const `IconData` instances out of the application
/// and subsets the fonts they name; a ligature name is a string, so nothing is
/// found and the whole font ships. Pass a codepoint that comes from a const
/// `IconData` — `Symbols.home` from `material_symbols_icons`, or a `const
/// IconData(0xe9b2, fontFamily: …)` of your own — and the font is subset to the
/// glyphs the application uses. A web export has no shaker of its own: serve the
/// subset the Flutter build wrote, or one from `pyftsubset`, with its
/// `@font-face`.
///
/// **Accessibility.** An icon beside a text is decoration and is hidden from
/// assistive technology; pass [label] when it stands alone and it is announced
/// instead.
final class MaterialIcon extends Box {
  /// Creates an icon from a [codePoint] of [fontFamily].
  ///
  /// Take [codePoint] from a const `IconData` — that is what the tree shaker
  /// reads, and a literal ships the whole font. `Symbols.home.codePoint`, or a
  /// const list of the symbols an application uses, both work.
  MaterialIcon.codePoint(
    int codePoint, {
    Object? key,
    double size = defaultSize,
    BoxColor? color,
    String fontFamily = defaultFontFamily,
    String? label,
  }) : this._(
         glyph: String.fromCharCode(codePoint),
         key: key,
         size: size,
         color:
             color ?? const BoxColor.role(MaterialColorRole.onSurfaceVariant),
         fontFamily: fontFamily,
         label: label,
       );

  /// Creates an icon from the ligature [name] of a symbol font.
  ///
  /// The convenient form for `Material Symbols`: both a browser and Flutter
  /// substitute the ligature. It is also the form the tree shaker cannot follow,
  /// so the whole font ships; [MaterialIcon.codePoint] is the small one.
  MaterialIcon.ligature(
    String name, {
    Object? key,
    double size = defaultSize,
    BoxColor? color,
    String fontFamily = defaultFontFamily,
    String? label,
  }) : this._(
         glyph: name,
         key: key,
         size: size,
         color:
             color ?? const BoxColor.role(MaterialColorRole.onSurfaceVariant),
         fontFamily: fontFamily,
         label: label,
       );

  MaterialIcon._({
    required String glyph,
    required super.key,
    required double size,
    required BoxColor color,
    required String fontFamily,
    required String? label,
  }) : super(
         width: size,
         height: size,
         mainAlign: MainAlign.center,
         crossAlign: CrossAlign.center,
         semantics: BoxSemantics(label: label, hidden: label == null),
         textStyle: BoxTextStyle(
           fontFamily: fontFamily,
           fontSize: size,
           fontWeight: FontWeight.normal,
           lineHeight: 1,
           letterSpacing: 0,
           color: color,
         ),
         children: <UINode>[TextNode(glyph, maxLines: 1)],
       );

  /// The size Material draws an icon at: 24 logical pixels.
  static const double defaultSize = 24;

  /// The family the Material Symbols font is declared under.
  static const String defaultFontFamily = 'Material Symbols Outlined';

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'material-icon';
}
