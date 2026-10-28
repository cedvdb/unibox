import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';
import 'material_typography.dart';

/// A Material 3 list tile: a row with an optional leading node, a title and a
/// subtitle, and an optional trailing node, drawn as a [Box].
///
/// ```dart
/// MaterialListTile(
///   leading: const TextNode('AL'),
///   title: const TextNode('Ada Lovelace'),
///   subtitle: const TextNode('ada@example.com'),
///   trailing: const TextNode('2m'),
///   onTap: openContact,
/// );
/// ```
///
/// It adds no renderer work: it *is* a box, so both targets draw it with the
/// renderer they already have, and every token it sets is one the conformance
/// table already pins. What the class buys is the combination — a row that fills
/// its width, 16 logical pixels between its parts, 16 of horizontal padding, a
/// minimum height that follows Material's one and two line sizes, `bodyLarge` for
/// the title, `bodyMedium` in a muted colour for the subtitle, and the button role
/// when the tile can be tapped.
///
/// **What it is not.** It is not a colour scheme: Material draws a subtitle in
/// `onSurfaceVariant` and tints a hovered tile with `onSurface` at 8%, and the
/// model has no scheme yet, so [subtitleColor] is the baseline light value written
/// out and the state tints are black at the same opacities. A dark theme passes
/// `color`, `subtitleStyle` and its own state styles. It is not a ripple either: a
/// press is a state style, the same as on any other control, and the ink splash is
/// the animation system this package does not have.
///
/// **The escape hatch is a [Box].** The tile states its arrangement, its padding,
/// its type and its interaction; anything else — a size bound, a border, a
/// transition — is a parameter or a plain box around it.
final class MaterialListTile extends Box {
  /// Creates a list tile around [title].
  ///
  /// Every default is a parameter: the padding, the gap, the title and subtitle
  /// styles, the minimum height and the state tints are the tile's own tokens, so
  /// an application can theme them without giving up the tile.
  ///
  /// `onTap` is read here instead of being passed straight through, because a
  /// tappable tile is what gets the button role.
  // ignore: use_super_parameters
  MaterialListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.dense = false,
    TapCallback? onTap,
    super.onLongPress,
    super.onHover,
    super.enabled,
    super.transition,
    super.margin,
    super.textStyle,
    BoxSemantics? semantics,
    BoxColor? color,
    double? width,
    BoxSpacing padding = _padding,
    double gap = _gap,
    BoxTextStyle? titleStyle,
    BoxTextStyle? subtitleStyle,
    BoxStyle? hoverStyle,
    Map<BoxState, BoxStyle>? stateStyles,
    double? minHeight,
  }) : super(
         direction: Axis.horizontal,
         crossAlign: CrossAlign.center,
         width: width ?? double.infinity,
         gap: gap,
         padding: padding,
         backgroundColor: color,
         minHeight:
             minHeight ?? _minHeightFor(dense, hasSubtitle: subtitle != null),
         onTap: onTap,
         semantics: semantics ?? _roleFor(onTap),
         hoverStyle:
             hoverStyle ??
             BoxStyle(
               backgroundColor: const BoxColor.role(
                 MaterialColorRole.hoverLayer,
               ),
             ),
         stateStyles:
             stateStyles ??
             <BoxState, BoxStyle>{
               BoxState.focus: BoxStyle(
                 backgroundColor: const BoxColor.role(
                   MaterialColorRole.focusLayer,
                 ),
               ),
               BoxState.pressed: BoxStyle(
                 backgroundColor: const BoxColor.role(
                   MaterialColorRole.pressedLayer,
                 ),
               ),
             },
         children: <UINode>[
           ?leading,
           Box(
             direction: Axis.vertical,
             flex: 1,
             gap: _textGap,
             textStyle:
                 titleStyle ??
                 MaterialTypography.bodyLarge.merge(
                   BoxTextStyle(
                     color: const BoxColor.role(MaterialColorRole.onSurface),
                   ),
                 ),
             children: <UINode>[
               title,
               if (subtitle != null)
                 Box(
                   textStyle:
                       subtitleStyle ??
                       MaterialTypography.bodyMedium.merge(
                         BoxTextStyle(
                           color: const BoxColor.role(
                             MaterialColorRole.onSurfaceVariant,
                           ),
                         ),
                       ),
                   children: <UINode>[subtitle],
                 ),
             ],
           ),
           ?trailing,
         ],
       );

  /// The main line of the tile.
  final UINode title;

  /// The supporting line under [title], drawn in the tile's subtitle style.
  final UINode? subtitle;

  /// The node before the text: an avatar, an icon, a colour.
  final UINode? leading;

  /// The node after the text: a value, a chevron, a switch.
  final UINode? trailing;

  /// Whether the tile takes the compact height Material calls dense.
  ///
  /// It only changes the minimum height; a dense tile keeps its padding, its gap
  /// and its type, which is what Material's density setting does.
  final bool dense;

  /// The muted colour Material draws a subtitle in: `onSurfaceVariant` of the
  /// baseline light scheme.
  ///
  /// It is the same value [MaterialPalette.light] states for `onSurfaceVariant`,
  /// written out so a tile needs no palette to look like Material; a themed
  /// application passes `subtitleStyle` with the role it wants instead.
  static const BoxColor subtitleColor = BoxColor.role(
    MaterialColorRole.onSurfaceVariant,
  );

  /// The typography of a subtitle: `bodyMedium` in [subtitleColor].
  ///
  /// Material gives a subtitle the body size and a muted colour, and the two move
  /// together, so the tile states them as one value. A test holds the size, the
  /// weight, the line height and the letter spacing to
  /// [MaterialTypography.bodyMedium], so the two cannot drift.
  static const BoxTextStyle subtitleTextStyle = BoxTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    lineHeight: 20 / 14,
    letterSpacing: 0.25,
    color: subtitleColor,
  );

  /// The padding Material puts around a tile.
  static const BoxSpacing _padding = BoxSpacing.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  /// The space Material keeps between the leading node, the text and the
  /// trailing node.
  static const double _gap = 16;

  /// The space between the title and the subtitle.
  static const double _textGap = 2;

  /// The minimum height Material gives a one line tile, a two line tile, and
  /// their dense variants.
  static double _minHeightFor(bool dense, {required bool hasSubtitle}) {
    if (dense) {
      return hasSubtitle ? 64 : 48;
    }
    return hasSubtitle ? 72 : 56;
  }

  /// The role a tile announces, which is a button when it can be tapped.
  ///
  /// A tile that does nothing is a plain row, and saying "button" about it would
  /// promise a keyboard entry point that does not exist.
  static BoxSemantics? _roleFor(TapCallback? onTap) =>
      onTap == null ? null : const BoxSemantics(role: BoxRole.button);

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'material-list-tile';
}
