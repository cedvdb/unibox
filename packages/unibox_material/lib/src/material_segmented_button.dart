import 'package:unibox_core/unibox_core.dart';

import 'material_ink_well.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// One choice of a [MaterialSegmentedButton]: a label, and optionally an icon.
final class MaterialSegment {
  /// Creates a segment around [label].
  const MaterialSegment({required this.label, this.icon, this.semanticsLabel});

  /// What the segment says.
  final UINode label;

  /// The glyph beside the label, when the choice is easier to read as a picture.
  final UINode? icon;

  /// What a screen reader calls the segment, when the label is not enough.
  final String? semanticsLabel;
}

/// A Material 3 segmented button: two to five choices in one divided pill.
///
/// ```dart
/// MaterialSegmentedButton(
///   segments: const <MaterialSegment>[
///     MaterialSegment(label: TextNode('Day')),
///     MaterialSegment(label: TextNode('Week')),
///     MaterialSegment(label: TextNode('Month')),
///   ],
///   selected: 1,
///   onSelect: (int index) => period = index,
/// )
/// ```
///
/// The container is one box: 40 pixels tall, fully rounded, a 1 pixel `outline`
/// line, and `overflow: hidden` so the chosen segment's fill is cut to the rounded
/// ends it reaches rather than needing a radius of its own. Each segment is a box
/// with an equal share (`flex: 1`) around a [MaterialInkWell], so the tint and the
/// ink cover the segment and not just its label; a 1 pixel rule between them is a
/// box the colour of the outline.
///
/// **The chosen segment shows a check**, in place of the icon it would otherwise draw
/// — Material's own behaviour, so a control that carries pictures still says which
/// choice is on. The check is drawn from boxes ([_check]): an icon font is a host
/// asset, and this package ships none. Pass `showSelectedIcon: false` for a control
/// whose fill is enough, and the icon stays where it is.
///
/// **What Material draws that this does not.** The container announces no
/// `radiogroup`: `BoxSemantics` has no group role, so each segment is a button that
/// says whether it is the chosen one. A disabled control fades as one (38%), rather
/// than drawing `onSurface` at 12% under a 38% label, which the model cannot say
/// without an alpha role per token.
final class MaterialSegmentedButton extends Box {
  /// Creates a segmented button with [segments], [selected] of them chosen.
  MaterialSegmentedButton({
    required List<MaterialSegment> segments,
    required int selected,
    required void Function(int index) onSelect,
    bool enabled = true,
    bool showSelectedIcon = true,
    super.margin,
    BoxTransition? transition,
    super.key,
  }) : super(
         height: controlHeight,
         // A disabled segmented button fades as one control rather than greying each
         // segment: Material draws the label at 38%, and one opacity is what this
         // model can say without an alpha role per token.
         opacity: enabled ? null : 0.38,
         borderRadius: radius,
         border: _outline,
         overflow: Overflow.hidden,
         direction: Axis.horizontal,
         crossAlign: CrossAlign.stretch,
         children: <UINode>[
           for (int i = 0; i < segments.length; i++) ...<UINode>[
             if (i > 0) _divider(),
             _segment(
               segment: segments[i],
               selected: i == selected,
               enabled: enabled,
               showSelectedIcon: showSelectedIcon,
               transition: transition,
               onTap: () => onSelect(i),
             ),
           ],
         ],
       );

  /// The height Material gives a segmented button.
  static const double controlHeight = 40;

  /// The corner radius, which is a full round at [controlHeight].
  static const double radius = 20;

  /// The size Material gives the icon of a segment, and the check of a chosen one.
  static const double iconSize = 18;

  /// The space between that icon and the label.
  static const double _iconGap = 8;

  /// The line around the container, and between its segments.
  static const BoxBorder _outline = BoxBorder(
    color: BoxColor.role(MaterialColorRole.outline),
  );

  /// One segment: the fill, and a well over it that covers the whole segment.
  static UINode _segment({
    required MaterialSegment segment,
    required bool selected,
    required bool enabled,
    required bool showSelectedIcon,
    required BoxTransition? transition,
    required TapCallback onTap,
  }) {
    final BoxColor foreground = _foregroundOf(selected);
    // Material puts the check of the chosen segment *in place of* its icon, so a
    // control that carries pictures still says which one is chosen. It is drawn from
    // boxes: a glyph from a font is a host asset, and this package ships none.
    final UINode? leading = selected && showSelectedIcon
        ? _check(foreground)
        : segment.icon;

    return Box(
      // Equal shares: Material gives every segment the same width, so the control
      // reads as a scale rather than as three buttons of different weight.
      flex: 1,
      backgroundColor: selected ? _selectedFill : null,
      children: <UINode>[
        MaterialInkWell(
          onTap: onTap,
          enabled: enabled,
          ink: foreground,
          width: double.infinity,
          height: double.infinity,
          mainAlign: MainAlign.center,
          transition: transition ?? MaterialInkWell.defaultTransition,
          semantics: BoxSemantics(
            role: BoxRole.button,
            label: segment.semanticsLabel,
            selected: selected,
          ),
          child: Box(
            padding: const BoxSpacing.symmetric(horizontal: 12),
            mainAlign: MainAlign.center,
            crossAlign: CrossAlign.center,
            width: double.infinity,
            textStyle: MaterialTypography.labelLarge.merge(
              BoxTextStyle(color: foreground),
            ),
            children: <UINode>[
              if (leading == null)
                segment.label
              else
                Box(
                  direction: Axis.horizontal,
                  crossAlign: CrossAlign.center,
                  gap: _iconGap,
                  children: <UINode>[leading, segment.label],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The check of a chosen segment: the two strokes of a tick, drawn as rotated
  /// bars, so a control that has to say which choice is active needs no font.
  static UINode _check(BoxColor color) {
    const double size = iconSize;
    final double stroke = size / 7;

    return StackNode(
      width: size,
      height: size,
      children: <UINode>[
        // The short stroke: from the middle down to the corner.
        _centred(
          Box(
            width: size * 0.45,
            height: stroke,
            borderRadius: stroke / 2,
            backgroundColor: color,
            transform: BoxTransform(rotation: 45, offsetX: -size * 0.22),
          ),
        ),
        // The long stroke: up to the top right.
        _centred(
          Box(
            width: size * 0.8,
            height: stroke,
            borderRadius: stroke / 2,
            backgroundColor: color,
            transform: BoxTransform(rotation: -45, offsetX: size * 0.12),
          ),
        ),
      ],
    );
  }

  /// [child] in the middle of the box that holds it.
  static UINode _centred(UINode child) =>
      PositionedNode(alignment: BoxAlignment.center, child: child);

  /// The rule between two segments: a hairline the colour of the outline.
  static UINode _divider() => Box(
    width: 1,
    backgroundColor: const BoxColor.role(MaterialColorRole.outline),
  );

  /// The fill of a chosen segment.
  static const BoxColor _selectedFill = BoxColor.role(
    MaterialColorRole.secondaryContainer,
  );

  /// The colour a segment's label is drawn in, and the ink a press leaves.
  static BoxColor _foregroundOf(bool selected) => selected
      ? const BoxColor.role(MaterialColorRole.onSecondaryContainer)
      : const BoxColor.role(MaterialColorRole.onSurface);

  /// The name this node answers to in an inspector.
  @override
  String? get debugLabel => 'material-segmented-button';
}
