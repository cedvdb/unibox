import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// A declared icon glyph, drawn by Flutter's native `Icon` substitution.
///
/// Both hosts ship the named font. Flutter hosts register matching const
/// `IconData` values in `materialComponents(icons: ...)` to preserve tree shaking.
final class MaterialIcon extends Box {
  /// Declares a glyph from a font supplied by both hosts.
  MaterialIcon.codePoint(
    this.codePoint, {
    super.key,
    double size = defaultSize,
    BoxColor? color,
    this.fontFamily = defaultFontFamily,
    String? label,
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
           letterSpacing: 0,
           lineHeight: 1,
           color:
               color ?? const BoxColor.role(MaterialColorRole.onSurfaceVariant),
         ),
         children: <UINode>[
           TextNode(String.fromCharCode(codePoint), maxLines: 1),
         ],
       );

  /// The glyph's codepoint in the font shipped by the hosts.
  final int codePoint;

  /// The family containing the glyph.
  final String fontFamily;

  /// The standard icon size in logical pixels.
  static const double defaultSize = 24;

  /// The default host-supplied icon family.
  static const String defaultFontFamily = 'Material Symbols Outlined';

  @override
  bool get requiresWidgetSubstitution => true;

  @override
  String get debugLabel => 'material-icon';
}
