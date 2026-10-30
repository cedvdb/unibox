import 'package:unibox_core/unibox_core.dart';

import 'material_check_mark.dart';
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
/// choice is on. The check is a [MaterialCheckMark] — drawn from boxes, because a font
/// is a host asset and this package ships none. Pass `showSelectedIcon: false` for a
/// control whose fill is enough, and the icon stays where it is.
///
/// **What Material draws that this does not.** The container announces no
/// `radiogroup`: a radio promises arrow keys between the choices and a single tab stop
/// for the set, and a box activates with `Enter` and `Space` alone — on both targets,
/// which is why `BoxRole` has no radio either. Each segment is a toggle button that
/// says whether it is pressed (`aria-pressed`, Flutter's `toggled`), which is true of
/// the control without promising behaviour the model cannot keep. A disabled control
/// fades as one (38%), rather than drawing `onSurface` at 12% under a 38% label, which
/// the model cannot say without an alpha role per token.
final class MaterialSegmentedButton extends Box {
  /// Creates a segmented button with [segments], [selected] of them chosen.
  ///
  /// The measurements are parameters: [height] and [borderRadius] the pill, [padding]
  /// the room around each segment's content, [iconGap] the space between a segment's
  /// icon and its label, and [labelStyle] the type — the state still owns the colour.
  MaterialSegmentedButton({
    required List<MaterialSegment> segments,
    required int selected,
    required void Function(int index) onSelect,
    bool enabled = true,
    bool showSelectedIcon = true,
    double height = controlHeight,
    double borderRadius = radius,
    BoxSpacing padding = _segmentPadding,
    double iconGap = _iconGap,
    BoxTextStyle labelStyle = MaterialTypography.labelLarge,
    // A width shares the segments equally; without one each hugs its label, because a
    // `flex` in an unbounded row is a layout error in Flutter.
    super.width,
    super.margin,
    BoxTransition? transition,
    super.key,
  }) : super(
         height: height,
         // A disabled segmented button fades as one control rather than greying each
         // segment: Material draws the label at 38%, and one opacity is what this
         // model can say without an alpha role per token.
         opacity: enabled ? null : 0.38,
         borderRadius: borderRadius,
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
               equal: width != null,
               height: height,
               padding: padding,
               iconGap: iconGap,
               labelStyle: labelStyle,
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

  /// The room Material gives a segment's content: 12 across, which is what an icon
  /// and a label are inset by on each side of a segment.
  static const BoxSpacing _segmentPadding = BoxSpacing.symmetric(
    horizontal: 12,
  );

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
    required bool equal,
    required double height,
    required BoxSpacing padding,
    required double iconGap,
    required BoxTextStyle labelStyle,
    required BoxTransition? transition,
    required TapCallback onTap,
  }) {
    final BoxColor foreground = _foregroundOf(selected);
    // Material puts the check of the chosen segment *in place of* its icon, so a
    // control that carries pictures still says which one is chosen. The mark is drawn
    // from boxes ([MaterialCheckMark]): a glyph from a font is a host asset, and this
    // package ships none.
    final UINode? leading = selected && showSelectedIcon
        ? MaterialCheckMark(color: foreground, size: iconSize)
        : segment.icon;

    return Box(
      // Equal shares when the button was given a width: Material gives every segment
      // the same share, so the control reads as a scale rather than as buttons of
      // different weight. Without a width there is nothing to divide — and a `flex` in
      // an unbounded row is a layout error in Flutter — so a segment hugs its label.
      flex: equal ? 1 : null,
      backgroundColor: selected ? _selectedFill : null,
      children: <UINode>[
        MaterialInkWell(
          onTap: onTap,
          enabled: enabled,
          ink: foreground,
          // A height, not an infinity: the segment is already as tall as the control,
          // and an infinite height inside a column is a constraint Flutter refuses.
          width: double.infinity,
          height: height,
          mainAlign: MainAlign.center,
          transition: transition ?? MaterialInkWell.defaultTransition,
          semantics: BoxSemantics(
            role: BoxRole.button,
            label: segment.semanticsLabel,
            pressed: selected,
          ),
          child: Box(
            padding: padding,
            mainAlign: MainAlign.center,
            crossAlign: CrossAlign.center,
            width: double.infinity,
            textStyle: labelStyle.merge(BoxTextStyle(color: foreground)),
            children: <UINode>[
              if (leading == null)
                segment.label
              else
                Box(
                  direction: Axis.horizontal,
                  crossAlign: CrossAlign.center,
                  gap: iconGap,
                  children: <UINode>[leading, segment.label],
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
