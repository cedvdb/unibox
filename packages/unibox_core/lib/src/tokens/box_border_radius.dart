/// The radius of each corner of a box, in logical pixels.
///
/// This is Flutter's `BorderRadius` under the package's `Box` prefix — the name
/// is prefixed because `BorderRadius` is a `dart:ui` type, and a token with that
/// name would be a compile error in any file that imports Flutter unprefixed.
///
/// [BoxStyle.borderRadius] is one radius for all four corners, which is what most
/// boxes want. A box that must not be round everywhere names the four here — a
/// Material filled text field rounds its top corners and leaves the bottom square,
/// and a bottom sheet is round at the top only.
///
/// ```dart
/// Box(
///   backgroundColor: BoxColor.white,
///   corners: BoxBorderRadius(topLeft: 4, topRight: 4),
/// )
/// ```
///
/// A corner left out is square. The four are one value, so a box that rounds two
/// corners declares it once rather than composing two half boxes.
final class BoxBorderRadius {
  /// Creates the four corners; a corner not named is square.
  const BoxBorderRadius({
    this.topLeft = 0,
    this.topRight = 0,
    this.bottomRight = 0,
    this.bottomLeft = 0,
  });

  /// Creates corners that are all [radius].
  const BoxBorderRadius.all(double radius)
    : topLeft = radius,
      topRight = radius,
      bottomRight = radius,
      bottomLeft = radius;

  /// The radius of the top left corner.
  final double topLeft;

  /// The radius of the top right corner.
  final double topRight;

  /// The radius of the bottom right corner.
  final double bottomRight;

  /// The radius of the bottom left corner.
  final double bottomLeft;

  /// Whether all four corners are the same radius.
  bool get isUniform =>
      topLeft == topRight &&
      topRight == bottomRight &&
      bottomRight == bottomLeft;

  /// Whether every corner is square.
  bool get isSquare => isUniform && topLeft == 0;

  /// The radius every corner shares. Only meaningful when [isUniform].
  double get uniform => topLeft;

  /// The four radii in CSS order: top left, top right, bottom right, bottom left.
  List<double> get radii => <double>[
    topLeft,
    topRight,
    bottomRight,
    bottomLeft,
  ];

  @override
  bool operator ==(Object other) =>
      other is BoxBorderRadius &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);

  @override
  String toString() =>
      'BoxBorderRadius(topLeft: $topLeft, topRight: $topRight, '
      'bottomRight: $bottomRight, bottomLeft: $bottomLeft)';
}
