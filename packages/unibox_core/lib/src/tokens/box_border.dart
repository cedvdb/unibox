import 'box_color.dart';
import 'unibox_theme.dart';

/// A uniform border drawn around a box.
final class BoxBorder {
  /// Creates a border with the given [width], [color] and [cap].
  const BoxBorder({
    this.width = 1,
    this.color = BoxColor.black,
    this.cap = BoxStrokeCap.butt,
  });

  /// A border that occupies no space and is not painted.
  const BoxBorder.none()
    : width = 0,
      color = BoxColor.transparent,
      cap = BoxStrokeCap.butt;

  /// This border with its role colour looked up in [theme].
  ///
  /// A border that names no role comes back as it is, so calling this on every
  /// style costs nothing when a tree uses values.
  BoxBorder resolve(UniboxTheme theme) => color.isRole
      ? BoxBorder(width: width, color: theme.resolve(color), cap: cap)
      : this;

  /// The border thickness in logical pixels.
  final double width;

  /// The border color.
  final BoxColor color;

  /// How the ends of the border are drawn where it is not closed.
  ///
  /// A rectangle has no ends — its border meets itself at four corners — so this is
  /// read by a box wearing a shape, where the outline is a line and the two ends of it
  /// are visible. A shaped box with a [BoxStrokeCap.round] border draws the rounded
  /// ends Material's progress indicator has, on both targets.
  final BoxStrokeCap cap;

  /// Whether the border has a visible thickness.
  bool get isVisible => width > 0;

  @override
  bool operator ==(Object other) =>
      other is BoxBorder &&
      other.width == width &&
      other.color == color &&
      other.cap == cap;

  @override
  int get hashCode => Object.hash(width, color, cap);

  @override
  String toString() => 'BoxBorder(width: $width, color: $color, cap: $cap)';
}

/// How the end of a line is drawn.
///
/// The three CSS and Skia both define with the same geometry, so a cap is interpolated
/// identically on both targets. `butt` stops the stroke at the end point, `round` adds a
/// half disc, `square` adds a half square — which is what makes the ends of an arc differ
/// in shape but not in position.
enum BoxStrokeCap {
  /// The stroke stops where the line does.
  butt,

  /// The stroke ends in a half disc, centred on the end point.
  round,

  /// The stroke ends in a half square: a half [BoxBorder.width] longer than `butt`.
  square,
}
