import 'dart:math' as math;

/// What a [BoxFraction] is a share of.
enum BoxFractionOf {
  /// The extent the parent hands the box: a `FractionallySizedBox` in Flutter, a
  /// percentage in CSS. It resolves against the box this one is drawn in, so it needs a
  /// parent that has an extent to share.
  parent,

  /// The viewport: the height or the width of the window the page is drawn in. It is the
  /// one extent a box knows without being handed a box, which is what lets a panel say
  /// "as tall as the screen" inside a column that scrolls.
  viewport,
}

/// The width or height of a box as a share of something, with an inset taken off.
///
/// A share is the size a box can state without knowing a number: half of a row, one tab
/// of a bar, the height of the screen less the header above it. The two spellings are
///
/// ```dart
/// const panel = Box(heightFraction: BoxFraction.viewport(1, minus: 216));
/// const half = Box(widthFraction: BoxFraction.parent(0.5));
/// ```
///
/// [BoxFractionOf.parent] is the older spelling of "half of the box around me" and is what
/// a `FractionallySizedBox` and a percentage both draw. [BoxFractionOf.viewport] is the
/// same idea against the window instead: it is how a panel fills the screen without the
/// host handing it a bounded box, and [minus] is how it loses the room a pinned header and
/// toolbar take, because a share of the screen that overlaps them is a share of the wrong
/// thing.
///
/// A resolved share never goes below zero — `max(0px, calc(100dvh - 216px))` on the web,
/// the same clamp in Flutter — because a window shorter than the inset states a length of
/// nothing rather than a negative one, which no layout can draw.
final class BoxFraction {
  /// A share of the extent the parent hands the box.
  ///
  /// `1` is the whole of it and `0.5` half. A parent share takes no inset: a percentage
  /// of the parent is a percentage of the parent, and losing room from it is what a
  /// [BoxFraction.viewport] with a [minus] is for.
  const BoxFraction.parent(this.value) : of = BoxFractionOf.parent, minus = 0;

  /// A share of the viewport, less [minus] logical pixels.
  ///
  /// `BoxFraction.viewport(1)` is the height of the screen; `minus: 216` takes a header
  /// and a toolbar off it, which is what a panel that has to fill what is left of the
  /// window states. The result is floored at zero.
  const BoxFraction.viewport(this.value, {this.minus = 0})
    : of = BoxFractionOf.viewport;

  /// What [value] is a share of.
  final BoxFractionOf of;

  /// The factor: `1` is the whole of what this is a share of.
  final double value;

  /// The logical pixels taken off the share, which is only ever stated for a viewport
  /// share.
  final double minus;

  /// Whether this is a share of the parent.
  bool get isOfParent => of == BoxFractionOf.parent;

  /// Whether this is a share of the viewport.
  bool get isOfViewport => of == BoxFractionOf.viewport;

  /// Whether the share is a factor of a stated `width`/`height`, with nothing taken off,
  /// which is the one shape a percentage and a `FractionallySizedBox` state exactly.
  bool get isPlainParentShare => isOfParent && minus == 0;

  /// The length this resolves to, given the extent of what it is a share of.
  ///
  /// The extent is the parent's measured one or the viewport's, whichever [of] names.
  /// The answer is never negative: a share that takes off more than it has is a length
  /// of nothing.
  double resolve(double extent) => math.max(0.0, extent * value - minus);

  @override
  bool operator ==(Object other) =>
      other is BoxFraction &&
      other.of == of &&
      other.value == value &&
      other.minus == minus;

  @override
  int get hashCode => Object.hash(of, value, minus);

  @override
  String toString() => isOfParent
      ? 'BoxFraction.parent($value)'
      : 'BoxFraction.viewport($value, minus: $minus)';
}
