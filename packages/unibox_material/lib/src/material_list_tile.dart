import 'package:unibox_core/unibox_core.dart';

import 'material_ink_well.dart';
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
/// **The ripple is the ink well.** The row is wrapped in a [MaterialInkWell], so a
/// tile inks where the press landed and tints on hover and focus exactly like every
/// other Material surface, and the tile adds no second implementation of either. The
/// row itself is [row], which is what a test or a reader inspects: the parts, before
/// they are wrapped.
///
/// **The corners are the caller's.** A tile that fills a rounded surface has to be
/// clipped to it, or its tint squares off the corners; either the container declares
/// `overflow: Overflow.hidden` — what a Material container does for its children — or
/// the tile is given the same [borderRadius] as the surface it fills, which clips its
/// own tint and its ink. Two tiles stacked in one container want the first, because
/// only the outer corners are round.
///
/// **What it is not.** It is not a colour scheme: every colour is a
/// [MaterialColorRole] resolved by the theme the host renders with.
///
/// **The escape hatch is a [Box].** The tile states its arrangement, its padding,
/// its type and its interaction; anything else — a size bound, a border, a
/// transition — is a parameter or a plain box around it.
final class MaterialListTile extends Box {
  /// Creates a list tile around [title].
  ///
  /// Every default is a parameter: the padding, the gap, the title and subtitle
  /// styles, the minimum height and the ink are the tile's own tokens, so an
  /// application can theme them without giving up the tile.
  ///
  /// `onTap` is read here instead of being passed straight through, because a
  /// tappable tile is what gets the button role — and the ink.
  factory MaterialListTile({
    Object? key,
    required UINode title,
    UINode? subtitle,
    UINode? leading,
    UINode? trailing,
    bool dense = false,
    TapCallback? onTap,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    BoxTransition? transition,
    BoxSpacing? margin,
    BoxTextStyle? textStyle,
    BoxSemantics? semantics,
    BoxColor? color,
    double? width,
    BoxSpacing padding = _padding,
    double gap = _gap,
    BoxTextStyle? titleStyle,
    BoxTextStyle? subtitleStyle,
    BoxColor ink = MaterialInkWell.defaultInk,
    double? borderRadius,
    double? minHeight,
    BoxStyle? hoverStyle,
    BoxStyle? focusStyle,
    BoxStyle? pressedStyle,
  }) {
    final Box row = Box(
      direction: Axis.horizontal,
      crossAlign: CrossAlign.center,
      gap: gap,
      padding: padding,
      minHeight:
          minHeight ?? _minHeightFor(dense, hasSubtitle: subtitle != null),
      textStyle: textStyle,
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
                textStyle: subtitleStyle ?? subtitleTextStyle,
                children: <UINode>[subtitle],
              ),
          ],
        ),
        ?trailing,
      ],
    );

    return MaterialListTile._(
      key: key,
      row: row,
      color: color,
      width: width,
      margin: margin,
      inkWell: MaterialInkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onHover: onHover,
        enabled: enabled,
        width: double.infinity,
        borderRadius: borderRadius,
        ink: ink,
        transition: transition ?? MaterialInkWell.defaultTransition,
        semantics: semantics ?? _roleFor(onTap),
        hoverStyle: hoverStyle,
        focusStyle: focusStyle,
        pressedStyle: pressedStyle,
        child: row,
      ),
    );
  }

  MaterialListTile._({
    super.key,
    super.margin,
    required this.row,
    required UINode inkWell,
    BoxColor? color,
    double? width,
  }) : super(
         width: width ?? double.infinity,
         backgroundColor: color,
         children: <UINode>[inkWell],
       );

  /// The row of parts, before the ink wraps it: the leading node, the text and the
  /// trailing node, with the tile's padding, gap and minimum height.
  ///
  /// It is public because it is what a reader and a test want to look at; the tile
  /// around it only fills the width and paints the surface.
  final Box row;

  /// The muted colour Material draws a subtitle in: `onSurfaceVariant` of the
  /// baseline light scheme.
  ///
  /// A role, so a dark theme moves it: the tile names it and the host answers.
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
