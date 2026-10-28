import 'dart:async';

import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// One drop of ink in flight: where it started and how far it has spread.
final class MaterialInkDrop {
  /// Creates a drop at [position] that has spread [progress] of the way.
  const MaterialInkDrop({
    required this.id,
    required this.position,
    required this.progress,
  });

  /// The identity of the drop, which keeps two presses apart.
  final int id;

  /// Where the press landed, inside the ink well.
  final BoxPoint position;

  /// How far the ink has spread, `0` to `1`.
  final double progress;

  /// The same drop, spread a little further.
  MaterialInkDrop advanceTo(double next) =>
      MaterialInkDrop(id: id, position: position, progress: next);

  @override
  bool operator ==(Object other) =>
      other is MaterialInkDrop &&
      other.id == id &&
      other.position == position &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(id, position, progress);

  @override
  String toString() =>
      'MaterialInkDrop(id: $id, position: $position, progress: $progress)';
}

/// The ink an ink well is drawing right now.
final class MaterialInkState {
  /// Creates a state with [drops] in flight.
  const MaterialInkState({this.drops = const <MaterialInkDrop>[]});

  /// The drops in flight, oldest first.
  final List<MaterialInkDrop> drops;

  @override
  bool operator ==(Object other) =>
      other is MaterialInkState &&
      other.drops.length == drops.length &&
      <int>[for (int i = 0; i < drops.length; i++) i]
          .every((int i) => other.drops[i] == drops[i]);

  @override
  int get hashCode =>
      Object.hashAll(drops.map((MaterialInkDrop drop) => drop.id));

  @override
  String toString() => 'MaterialInkState(drops: ${drops.length})';
}

/// How long a drop takes to spread and fade: Material's splash timeline.
const Duration materialInkDuration = Duration(milliseconds: 450);

/// How wide the ink grows before it stops, in logical pixels.
///
/// A box does not know its own size, so a drop grows to a size that covers a
/// button and stops: a region larger than this shows ink around its centre.
const double materialInkSpread = 280;

/// How opaque the ink starts, before it fades out with the drop.
const double materialInkOpacity = 0.12;

/// The frame the ink is advanced by while a drop is in flight.
const Duration _inkFrame = Duration(milliseconds: 16);

/// The ink a press of a [MaterialInkWell] starts.
///
/// The ripple is state like any other: a press adds a drop, a timer advances it
/// every frame, and the view draws one box per drop. Nothing here knows about
/// Flutter or the DOM, which is why the same well ripples wherever a renderer
/// subscribes to the store — and why a page rendered without a client runtime
/// shows the resting well and no ink at all.
final class MaterialInkStore extends StateStore<MaterialInkState> {
  /// Creates a store with no ink in flight.
  MaterialInkStore() : super(const MaterialInkState());

  Timer? _ticker;
  int _next = 0;

  /// Starts a drop where [position] was pressed.
  void press(BoxPoint position) {
    state = MaterialInkState(
      drops: <MaterialInkDrop>[
        ...state.drops,
        MaterialInkDrop(id: _next++, position: position, progress: 0),
      ],
    );

    _ticker ??= Timer.periodic(_inkFrame, (Timer _) => advance(_inkFrame));
  }

  /// Advances every drop by [delta] and forgets the ones that have spread.
  ///
  /// It is public so a test can drive the clock itself, which is also what keeps
  /// the store from hiding a clock of its own behind the timer.
  void advance(Duration delta) {
    final double step =
        delta.inMicroseconds / materialInkDuration.inMicroseconds;

    final List<MaterialInkDrop> next = <MaterialInkDrop>[
      for (final MaterialInkDrop drop in state.drops)
        if (drop.progress + step < 1) drop.advanceTo(drop.progress + step),
    ];

    state = MaterialInkState(drops: next);

    if (next.isEmpty) {
      _stop();
    }
  }

  @override
  void onUnmount() => _stop();

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  /// Stops the clock, so a well that left the tree leaves no timer behind.
  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }
}

/// A Material 3 tappable region around [child]: the three state layers of the
/// palette, and the ink a press spreads from where it landed.
///
/// ```dart
/// MaterialInkWell(
///   onTap: openContact,
///   borderRadius: 12,
///   child: const TextNode('Ada Lovelace'),
/// )
/// ```
///
/// It is a [StatefulNode] over one box, so both targets draw it with the
/// renderers they already have: the tints are state styles, and the ink is a
/// second layer of boxes whose size and opacity come from [MaterialInkStore].
/// The node buys the combination — the three layers, a short transition so a
/// tint eases instead of flashing, the ink, and the button role when the region
/// can be tapped.
///
/// **It paints no surface of its own.** The ink and the tints have to sit *above*
/// the fill they belong to, so the filled box goes around the ink well, not
/// inside it; wrapped the other way round the fill would hide both. The well
/// clips its own content to [borderRadius], which is how a drop stays inside a
/// rounded button.
///
/// **What the ink needs.** A region only ripples when it can be pressed — an
/// `onTap` or an `onLongPress`, and [enabled] — so a well that only paints a
/// hover tint listens to no pointer at all and renders without a client runtime.
/// A server render reads the resting state and draws no ink, which is exactly
/// what a page without JavaScript should show.
///
/// Every colour is a [MaterialColorRole], so a dark scheme is the host's theme
/// rather than a parameter here; [ink] is the one exception, because the ink has
/// to contrast with the fill *around* the well, which is not a role the well can
/// see.
final class MaterialInkWell
    extends StatefulNode<MaterialInkState, MaterialInkStore> {
  /// Creates a region that tints and ripples when pressed.
  ///
  /// [onTap] is read here instead of being passed straight through, because a
  /// tappable region is what gets the button role. [padding] is the room between
  /// the edge of the well and [child]; the ink is painted under it.
  MaterialInkWell({
    super.key,
    required UINode child,
    TapCallback? onTap,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    bool enabled = true,
    BoxSpacing? margin,
    BoxSpacing? padding,
    double? width,
    double? height,
    int? flex,
    double? borderRadius,
    BoxColor ink = defaultInk,
    BoxSemantics? semantics,
    BoxTransition transition = defaultTransition,
    BoxStyle? hoverStyle,
    BoxStyle? focusStyle,
    BoxStyle? pressedStyle,
  }) : super(
         create: MaterialInkStore.new,
         view: (MaterialInkState state, MaterialInkStore store) => _inkWellView(
           state,
           store,
           child: child,
           onTap: onTap,
           onLongPress: onLongPress,
           onHover: onHover,
           enabled: enabled,
           margin: margin,
           padding: padding,
           width: width,
           height: height,
           flex: flex,
           borderRadius: borderRadius,
           ink: ink,
           semantics: semantics,
           transition: transition,
           hoverStyle: hoverStyle,
           focusStyle: focusStyle,
           pressedStyle: pressedStyle,
         ),
       );

  /// The colour the ink is painted with unless the well is told otherwise: the
  /// colour of text on the page, which is what Material splashes over a surface.
  static const BoxColor defaultInk = BoxColor.role(MaterialColorRole.onSurface);

  /// The easing of the tint: Material's short fade, so a state change is not a
  /// flash.
  static const BoxTransition defaultTransition = BoxTransition(
    duration: Duration(milliseconds: 100),
  );

  /// [color] as the background of a state style.
  static BoxStyle _tint(BoxColor color) => BoxStyle(backgroundColor: color);
}

/// The well, its ink and its content, as one box.
///
/// Four layers, painted in this order: the fill (outside, in the box around the
/// well), the tints (this box's own background), the ink, and the content. The
/// ink goes under the content and above the tints because a drop is meant to be
/// read through the label, not over it.
///
/// The drops sit in the stack the well holds, and the well clips them to its
/// radius. Clipping at the well rather than in a filling layer is what keeps the
/// ripple off a rule the model does not have: a child that fills a positioned
/// parent does not fill on the web, so every box in the ink carries its own size.
UINode _inkWellView(
  MaterialInkState state,
  MaterialInkStore store, {
  required UINode child,
  required TapCallback? onTap,
  required LongPressCallback? onLongPress,
  required HoverCallback? onHover,
  required bool enabled,
  required BoxSpacing? margin,
  required BoxSpacing? padding,
  required double? width,
  required double? height,
  required int? flex,
  required double? borderRadius,
  required BoxColor ink,
  required BoxSemantics? semantics,
  required BoxTransition transition,
  required BoxStyle? hoverStyle,
  required BoxStyle? focusStyle,
  required BoxStyle? pressedStyle,
}) {
  final bool pressable = enabled && (onTap != null || onLongPress != null);

  return Box(
    onTap: onTap,
    onTapDown: pressable
        ? (BoxTapEvent event) => store.press(event.position)
        : null,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    margin: margin,
    width: width,
    height: height,
    flex: flex,
    borderRadius: borderRadius,
    overflow: Overflow.hidden,
    transition: transition,
    semantics:
        semantics ??
        (onTap == null ? null : const BoxSemantics(role: BoxRole.button)),
    hoverStyle:
        hoverStyle ??
        MaterialInkWell._tint(
          const BoxColor.role(MaterialColorRole.hoverLayer),
        ),
    stateStyles: <BoxState, BoxStyle>{
      BoxState.focus:
          focusStyle ??
          MaterialInkWell._tint(
            const BoxColor.role(MaterialColorRole.focusLayer),
          ),
      BoxState.pressed:
          pressedStyle ??
          MaterialInkWell._tint(
            const BoxColor.role(MaterialColorRole.pressedLayer),
          ),
    },
    children: <UINode>[
      StackNode(
        children: <UINode>[
          for (final MaterialInkDrop drop in state.drops) _dropView(drop, ink),
          // The content sizes the stack; a drop takes no room of its own.
          Box(padding: padding, children: <UINode>[child]),
        ],
      ),
    ],
  );
}

/// One drop: a circle centred on the press, growing as it fades.
///
/// The circle is moved by a transform rather than by the offsets of the node that
/// positions it, and that is a cost decision: a frame of the ripple is then one look
/// of one box, so the web writes the wrapper's rule once and only the ink's own
/// declarations are new. A transform also paints without taking room, which is what
/// keeps a growing drop from resizing the well around it.
UINode _dropView(MaterialInkDrop drop, BoxColor ink) {
  final double diameter = materialInkSpread * drop.progress;

  return PositionedNode(
    left: 0,
    top: 0,
    child: Box(
      width: diameter,
      height: diameter,
      borderRadius: diameter / 2,
      backgroundColor: ink,
      opacity: materialInkOpacity * (1 - drop.progress),
      transform: BoxTransform(
        offsetX: drop.position.x - diameter / 2,
        offsetY: drop.position.y - diameter / 2,
      ),
    ),
  );
}
