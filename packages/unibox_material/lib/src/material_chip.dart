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
/// The height is Material's 32: `labelLarge`'s 20 pixel line with six above and below.
/// Selected, the chip fills with `secondaryContainer` and drops its line — no border,
/// because the fill is the state — and a leading check is drawn when [leading] is
/// given; unselected it is a `surface` fill with an `outline` line and the quieter
/// `onSurfaceVariant` label.
///
/// A chip is a control, so it announces itself as a button when it can be pressed,
/// and says whether it is chosen: `selected` is the pressed state a screen reader
/// hears, not a colour.
///
/// **What it can carry.** [leading] is a node before the label — where Material puts a
/// check on a chosen filter chip — and `trailing` is one after it. [onRemove] adds the
/// close of an input chip: a round 18 pixel target of its own inside the pill, so a
/// press on the cross removes the chip instead of choosing it, and the cross itself is
/// [trailing] — a glyph the application draws or writes, because a font is a host
/// asset.
final class MaterialChip extends Box {
  /// Creates a chip around [label].
  MaterialChip({
    required UINode label,
    bool selected = false,
    UINode? leading,
    TapCallback? onTap,
    UINode? trailing,
    TapCallback? onRemove,
    bool enabled = true,
    BoxColor? ink,
    super.margin,
    BoxTransition? transition,
    super.key,
  }) : super(
         backgroundColor: selected ? _selectedFill : null,
         border: selected ? null : _outline,
         borderRadius: radius,
         children: <UINode>[
           MaterialInkWell(
             onTap: onTap,
             enabled: enabled,
             borderRadius: radius,
             ink: ink ?? _inkOf(selected),
             padding: BoxSpacing.symmetric(
               horizontal: leading == null ? 16 : 8,
               vertical: 6,
             ),
             transition: transition ?? MaterialInkWell.defaultTransition,
             semantics: onTap == null
                 ? null
                 : BoxSemantics(role: BoxRole.button, selected: selected),
             child: _content(
               label: label,
               leading: leading,
               selected: selected,
               trailing: onRemove == null ? trailing : null,
               remove: onRemove == null
                   ? null
                   : _removeAffordance(
                       glyph: trailing,
                       onRemove: onRemove,
                       enabled: enabled,
                       selected: selected,
                     ),
             ),
           ),
         ],
       );

  /// The corner radius Material gives a chip.
  static const double radius = 8;

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
    required bool selected,
  }) {
    final BoxTextStyle style = MaterialTypography.labelLarge.merge(
      BoxTextStyle(color: _inkOf(selected)),
    );
    final UINode text = Box(textStyle: style, children: <UINode>[label]);
    final UINode? after = remove ?? trailing;

    if (leading == null && after == null) {
      return text;
    }

    return Box(
      direction: Axis.horizontal,
      crossAlign: CrossAlign.center,
      gap: 8,
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
  static UINode _removeAffordance({
    required UINode? glyph,
    required TapCallback onRemove,
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
      semantics: const BoxSemantics(role: BoxRole.button, label: 'Remove'),
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
