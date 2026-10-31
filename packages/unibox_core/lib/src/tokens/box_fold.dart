import '../enums.dart';
import 'box_style.dart';
import 'box_transition.dart';

/// The look a box takes as it leaves the box that scrolls it.
///
/// A fold is the one motion the *reader* drives: the scroll is the clock, and the box paints
/// another look the further it has travelled out of its viewport. It is what a hero does as a
/// toolbar comes up under it — fading, shrinking a little, losing its picture — and it is the
/// one piece of an app's chrome that a served document could not otherwise have.
///
/// It is paint only. The background colour, the border colour, the corner radius, the
/// shadows, the opacity and the transform: the same set [BoxTransition] eases, and for the
/// same reason — a layout that moves is not a look, and two engines interpolating a layout
/// give two different pictures on every frame in between.
///
/// The travel is the box's own exit from the viewport, from its leading edge reaching the
/// edge of the viewport to its trailing edge leaving it. Nothing states a number of pixels,
/// so the same tree folds over a hero of 132 pixels or of 200 without being edited: a browser
/// gets the range from `view()` and Flutter from the box's own rectangle.
///
/// ```dart
/// Box(
///   height: 132,
///   fold: const BoxFold(
///     to: BoxStyle(opacity: 0, transform: BoxTransform(scale: 0.75)),
///     over: 0.75,
///   ),
///   children: <UINode>[TextNode('Six flats, one tree')],
/// )
/// ```
final class BoxFold {
  /// Creates a fold from the box's own look towards [to].
  ///
  /// [to] states the tokens at the end of the travel, [curve] how they ease on the way, and
  /// [over] how much of the exit the fold takes: the default completes it exactly as the box
  /// leaves, and `0.5` completes it while half the box is still in view, which is a look that
  /// is gone before the reader has finished with it.
  const BoxFold({
    required this.to,
    this.curve = BoxCurve.linear,
    this.over = 1,
  });

  /// The tokens at the end of the travel.
  ///
  /// Only the looks a box paints may be named here: the background, the border colour, the
  /// corner radius, the shadows, the opacity and the transform. `validateTree` reports the
  /// rest, because a fold cannot move a layout.
  final BoxStyle to;

  /// How the change eases over the travel, from the five curves both targets share.
  final BoxCurve curve;

  /// How much of the box's exit the fold completes over, from `0` up to `1`.
  ///
  /// `1` — the default — reaches the folded look exactly as the box leaves the viewport.
  /// A smaller number finishes earlier, which is how `1 - t * 1.5` is stated: at `0.66` the
  /// look has arrived while a third of the box is still in view.
  final double over;

  /// The looks this fold moves, which are the ones [to] names.
  ///
  /// A renderer eases exactly these, so a fold that states no paint is a fold that changes
  /// nothing — `validateTree` says so rather than shipping a rule no browser applies.
  Set<BoxProperty> get looks => <BoxProperty>{
    if (to.backgroundColor != null) BoxProperty.backgroundColor,
    if (to.border != null) BoxProperty.borderColor,
    if (to.borderRadius != null || to.corners != null) BoxProperty.borderRadius,
    if (to.shadows != null) BoxProperty.shadows,
    if (to.opacity != null) BoxProperty.opacity,
    if (to.transform != null) BoxProperty.transform,
  };

  /// Whether the fold names no look at all.
  bool get isEmpty => looks.isEmpty;

  /// How far into the fold the box is, given the fraction of its own [exit] it has travelled.
  ///
  /// The one piece of arithmetic both targets share, in the order a browser applies it: the
  /// range first — [over] — and the curve after it, which each engine applies in its own
  /// interpolator. [exit] is clamped, so an overscroll or a box that has not moved yet reads
  /// as the resting or the folded look rather than past it.
  double progressAt(double exit) {
    if (over <= 0) {
      return 1;
    }

    return (exit / over).clamp(0.0, 1.0);
  }

  /// A copy of this fold with the named fields replaced.
  BoxFold copyWith({BoxStyle? to, BoxCurve? curve, double? over}) => BoxFold(
    to: to ?? this.to,
    curve: curve ?? this.curve,
    over: over ?? this.over,
  );

  @override
  bool operator ==(Object other) =>
      other is BoxFold &&
      other.to == to &&
      other.curve == curve &&
      other.over == over;

  @override
  int get hashCode => Object.hash(to, curve, over);

  @override
  String toString() => 'BoxFold(to: $to, curve: $curve, over: $over)';
}
