import 'dart:async';

import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// A Material 3 circular progress indicator: a ring, and the part of it that is
/// done.
///
/// ```dart
/// MaterialProgressRing(value: 0.42, label: '42% complete')
/// ```
///
/// The whole component is three nodes: a box that draws the track, a box that draws
/// the value, and the stack that puts one over the other. Each is **an arc stroked in
/// a colour** — `BoxShape.arc` for the outline, `BoxBorder` for the paint, with the
/// rounded ends Material draws — so no renderer knows what a progress indicator is,
/// which is what makes the look a value and the component a node built from nodes.
///
/// **A ring states its thickness in pixels.** The shape is written in a view box as
/// wide as the box, so a hundredth of the ring is a hundredth of the diameter and
/// [thickness] is a length: a 4 pixel stroke is 4 pixels at every size, which is what
/// Material's indicator does. The same number is the shape's inset and the border's
/// width, which is why the stroke sits inside the box rather than half outside it.
///
/// **The value is clamped.** A ring is one turn, so `-0.2` draws no value and `1.4`
/// draws a closed ring rather than reporting an error: a value is data an application
/// computes, not a mistake to throw about.
///
/// **What it is not.** It does not animate: a bar that moves is a value a store
/// publishes or a timeline the model runs, and this class draws whatever fraction it is
/// given. An unknown value is [MaterialSpinner]. And the model has no progress role, so
/// a screen reader hears [label] as text — a `role="progressbar"` with its bounds is a
/// gap in `BoxSemantics`, not something this class can fix.
final class MaterialProgressRing extends Box {
  /// Creates a ring that is [value] of the way round, over its track.
  MaterialProgressRing({
    required double value,
    double size = 48,
    double thickness = 4,
    BoxColor indicator = defaultIndicator,
    BoxColor track = defaultTrack,
    super.transform,
    String? label,
    super.key,
  }) : super(
         width: size,
         height: size,
         semantics: label == null ? null : BoxSemantics(label: label),
         children: <UINode>[
           StackNode(
             children: <UINode>[
               _arc(size: size, thickness: thickness, color: track),
               if (value > 0)
                 _arc(
                   size: size,
                   thickness: thickness,
                   color: indicator,
                   sweep: value,
                 ),
             ],
           ),
         ],
       );

  /// One arc of the ring: the outline of a circle, [sweep] of the way round, stroked
  /// in [color].
  ///
  /// The border *is* the paint. A shaped box strokes its outline instead of filling it,
  /// so the stroke's width and the shape's inset are one number, and `round` is what
  /// gives the arc the ends Material draws — without a cap, a stroke stops on a radius
  /// and an indicator reads as a wedge.
  static Box _arc({
    required double size,
    required double thickness,
    required BoxColor color,
    double sweep = 1,
  }) => Box(
    width: size,
    height: size,
    shape: BoxShape.arc(stroke: thickness, sweep: sweep, viewBox: size),
    border: BoxBorder(width: thickness, color: color, cap: BoxStrokeCap.round),
  );

  /// The colour of the part that is done.
  static const BoxColor defaultIndicator = BoxColor.role(
    MaterialColorRole.primary,
  );

  /// The colour of the part that is not.
  static const BoxColor defaultTrack = BoxColor.role(
    MaterialColorRole.surfaceContainerHighest,
  );
}

/// What a [MaterialSpinner] is turning to: which step of the turn it is on.
///
/// One number and a clock: the spinner is a ring at a fixed sweep, rotated by a step
/// that wraps. Every step repeats after one turn, so a page that has been open for an
/// hour looks the same as one that has been open for a second — and on the web it
/// also writes the same class again instead of a new one, which is why the sheet
/// stops growing after the first turn.
final class MaterialSpinStore extends StateStore<int> {
  /// Creates a spinner stopped at its first step.
  MaterialSpinStore({this.steps = 60}) : super(0);

  /// How many steps one turn is divided into.
  ///
  /// Sixty is one step a frame at 16 milliseconds, so a turn takes just under a
  /// second and the ring never jumps further than the eye follows.
  final int steps;

  /// How long one step lasts.
  static const Duration frame = Duration(milliseconds: 16);

  Timer? _ticker;

  /// How far the ring has turned, in degrees.
  double get degrees => state * 360 / steps;

  /// Turns the ring one step, wrapping to the start after a full turn.
  void advance() => state = (state + 1) % steps;

  @override
  void onMount() {
    _ticker ??= Timer.periodic(frame, (Timer _) => advance());
  }

  @override
  void onUnmount() => _stop();

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  /// Stops the clock, so a spinner that left the tree leaves no timer behind.
  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }
}

/// A Material 3 circular progress indicator whose value is not known: a ring that
/// turns.
///
/// ```dart
/// MaterialSpinner(label: 'Loading')
/// ```
///
/// It draws a [MaterialProgressRing] at [sweep] of a turn and rotates it one step
/// per frame, which is the whole animation. The sweep does not breathe the way
/// Material's spinner does — a shape cannot be eased, because two outlines have no
/// numbers between them — and the turn is a sequence of steps rather than a curve,
/// because the model has no keyframe timeline. Both are decisions rather than
/// accidents: a `BoxTransition` cannot move a path, and a `Timer` can.
///
/// **A server render draws one frame.** `onMount` starts the clock and a renderer
/// that cannot react never calls it, so an export shows a still ring rather than
/// nothing at all.
final class MaterialSpinner extends StatefulNode<int, MaterialSpinStore> {
  /// Creates a spinner of [size], with [sweep] of the turn drawn.
  MaterialSpinner({
    double size = 48,
    double thickness = 4,
    double sweep = 0.75,
    BoxColor indicator = MaterialProgressRing.defaultIndicator,
    BoxColor track = MaterialProgressRing.defaultTrack,
    int steps = 60,
    String? label,
    super.key,
  }) : super(
         create: () => MaterialSpinStore(steps: steps),
         view: (int phase, MaterialSpinStore store) => MaterialProgressRing(
           value: sweep,
           size: size,
           thickness: thickness,
           indicator: indicator,
           track: track,
           label: label,
           transform: BoxTransform(rotation: store.degrees),
         ),
       );
}
