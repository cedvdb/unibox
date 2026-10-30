import 'package:unibox_core/unibox_core.dart';

import 'material_ink_well.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// A Material 3 filter chip: a label in a pill, selected or not.
///
/// ```dart
/// MaterialChip(label: const TextNode('Two rooms'), selected: true, onTap: filter)
/// MaterialChip(label: const TextNode('Studio'), onTap: filter)
/// ```
///
/// It is a [Box] around a [MaterialInkWell], like [MaterialButton]: the fill and the
/// line are the box's, the hover, focus and press tints are the well's, and the ink a
/// press leaves is clipped to the pill. **The padding is the well's alone** — one node
/// carries the room inside the chip, so the tint reaches exactly the edge of the pill
/// it belongs to. Two paddings, one on each, is what made the example's chips tint far
/// beyond themselves when they were composed by hand.
///
/// The height it *paints* is Material's 32: `labelLarge`'s 20 pixel line with six above
/// and below. The region a finger hits is 48, because Material states one target for a
/// touch screen and a 32 pixel chip is below it: the pill is centred in a target of
/// [minTapTarget], which is the size the chip takes in a row.
/// Selected, the chip fills with `secondaryContainer` and drops its line — no border,
/// because the fill is the state — and a leading check is drawn when [leading] is
/// given; unselected it has an `outline` line and the quieter `onSurfaceVariant` label.
///
/// A chip is a control, so it announces itself as a button when it can be pressed,
/// and says whether it is on: `pressed` is the state a screen reader hears — "pressed"
/// or "not pressed", `aria-pressed` in a browser — and not a colour.
///
/// **What it can carry.** [leading] is a node before the label — where Material puts a
/// check on a chosen filter chip — and `trailing` is one after it. [onRemove] adds the
/// close of an input chip: a round 18 pixel target of its own inside the pill, so a
/// press on the cross removes the chip instead of choosing it, and the cross itself is
/// [trailing] — a glyph the application draws or writes, because a font is a host
/// asset. [removeSemanticsLabel] is what that target announces: a row of applied
/// filters should say which one it removes, because eleven chips that all say "Remove"
/// tell a reader nothing about what is about to go.
final class MaterialChip extends Box {
  /// Creates a chip around [label].
  ///
  /// Every measurement Material gives a chip is a parameter, so an application can
  /// tighten a row of chips without giving up the component: [padding] is the room
  /// inside the pill, [height] the pill it paints (32 unless it says otherwise),
  /// [tapTargetHeight] the room a finger gets around it (48), [gap] the space
  /// between a node and the label, and [borderRadius] the corner. [labelStyle] and
  /// [ink] are the type and the splash. [removeSemanticsLabel] is the name of the
  /// chip's own close, which defaults to "Remove".
  MaterialChip({
    required UINode label,
    bool selected = false,
    UINode? leading,
    TapCallback? onTap,
    HoverCallback? onHover,
    UINode? trailing,
    TapCallback? onRemove,
    String? removeSemanticsLabel,
    bool enabled = true,
    BoxColor? ink,
    double height = controlHeight,
    double tapTargetHeight = minTapTarget,
    double borderRadius = radius,
    double gap = _nodeGap,
    BoxSpacing? padding,
    BoxTextStyle? labelStyle,
    super.margin,
    BoxTransition? transition,
    super.key,
  }) : super(
         borderRadius: borderRadius,
         // The shape is the well's now, because the target is taller than it: the chip
         // is as tall as the finger it is aimed at, and paints the 32 pixel pill in the
         // middle of that.
         minHeight: tapTargetHeight,
         mainAlign: MainAlign.center,
         // A disabled chip fades rather than changing role: Material draws the label at
         // 38% and the line at 12%, and one opacity is what this model can say without
         // an alpha role per token.
         opacity: enabled ? null : 0.38,
         children: <UINode>[
           MaterialInkWell(
             onTap: onTap,
             onHover: onHover,
             enabled: enabled,
             // Material's 32: `labelLarge`'s 20 pixel line with six above and below,
             // held even when a leading or trailing glyph is taller than the line it
             // sits on. The 48 around it is the target, which is not paint: a chip
             // that painted 48 would be a chip Material does not have.
             height: height,
             tapTargetHeight: tapTargetHeight,
             // A taller pill than the default still reads: the content is centred in
             // it rather than pinned to its top.
             mainAlign: MainAlign.center,
             fill: selected ? _selectedFill : null,
             border: selected ? null : _outline,
             borderRadius: borderRadius,
             ink: ink ?? _inkOf(selected),
             // Material pads only the side a node sits on: 16 where the label meets
             // the edge, 8 where an 18 pixel glyph does, 8 between them.
             padding:
                 padding ??
                 _insetsFor(
                   leading: leading,
                   trailing: trailing,
                   hasRemove: onRemove != null,
                 ),
             transition: transition ?? MaterialInkWell.defaultTransition,
             semantics: onTap == null
                 ? null
                 : BoxSemantics(role: BoxRole.button, pressed: selected),
             child: _content(
               label: label,
               leading: leading,
               gap: gap,
               labelStyle: labelStyle,
               selected: selected,
               trailing: onRemove == null ? trailing : null,
               remove: onRemove == null
                   ? null
                   : _removeAffordance(
                       glyph: trailing,
                       onRemove: onRemove,
                       label: removeSemanticsLabel ?? _removeLabel,
                       enabled: enabled,
                       selected: selected,
                     ),
             ),
           ),
         ],
       );

  /// The corner radius Material gives a chip.
  static const double radius = 8;

  /// The height Material gives a chip, whatever it carries.
  static const double controlHeight = 32;

  /// The height of the region a finger has to hit.
  ///
  /// Material states 48 for a touch target and a chip paints 32, so the two numbers
  /// differ on purpose: the pill is centred in a target this tall (see
  /// `MaterialInkWell.tapTargetHeight`). It is layout and not paint, which means a row
  /// of chips is 48 tall — the same thing Flutter's padded tap target does.
  static const double minTapTarget = 48;

  /// How far a node inside a chip sits from the edge of the pill, and from the label.
  ///
  /// Material's chip spec: an icon is 18 logical pixels, 8 from the edge and 8 from
  /// the label, so a chip with a node pads by this on that side and by 16 on the side
  /// where the label reaches the edge.
  static const double _nodeInset = 8;

  /// How far the label sits from the edge of a pill with no node on that side.
  static const double _labelInset = 16;

  /// The space between a node and the label when the chip is not told otherwise.
  static const double _nodeGap = 8;

  /// What the close of a chip announces when the caller does not name it.
  ///
  /// It is the whole of what the cross means on its own. A chip that removes one of
  /// several filters should pass [removeSemanticsLabel] instead, so a reader hears which
  /// one.
  static const String _removeLabel = 'Remove';

  /// The room inside the pill: Material pads only the sides a node sits on.
  ///
  /// Six above and below is `labelLarge`'s 20 pixel line plus twelve inside the 32
  /// pixel pill, which is what makes the default height and this room agree.
  static BoxSpacing _insetsFor({
    required UINode? leading,
    required UINode? trailing,
    required bool hasRemove,
  }) => BoxSpacing.only(
    left: leading == null ? _labelInset : _nodeInset,
    right: (trailing == null && !hasRemove) ? _labelInset : _nodeInset,
    top: 6,
    bottom: 6,
  );

  /// The size Material gives the node inside a chip.
  static const double iconSize = 18;

  /// The fill of a chosen chip.
  static const BoxColor _selectedFill = BoxColor.role(
    MaterialColorRole.secondaryContainer,
  );

  /// The line around a chip that is not chosen.
  static const BoxBorder _outline = BoxBorder(
    color: BoxColor.role(MaterialColorRole.outline),
  );

  /// The label, with its leading node beside it when there is one.
  ///
  /// The role and the colour are stated once on the box around the text, because
  /// typography is the one thing a box passes down.
  static UINode _content({
    required UINode label,
    required UINode? leading,
    required UINode? remove,
    required UINode? trailing,
    required double gap,
    required BoxTextStyle? labelStyle,
    required bool selected,
  }) {
    final BoxTextStyle style = (labelStyle ?? MaterialTypography.labelLarge)
        .merge(BoxTextStyle(color: _inkOf(selected)));
    final UINode text = Box(textStyle: style, children: <UINode>[label]);
    final UINode? after = remove ?? trailing;

    if (leading == null && after == null) {
      return text;
    }

    return Box(
      direction: Axis.horizontal,
      crossAlign: CrossAlign.center,
      gap: gap,
      textStyle: style,
      children: <UINode>[?leading, label, ?after],
    );
  }

  /// The close of an input chip: [glyph] in a round well of its own.
  ///
  /// Its own well matters twice. It is a second target — a press on the cross removes
  /// the chip and must not also press it — and it gets the state layer of a control
  /// rather than the label's. The glyph is the caller's: a font is a host asset, and
  /// this package ships none, so a cross is drawn or given as text by the application.
  ///
  /// The glyph is centred on **both** axes, which a well has to say: it is a column, and
  /// a cross without `crossAlign` was pinned to the start of the target, so the ring a
  /// hover drew around it sat four pixels off the cross it belongs to.
  ///
  /// [label] is what the target says to a screen reader: a control that is a cross has no
  /// text of its own, so without a name it is announced as a button and nothing more.
  static UINode _removeAffordance({
    required UINode? glyph,
    required TapCallback onRemove,
    required String label,
    required bool enabled,
    required bool selected,
  }) {
    return MaterialInkWell(
      onTap: onRemove,
      enabled: enabled,
      borderRadius: 9,
      ink: _inkOf(selected),
      width: 18,
      height: 18,
      mainAlign: MainAlign.center,
      crossAlign: CrossAlign.center,
      semantics: BoxSemantics(role: BoxRole.button, label: label),
      child: Box(
        mainAlign: MainAlign.center,
        crossAlign: CrossAlign.center,
        width: double.infinity,
        children: <UINode>[?glyph],
      ),
    );
  }

  /// The colour the label is drawn in, and the ink a press leaves.
  static BoxColor _inkOf(bool selected) => selected
      ? const BoxColor.role(MaterialColorRole.onSecondaryContainer)
      : const BoxColor.role(MaterialColorRole.onSurfaceVariant);

  /// The name this node answers to in an inspector.
  @override
  String? get debugLabel => 'material-chip';
}
