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
/// **What Material draws that this does not.** A chosen segment shows a check beside
/// its label, which needs a glyph from a font the package does not ship — a segment
/// takes an [MaterialSegment.icon] instead, and the fill states the choice on its
/// own. The container also announces no `radiogroup`: `BoxSemantics` has no group
/// role, so each segment is a button that says whether it is the chosen one.
final class MaterialSegmentedButton extends Box {
  /// Creates a segmented button with [segments], [selected] of them chosen.
  MaterialSegmentedButton({
    required List<MaterialSegment> segments,
    required int selected,
    required void Function(int index) onSelect,
    bool enabled = true,
    super.margin,
    BoxTransition? transition,
    super.key,
  }) : super(
         height: controlHeight,
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

  /// The line around the container, and between its segments.
  static const BoxBorder _outline = BoxBorder(
    color: BoxColor.role(MaterialColorRole.outline),
  );

  /// One segment: the fill, and a well over it that covers the whole segment.
  static UINode _segment({
    required MaterialSegment segment,
    required bool selected,
    required bool enabled,
    required BoxTransition? transition,
    required TapCallback onTap,
  }) {
    final BoxColor foreground = _foregroundOf(selected);

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
              if (segment.icon == null)
                segment.label
              else
                Box(
                  direction: Axis.horizontal,
                  crossAlign: CrossAlign.center,
                  gap: 8,
                  children: <UINode>[segment.icon!, segment.label],
                ),
            ],
          ),
        ),
      ],
    );
  }

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
