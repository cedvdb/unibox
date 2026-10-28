/// A rigid transformation of a box: move it, turn it, scale it.
///
/// The three parts are applied in one fixed order — translate, then rotate, then
/// scale — about the centre of the box, on both targets. The order has to be part
/// of the model because CSS and Flutter both compose matrices left to right and
/// would otherwise let a renderer choose: CSS spells this as
/// `translate(x, y) rotate(deg) scale(s)` with its default origin of the centre,
/// Flutter as the same matrix with `alignment: Alignment.center`.
///
/// ```dart
/// const lifted = Box(
///   transform: BoxTransform(offsetY: -4, scale: 1.02),
///   transition: BoxTransition(duration: Duration(milliseconds: 150)),
///   hoverStyle: BoxStyle(transform: BoxTransform(offsetY: -4, scale: 1.02)),
/// );
/// ```
final class BoxTransform {
  /// Creates a transformation. Every part defaults to "leave it alone".
  const BoxTransform({
    this.scale = 1,
    this.scaleX = 1,
    this.scaleY = 1,
    this.rotation = 0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  /// The scale factor, `1` for the size the box was given.
  ///
  /// A value below `1` shrinks the box, above `1` grows it. Scaling never changes
  /// the space the box occupies: like a `Transform` in Flutter, it paints bigger
  /// or smaller, so words do not reflow and neighbours do not move.
  final double scale;

  /// How much [scale] stretches the box along the x axis, `1` for not at all.
  ///
  /// The two axes are separate because a control can grow in one direction and not
  /// the other: Material's navigation indicator stretches out of its icon sideways
  /// at its full height, which a single factor cannot say. It multiplies [scale]
  /// rather than replacing it, so `scale: 2, scaleX: 0.5` is the box at its own
  /// height and its own width.
  final double scaleX;

  /// How much [scale] stretches the box along the y axis, `1` for not at all.
  final double scaleY;

  /// The rotation in degrees, clockwise, around the centre of the box.
  final double rotation;

  /// How far to move the box along the x axis, in logical pixels.
  final double offsetX;

  /// How far to move the box along the y axis, in logical pixels.
  final double offsetY;

  /// Whether this transformation leaves the box exactly where it was.
  bool get isIdentity =>
      scale == 1 &&
      scaleX == 1 &&
      scaleY == 1 &&
      rotation == 0 &&
      offsetX == 0 &&
      offsetY == 0;

  /// Creates a copy of this transformation with the given parts replaced.
  BoxTransform copyWith({
    double? scale,
    double? scaleX,
    double? scaleY,
    double? rotation,
    double? offsetX,
    double? offsetY,
  }) {
    return BoxTransform(
      scale: scale ?? this.scale,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      rotation: rotation ?? this.rotation,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }

  /// The transformation a fraction [t] of the way from [begin] to [end].
  ///
  /// Each part is interpolated on its own, which is what CSS does when both sides
  /// of a transition list the same transform functions: interpolating the composed
  /// matrices instead would shrink a box that is only turning.
  static BoxTransform lerp(BoxTransform begin, BoxTransform end, double t) {
    if (t <= 0) {
      return begin;
    }
    if (t >= 1) {
      return end;
    }
    return BoxTransform(
      scale: begin.scale + (end.scale - begin.scale) * t,
      scaleX: begin.scaleX + (end.scaleX - begin.scaleX) * t,
      scaleY: begin.scaleY + (end.scaleY - begin.scaleY) * t,
      rotation: begin.rotation + (end.rotation - begin.rotation) * t,
      offsetX: begin.offsetX + (end.offsetX - begin.offsetX) * t,
      offsetY: begin.offsetY + (end.offsetY - begin.offsetY) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BoxTransform &&
      other.scale == scale &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY &&
      other.rotation == rotation &&
      other.offsetX == offsetX &&
      other.offsetY == offsetY;

  @override
  int get hashCode =>
      Object.hash(scale, scaleX, scaleY, rotation, offsetX, offsetY);

  @override
  String toString() =>
      'BoxTransform(scale: $scale, scaleX: $scaleX, scaleY: $scaleY, '
      'rotation: $rotation, offsetX: $offsetX, offsetY: $offsetY)';
}
