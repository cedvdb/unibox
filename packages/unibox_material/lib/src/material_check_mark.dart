import 'dart:math' as math;

import 'package:unibox_core/unibox_core.dart';

/// Material's check mark, drawn from two boxes: the tick a chosen control shows.
///
/// ```dart
/// MaterialChip(
///   label: const TextNode('Two rooms'),
///   selected: true,
///   leading: MaterialCheckMark(
///     color: const BoxColor.role(MaterialColorRole.onSecondaryContainer),
///   ),
/// )
/// ```
///
/// Material draws the check of a chosen chip and of a chosen segment with its icon
/// font, and a font is a host asset this package does not ship, so the shape is drawn
/// from the two strokes it is made of: a bar climbing to the left from an elbow and a
/// longer one climbing to the right, each turned 45°, each as thick as Material's own
/// outline and as long as it.
///
/// **The numbers are the glyph's, not a guess.** Material's check is a polygon of the
/// 24 pixel grid, and reduced to its two centre lines it is a 2 pixel stroke, a 7.07
/// pixel short arm (the diagonal of a 5 pixel step) and a 14 pixel long arm (the
/// diagonal of a 9.9 pixel one), each turned 45°. Those three shares are the glyph's,
/// and the elbow follows from them: it is placed
/// where the inked mark — both arms and their round caps — is centred in the square,
/// which puts it at Material's own `9.55` across and a sixth of a stroke below its
/// `16.6` down, the difference between a round cap and the mitred end of a polygon.
///
/// A tick drawn at a seventh of its box is nearly twice as heavy, which is what makes
/// a hand-tuned one read as a pen stroke beside Material's type. Both strokes end at
/// the same point, so their caps round the elbow too, and the mark carries no
/// semantics of its own — a chip and a segment say what is chosen through their
/// `selected`, so this is decoration beside a label.
final class MaterialCheckMark extends StackNode {
  /// Creates a check mark of [size], drawn in [color].
  MaterialCheckMark({
    required BoxColor color,
    double size = defaultSize,
    super.key,
  }) : super(width: size, height: size, children: _strokes(color, size));

  /// The size the mark is drawn at unless a caller says otherwise: 18, the node
  /// Material puts inside a chip and inside a segment.
  static const double defaultSize = 18;

  /// The thickness of Material's stroke, as a share of the box.
  static const double _strokeShare = 2 / 24;

  /// The length of the short arm, as a share of the box.
  static const double _shortArmShare = 7.07 / 24;

  /// The length of the long arm, as a share of the box.
  static const double _longArmShare = 14 / 24;

  /// The half of the square root of two: how far a 45° arm moves along each axis for
  /// every pixel of its length.
  static const double _diagonal = math.sqrt2 / 2;

  /// Where the elbow sits across the box, as a share of it from the middle: half the
  /// difference between the arms, which is the point that leaves as much tick on one
  /// side of the square as the other.
  static const double _elbowShareX =
      (_shortArmShare - _longArmShare) / 2 * _diagonal;

  /// Where the elbow sits down the box, as a share of it from the middle: half the long
  /// arm's climb, which centres the arms and their caps.
  static const double _elbowShareY = _longArmShare / 2 * _diagonal;

  /// The two strokes of the tick, each moved so that its inner end is the elbow.
  static List<UINode> _strokes(BoxColor color, double size) {
    final double thickness = size * _strokeShare;
    final double shortArm = size * _shortArmShare;
    final double longArm = size * _longArmShare;
    final double elbowX = size * _elbowShareX;
    final double elbowY = size * _elbowShareY;
    final double shortReach = shortArm / 2 * _diagonal;
    final double longReach = longArm / 2 * _diagonal;

    return <UINode>[
      // The short arm climbs to the left from the elbow, so its middle is half an
      // arm up and to the left of it.
      _centred(
        _bar(
          color: color,
          length: shortArm,
          thickness: thickness,
          rotation: 45,
          offsetX: elbowX - shortReach,
          offsetY: elbowY - shortReach,
        ),
      ),
      // The long arm climbs to the right, so its middle is half an arm up and to
      // the right of the same elbow.
      _centred(
        _bar(
          color: color,
          length: longArm,
          thickness: thickness,
          rotation: -45,
          offsetX: elbowX + longReach,
          offsetY: elbowY - longReach,
        ),
      ),
    ];
  }

  /// One stroke of the tick: a bar with rounded ends, turned and moved into place.
  static UINode _bar({
    required BoxColor color,
    required double length,
    required double thickness,
    required double rotation,
    required double offsetX,
    required double offsetY,
  }) => Box(
    width: length,
    height: thickness,
    borderRadius: thickness / 2,
    backgroundColor: color,
    transform: BoxTransform(
      rotation: rotation,
      offsetX: offsetX,
      offsetY: offsetY,
    ),
  );

  /// [child] in the middle of the stack that holds it.
  static UINode _centred(UINode child) =>
      PositionedNode(alignment: BoxAlignment.center, child: child);

  /// The name this node answers to in an inspector.
  @override
  String? get debugLabel => 'material-check-mark';
}
