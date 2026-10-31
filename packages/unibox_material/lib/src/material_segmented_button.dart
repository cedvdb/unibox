import 'package:unibox_core/unibox_core.dart';

import 'material_check_mark.dart';
import 'material_ink_well.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// One choice of a [MaterialSegmentedButton]: a label, and optionally an icon.
final class MaterialSegment {
  /// Creates a segment around [label].
  ///
  /// [url] makes this choice a destination instead of a press, the way a box with a url
  /// is an anchor: a control that switches the list under the reader is a button, and one
  /// that is a place is a link. [newTab] is the web's.
  const MaterialSegment({
    required this.label,
    this.icon,
    this.semanticsLabel,
    this.url,
    this.newTab = false,
  });

  /// What the segment says.
  final UINode label;

  /// The glyph beside the label, when the choice is easier to read as a picture.
  final UINode? icon;

  /// What a screen reader calls the segment, when the label is not enough.
  final String? semanticsLabel;

  /// Where this choice leads, when it is a destination rather than a press.
  ///
  /// A segment with a url does not call the control's `onSelect`: the press belongs to
  /// the browser (and, in Flutter, to the host's link scope). The chosen one is then the
  /// page the reader is on — not a link to itself — and says so with `aria-current`.
  final String? url;

  /// Whether [url] opens in a new tab, on the web.
  final bool newTab;
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
/// around a [MaterialInkWell], so the tint and the ink cover the segment and not just
/// its label; the 1 pixel rule between two segments is a box the colour of the outline,
/// layered over the segment it opens.
///
/// **The columns are equal.** A segment is a column of the control and never a width of
/// its own: the control measures its widest segment — the label, the icon beside it and the
/// padding around both — and every segment is that wide, so a control of "Rent" beside
/// "Rent to buy" is two equal halves rather than a button beside a bigger one. That is
/// what Material's own `SegmentedButton` does, and it is the tree's own rule: the pill is a
/// [Box] around a [GridNode] that states one column per segment. With no width the pill
/// hugs its columns — a row that scrolls gets a control exactly as wide as its content,
/// and the widest label sets the width of every segment — and a width divides that width
/// equally instead, which is what a pill stretched across a cell wants. A column that the
/// room does not stretch to cuts its label (see below) rather than widening the pill.
///
/// **The line is the caller's.** [border] is the container's line *and* the rules
/// between its segments — one hairline the model draws as a box, at the start of every
/// segment but the first — and the default is Material's `outline`, so a theme that draws
/// its segmented control with `outlineVariant` — Material's own `SegmentedButton` does —
/// says so once rather than reaching into this package.
///
/// **The chosen segment shows a check**, in place of the icon it would otherwise draw
/// — Material's own behaviour, so a control that carries pictures still says which
/// choice is on. The check is a [MaterialCheckMark] — drawn from boxes, because a font
/// is a host asset and this package ships none. Pass `showSelectedIcon: false` for a
/// control whose fill is enough, and the icon stays where it is.
///
/// **A segment's label is one line.** A segment is a column of the control's width and not
/// a width of its own, so a label longer than that column — a translation, or any label at
/// a larger text scale — gives way instead of widening the pill or painting over the
/// segment beside it: a text is drawn with `maxLines: 1` and an ellipsis, and any other
/// node is cut at the column. Only a parent too narrow for `count ×` the widest segment
/// reaches it, because the widest label is what set the column every label is given.
///
/// **A set of destinations is a set of links.** Give the segments a [MaterialSegment.url]
/// and the control stops being a set of buttons: each unselected choice is one `<a href>`
/// with the segment's padding and fill, so a crawler reads where the choices lead, a page
/// with no runtime follows them, and the ink still ripples because the anchor is the well.
/// The chosen one is the page the reader is on: it is not a link to itself, it is not in
/// the tab order, and it says `aria-current="page"`. [onSelect] is then not called for a
/// segment that has a url — the destination is the press.
///
/// **What Material draws that this does not.** A set of selecting segments announces no
/// `radiogroup`: a radio promises arrow keys between the choices and a single tab stop
/// for the set, and a box activates with `Enter` and `Space` alone — on both targets,
/// which is why `BoxRole` has no radio either. Each selecting segment is a toggle button
/// that says whether it is pressed (`aria-pressed`, Flutter's `toggled`), which is true of
/// the control without promising behaviour the model cannot keep. A disabled control
/// fades as one (38%), rather than drawing `onSurface` at 12% under a 38% label, which
/// the model cannot say without an alpha role per token.
final class MaterialSegmentedButton extends Box {
  /// Creates a segmented button with [segments], [selected] of them chosen.
  ///
  /// The measurements are parameters: [height] and [borderRadius] the pill, [padding]
  /// the room around each segment's content, [iconGap] the space between a segment's
  /// icon and its label, [border] the line around the pill and between its segments,
  /// and [labelStyle] the type — the state still owns the colour.
  MaterialSegmentedButton({
    required List<MaterialSegment> segments,
    required int selected,
    void Function(int index)? onSelect,
    bool enabled = true,
    bool showSelectedIcon = true,
    double height = controlHeight,
    double borderRadius = radius,
    BoxBorder border = _outline,
    BoxSpacing padding = _segmentPadding,
    double iconGap = _iconGap,
    BoxTextStyle labelStyle = MaterialTypography.labelLarge,
    // A width is divided equally between the segments; without one the pill is as wide as
    // its columns and hugs them — a row that scrolls, or a control in the corner of a page.
    // Both are one rule, the `GridNode` below, so the width states no size of its own.
    super.width,
    super.margin,
    BoxTransition? transition,
    super.key,
  }) : assert(
         onSelect != null ||
             segments.every((MaterialSegment segment) => segment.url != null),
         'A segment that is not a destination needs an onSelect to answer its '
         'press: give the control an onSelect, or give every segment a url.',
       ),
       super(
         height: height,
         // A disabled segmented button fades as one control rather than greying each
         // segment: Material draws the label at 38%, and one opacity is what this
         // model can say without an alpha role per token.
         opacity: enabled ? null : 0.38,
         borderRadius: borderRadius,
         border: border,
         overflow: Overflow.hidden,
         children: <UINode>[
           // One column per segment, all of one factor: the grid measures its widest
           // segment and gives each column that width, or divides the width it was given
           // between them. One rule for both cases, so the tree says nothing about how
           // wide a segment is — and the grid fills the pill, while a pill with no width
           // of its own is as wide as its columns.
           GridNode.columns(
             List<int>.filled(segments.length, 1),
             crossAlign: CrossAlign.stretch,
             children: <UINode>[
               for (int i = 0; i < segments.length; i++)
                 _segment(
                   segment: segments[i],
                   selected: i == selected,
                   enabled: enabled,
                   showSelectedIcon: showSelectedIcon,
                   first: i == 0,
                   border: border,
                   height: height,
                   padding: padding,
                   iconGap: iconGap,
                   labelStyle: labelStyle,
                   transition: transition,
                   onTap: onSelect == null ? null : () => onSelect(i),
                 ),
             ],
           ),
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

  /// One segment: the fill, a well over it that covers the whole segment, and the rule at
  /// its start unless it is the first.
  ///
  /// The press and the destination are the same decision, so they are made here once: a
  /// segment with a url that is not the chosen one is an anchor and nothing else, the
  /// chosen one is the page the reader is on and takes no press, and a segment without a
  /// url selects.
  ///
  /// The stack is what lets the rule stay inside the segment: a column of the pill is the
  /// whole of its width, so a line laid out before the segment's content would either take
  /// room from it or push the label off the centre of the column. Layered over it instead,
  /// the line is where the segment begins and the label stays centred on the segment — the
  /// geometry Material's own control draws, where the divider is part of the segment's own
  /// shape.
  static UINode _segment({
    required MaterialSegment segment,
    required bool selected,
    required bool enabled,
    required bool showSelectedIcon,
    required bool first,
    required BoxBorder border,
    required double height,
    required BoxSpacing padding,
    required double iconGap,
    required BoxTextStyle labelStyle,
    required BoxTransition? transition,
    required TapCallback? onTap,
  }) {
    final BoxColor foreground = _foregroundOf(selected);
    final bool link = segment.url != null;
    // A destination is not the page it points at: the chosen one is where the reader
    // already is, so it names no url and there is nothing left to press.
    final String? url = link && !selected ? segment.url : null;
    // Material puts the check of the chosen segment *in place of* its icon, so a
    // control that carries pictures still says which one is chosen. The mark is drawn
    // from boxes ([MaterialCheckMark]): a glyph from a font is a host asset, and this
    // package ships none.
    final UINode? leading = selected && showSelectedIcon
        ? MaterialCheckMark(color: foreground, size: iconSize)
        : segment.icon;

    return Box(
      // The fill of the chosen segment. The column itself is the grid's: every child of a
      // stated grid is one, so no segment states a width, a flex or a factor.
      backgroundColor: selected ? _selectedFill : null,
      children: <UINode>[
        StackNode(
          children: <UINode>[
            MaterialInkWell(
              onTap: link ? null : onTap,
              url: url,
              newTab: url != null && segment.newTab,
              enabled: enabled,
              ink: foreground,
              // A height, not an infinity: the segment is already as tall as the control,
              // and an infinite height inside a column is a constraint Flutter refuses.
              //
              // The width is infinite because the column is what bounds it: the pill gave
              // this segment its width, so the well fills exactly the column, and a tint or
              // an ink that only covered the label would stop short of the rounded end the
              // segment reaches.
              width: double.infinity,
              height: height,
              mainAlign: MainAlign.center,
              transition: transition ?? MaterialInkWell.defaultTransition,
              semantics: _semanticsOf(segment, selected: selected, link: link),
              child: Box(
                padding: padding,
                mainAlign: MainAlign.center,
                crossAlign: CrossAlign.center,
                width: double.infinity,
                textStyle: labelStyle.merge(BoxTextStyle(color: foreground)),
                children: <UINode>[
                  if (leading == null)
                    _labelOf(segment.label)
                  else
                    Box(
                      direction: Axis.horizontal,
                      crossAlign: CrossAlign.center,
                      gap: iconGap,
                      children: <UINode>[
                        leading,
                        _labelOf(segment.label, beside: true),
                      ],
                    ),
                ],
              ),
            ),
            if (!first) _divider(border, height),
          ],
        ),
      ],
    );
  }

  /// What one segment says to a screen reader.
  ///
  /// A destination is a link — the tag is its role, so the node adds a name and nothing
  /// else — and the chosen one names the page the reader is on. A segment that selects is
  /// a button, and says whether it is the chosen one.
  static BoxSemantics? _semanticsOf(
    MaterialSegment segment, {
    required bool selected,
    required bool link,
  }) {
    final String? label = segment.semanticsLabel;

    if (!link) {
      return BoxSemantics(
        role: BoxRole.button,
        label: label,
        pressed: selected,
      );
    }

    if (!selected) {
      return label == null ? null : BoxSemantics(label: label);
    }

    return label == null
        ? const BoxSemantics(current: BoxCurrent.page)
        : BoxSemantics(label: label, current: BoxCurrent.page);
  }

  /// The label of a segment, in the column the segment was given.
  ///
  /// A segment is a column of the control's width and not a width of its own, so a label
  /// long enough to fill it — a translation, or any label at a large text scale — has to
  /// give way rather than widen the pill or paint over the segment beside it. Two things
  /// say so, and both are read by the two targets:
  ///
  /// * the box around the label is **stretched**, which is what gives a text a width to
  ///   be cut at: Flutter hands the child of a stretched column a tight width and CSS
  ///   hands a stretched flex item the track, and a text that fills its box ellipsises
  ///   while one that hugs it first measures what it cannot have;
  /// * the text itself is **one line**, cut with an ellipsis ([_fitted]) and centred in
  ///   the room it was given, which is what Material states for a segment's label.
  ///
  /// There is no column to hug instead: every segment of a segmented button is one, and the
  /// widest label is what the column is. A label wider than one is only reached by a parent
  /// too narrow for `count ×` that widest segment.
  ///
  /// [beside] is the shape with a node in front of it. The model's `flex` is a portion of
  /// the parent and not "take what is left", so the label fills the room beside the
  /// node: a short label is centred in that room rather than sitting against its icon.
  /// Flutter's own `SegmentedButton` uses a `Flexible` there, which this model has no
  /// word for; the difference shows at a width where the label is much shorter than its
  /// column, and it is the price of a label that can never overflow.
  static UINode _labelOf(UINode label, {bool beside = false}) => Box(
    // A column, at the one place that says so: the box fills the segment when it is the
    // content's only child, and the room beside the node when it is the row's.
    flex: beside ? 1 : null,
    width: beside ? null : double.infinity,
    // The room the text is given, and the cut when it is still too long: a node that
    // is not a text cannot say how it gives way, so it is clipped at the column.
    crossAlign: CrossAlign.stretch,
    overflow: Overflow.hidden,
    children: <UINode>[_fitted(label)],
  );

  /// [label] as a segment draws it: one line, centred, and an ellipsis when it does not fit.
  ///
  /// A text is the one node that can say how it gives way, so it is rebuilt with the
  /// tokens that make it: [TextNode.maxLines] of one and [TextOverflow.ellipsis], which
  /// CSS spells `-webkit-line-clamp: 1` and Flutter `maxLines: 1` with an ellipsis. A
  /// caller who stated either keeps their answer, and every other token comes through
  /// untouched. A node that is not a text is returned as it is and cut by the box around
  /// it, because there is nothing to rebuild.
  static UINode _fitted(UINode label) {
    if (label is! TextNode) {
      return label;
    }

    return TextNode(
      label.text,
      key: label.key,
      headingLevel: label.headingLevel,
      fontSize: label.fontSize,
      fontWeight: label.fontWeight,
      color: label.color,
      lineHeight: label.lineHeight,
      fontFamily: label.fontFamily,
      letterSpacing: label.letterSpacing,
      decoration: label.decoration,
      decorationColor: label.decorationColor,
      decorationThickness: label.decorationThickness,
      // Centred, because the box around it now fills the column: a text that fills its
      // room and starts at its edge would read as a label pinned to the left of the pill.
      textAlign: label.textAlign ?? TextAlign.center,
      maxLines: label.maxLines ?? 1,
      overflow: label.overflow ?? TextOverflow.ellipsis,
      style: label.style,
    );
  }

  /// The rule between two segments: a hairline the colour of the border, at the start of
  /// the segment it opens.
  ///
  /// It is a box rather than a border on the segment, because the caller names one line for
  /// the pill and its rules and a border would draw all four sides of every segment; and it
  /// is layered over the segment rather than laid out before it, because the segment is a
  /// share of the pill and a line in its flow would either take a pixel of the share or
  /// push the label off the share's centre. `centerStart` is where it sits: the middle of
  /// the segment's starting edge, which is its left on a page written left to right and its
  /// right on one written the other way.
  ///
  /// The height is the control's, stated rather than filled: a positioned box cannot
  /// stretch to the layer it sits in, and an infinite height inside one is a fill the model
  /// reports — a page that scrolls hands the pill's whole subtree no end on that axis, and
  /// the renderer cannot tell that the pill's own height bounds it.
  static UINode _divider(BoxBorder border, double height) => PositionedNode(
    alignment: BoxAlignment.centerStart,
    child: Box(
      width: border.width,
      height: height,
      backgroundColor: border.color,
    ),
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
