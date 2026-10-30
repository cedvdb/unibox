import '../enums.dart';

/// One part of a look that a transition can ease on its own.
///
/// A look is made of parts a renderer animates separately, and CSS names each of
/// them as its own property. The set is deliberately the one both targets can
/// animate: the four things a box paints, its opacity and its transform.
enum BoxProperty {
  /// The colour behind the children.
  backgroundColor,

  /// The colour of the border line.
  borderColor,

  /// The corner radius.
  borderRadius,

  /// The drop shadows.
  shadows,

  /// How opaque the box is.
  opacity,

  /// How the box is moved, turned or scaled.
  transform;

  /// The four things a box paints, which ease as one group.
  ///
  /// Flutter interpolates a `BoxDecoration` as a unit, so a transition that moved
  /// the paint at different speeds would need layered decorations. Naming this set
  /// in one part is the way to say "the paint, all of it, at this speed"; splitting
  /// it is reported by `validateTree`, and a box that really wants two paint speeds
  /// nests a box.
  static const Set<BoxProperty> paint = <BoxProperty>{
    backgroundColor,
    borderColor,
    borderRadius,
    shadows,
  };
}

/// How one group of looks eases, and when it starts.
///
/// ```dart
/// const BoxTransition(
///   duration: Duration(milliseconds: 200),
///   parts: <BoxTransitionPart>[
///     // the colour first…
///     BoxTransitionPart(
///       properties: <BoxProperty>{BoxProperty.backgroundColor},
///       duration: Duration(milliseconds: 100),
///     ),
///     // …then the scale, once the colour has settled
///     BoxTransitionPart(
///       properties: <BoxProperty>{BoxProperty.transform},
///       duration: Duration(milliseconds: 150),
///       delay: Duration(milliseconds: 100),
///     ),
///   ],
/// )
/// ```
final class BoxTransitionPart {
  /// Creates a part that eases [properties] over [duration], after [delay].
  const BoxTransitionPart({
    required this.properties,
    required this.duration,
    this.curve = BoxCurve.ease,
    this.delay = Duration.zero,
  });

  /// The properties this part eases.
  final Set<BoxProperty> properties;

  /// How long they take.
  final Duration duration;

  /// How they ease.
  final BoxCurve curve;

  /// How long after the change they start.
  final Duration delay;

  /// When the part finishes, counted from the change.
  Duration get end => delay + duration;

  /// Creates a copy of this part with the given fields replaced.
  BoxTransitionPart copyWith({
    Set<BoxProperty>? properties,
    Duration? duration,
    BoxCurve? curve,
    Duration? delay,
  }) {
    return BoxTransitionPart(
      properties: properties ?? this.properties,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      delay: delay ?? this.delay,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BoxTransitionPart &&
      other.properties.length == properties.length &&
      other.properties.containsAll(properties) &&
      other.duration == duration &&
      other.curve == curve &&
      other.delay == delay;

  @override
  int get hashCode =>
      Object.hash(Object.hashAllUnordered(properties), duration, curve, delay);

  @override
  String toString() =>
      'BoxTransitionPart(properties: ${properties.map((BoxProperty l) => l.name).join(', ')}, '
      'duration: $duration, curve: $curve, delay: $delay)';
}

/// The timing of one look, resolved from a [BoxTransition].
typedef BoxTransitionTiming = ({
  Duration duration,
  BoxCurve curve,
  Duration delay,
});

/// How one look of a box becomes another.
///
/// A [BoxStyle] describes a box at rest; a [BoxState] style, or a bag the host
/// swaps in, describes it otherwise. Without a transition the second replaces the
/// first and the eye sees a jump. A transition turns that jump into an
/// interpolation of the *paint* — background, border colour, corner radius,
/// shadow — of the opacity and of the transform, which is the set both targets
/// animate with the same result.
///
/// The single [duration] and [curve] are the base; [parts] override them for the
/// looks they name, so a colour can settle before a scale starts.
///
/// Two things are deliberately outside it. Layout never animates: a transition on
/// a width or a gap would move everything around the box on one target and not on
/// the other, and a moving layout is not a look. And the border *width* is not in
/// the set for the same reason: CSS animates it as a layout change, Flutter as a
/// paint change.
///
/// ```dart
/// const Box(
///   stateStyles: <BoxState, BoxStyle>{
///     BoxState.hover: BoxStyle(backgroundColor: BoxColor.rgb(0xF3, 0xF4, 0xF6)),
///   },
///   transition: BoxTransition(duration: Duration(milliseconds: 150)),
/// );
/// ```
final class BoxTransition {
  /// Creates a transition with a base [duration] and [curve], and [parts] that
  /// override them for the looks they name.
  const BoxTransition({
    required this.duration,
    this.curve = BoxCurve.ease,
    this.parts = const <BoxTransitionPart>[],
  });

  /// How long a look takes to change, unless a [parts] entry says otherwise.
  ///
  /// A duration of zero or less renders as no animation at all; `validateTree`
  /// reports it, because a `Duration` cannot be checked in a const constructor.
  final Duration duration;

  /// The easing applied over [duration].
  final BoxCurve curve;

  /// Per-look overrides of [duration] and [curve].
  final List<BoxTransitionPart> parts;

  /// The timing [look] eases with: its own part when one names it, the base
  /// otherwise.
  BoxTransitionTiming timingOf(BoxProperty look) {
    for (final BoxTransitionPart part in parts) {
      if (part.properties.contains(look)) {
        return (duration: part.duration, curve: part.curve, delay: part.delay);
      }
    }
    return (duration: duration, curve: curve, delay: Duration.zero);
  }

  /// How long the whole change takes, from the first part that starts to the last
  /// that finishes.
  Duration get totalDuration {
    Duration total = Duration.zero;
    for (final BoxProperty look in BoxProperty.values) {
      final Duration end = timingOf(look).delay + timingOf(look).duration;
      if (end > total) {
        total = end;
      }
    }
    return total;
  }

  /// Creates a copy of this transition with the given fields replaced.
  BoxTransition copyWith({
    Duration? duration,
    BoxCurve? curve,
    List<BoxTransitionPart>? parts,
  }) {
    return BoxTransition(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      parts: parts ?? this.parts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! BoxTransition ||
        other.duration != duration ||
        other.curve != curve ||
        other.parts.length != parts.length) {
      return false;
    }
    for (var index = 0; index < parts.length; index++) {
      if (other.parts[index] != parts[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(duration, curve, Object.hashAll(parts));

  @override
  String toString() =>
      'BoxTransition(duration: $duration, curve: $curve, parts: $parts)';
}
