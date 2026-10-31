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
/// second layer of boxes whose scale and opacity come from [MaterialInkStore].
/// The node buys the combination — the three layers, a short transition so a
/// tint eases instead of flashing, the ink, and the button role when the region
/// can be tapped.
///
/// **It paints no surface unless it is given one.** The ink and the tints have to sit
/// *above* the fill they belong to, so by default the filled box goes around the ink
/// well, not inside it; wrapped the other way round the fill would hide both. Pass
/// [fill] — and [border] with it — and the well paints that surface itself, under the
/// tints: a box has one background, so the two are composited into the one colour it
/// can paint, which is the same arithmetic a host does when it paints a hover into a
/// button's fill. The tints are a box of their own and take the shape's size and its
/// floors, so the two cover the same rectangle: a tint is the shape, never a smaller one
/// drawn inside it. The well clips its own content to [borderRadius], which is how a drop
/// stays inside a rounded button.
///
/// **A target can be taller than the shape.** A chip paints 32 pixels and a finger
/// needs 48: [tapTargetHeight] makes the region a caller can hit taller than the pill it
/// paints, and the pill is centred in it. The tints and the ink stay on the shape — a
/// tint is the shape — so hovering the extra room takes the press but paints nothing.
/// Material does the same thing with its padded tap target, and the room is layout, not
/// paint: a row of chips is as tall as the target.
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
  ///
  /// [fill] and [border] are the surface the well tints, when it paints one itself;
  /// [tapTargetHeight] is a target taller than [height], which the shape is centred
  /// in. A target needs a [height] to centre within, so it is ignored by a well that
  /// hugs its content.
  ///
  /// [minWidth] and [minHeight] are floors on the shape — the box that takes the press —
  /// rather than on a fill around it: a control smaller than the pill it paints has ends
  /// that look pressable and are not, which is what Material's own minimum size prevents.
  /// A floor never clamps: a label taller than it grows the shape. The tints are a box of
  /// their own and take the same floor and the same size, so a floor can never leave a
  /// tint behind: the pill of a `minHeight` is tinted, not only the line of its label.
  ///
  /// [url] makes the region a destination rather than a callback: the anchor is wherever
  /// the press is, so the browser follows it with no runtime, a crawler reads it, and a
  /// press still ripples. [shadows] and [textStyle] are what let one well be a whole
  /// surface — a card — instead of a press inside somebody else's box.
  MaterialInkWell({
    super.key,
    required UINode child,
    TapCallback? onTap,
    LongPressCallback? onLongPress,
    HoverCallback? onHover,
    String? url,
    bool newTab = false,
    bool enabled = true,
    BoxSpacing? margin,
    BoxSpacing? padding,
    double? width,
    double? height,
    double? minWidth,
    double? minHeight,
    int? flex,
    double? borderRadius,
    BoxColor? fill,
    BoxBorder? border,
    List<BoxShadow>? shadows,
    BoxTextStyle? textStyle,
    double? tapTargetHeight,
    BoxColor ink = defaultInk,
    BoxSemantics? semantics,
    BoxTransition transition = defaultTransition,
    BoxStyle? hoverStyle,
    BoxStyle? focusStyle,
    BoxStyle? pressedStyle,
    MainAlign? mainAlign,
    CrossAlign? crossAlign,
  }) : assert(
         tapTargetHeight == null || height != null,
         'A tap target taller than the shape needs a height to centre the shape in.',
       ),
       super(
         create: MaterialInkStore.new,
         view: (MaterialInkState state, MaterialInkStore store) => _inkWellView(
           state,
           store,
           child: child,
           onTap: onTap,
           onLongPress: onLongPress,
           onHover: onHover,
           url: url,
           newTab: newTab,
           enabled: enabled,
           margin: margin,
           padding: padding,
           width: width,
           height: height,
           minWidth: minWidth,
           minHeight: minHeight,
           flex: flex,
           borderRadius: borderRadius,
           fill: fill,
           border: border,
           shadows: shadows,
           textStyle: textStyle,
           tapTargetHeight: tapTargetHeight,
           ink: ink,
           semantics: semantics,
           transition: transition,
           hoverStyle: hoverStyle,
           focusStyle: focusStyle,
           pressedStyle: pressedStyle,
           mainAlign: mainAlign,
           crossAlign: crossAlign,
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

/// The well, its ink and its content, as one box — or two layers of box when it paints
/// a surface, and three when the target is taller than the shape.
///
/// The layers are painted in this order: the surface (given to the well, or painted by
/// the box around it), the tints, the ink and the content. The ink goes under the
/// content and above the tints because a drop is meant to be read through the label,
/// not over it.
///
/// A fill and a tint have to be two boxes, because a box paints one background: the
/// well's own box carries the surface and clips it, and a box inside it carries the
/// three state layers. The tints cannot be composited into the fill either — a role has
/// no channels until a theme resolves it, which happens at render time and not while
/// the tree is built.
///
/// The drops sit in the stack under the tints, and the well clips them to its radius.
/// Clipping at the well rather than in a filling layer is what keeps the ripple off a
/// rule the model does not have: a child that fills a positioned parent does not fill
/// on the web, so every box in the ink carries its own size.
///
/// When [tapTargetHeight] is taller than [height] there is one more box outside: the
/// target, with the shape centred in it. The tints, the ink, the surface and the clip
/// belong to the shape; only the presses belong to the room around it, and every press
/// is moved into the shape's own coordinates so a drop still starts where it landed.
UINode _inkWellView(
  MaterialInkState state,
  MaterialInkStore store, {
  required UINode child,
  required TapCallback? onTap,
  required LongPressCallback? onLongPress,
  required HoverCallback? onHover,
  required String? url,
  required bool newTab,
  required bool enabled,
  required BoxSpacing? margin,
  required BoxSpacing? padding,
  required double? width,
  required double? height,
  required double? minWidth,
  required double? minHeight,
  required int? flex,
  required double? borderRadius,
  required BoxColor? fill,
  required BoxBorder? border,
  required List<BoxShadow>? shadows,
  required BoxTextStyle? textStyle,
  required double? tapTargetHeight,
  required BoxColor ink,
  required BoxSemantics? semantics,
  required BoxTransition transition,
  required BoxStyle? hoverStyle,
  required BoxStyle? focusStyle,
  required BoxStyle? pressedStyle,
  required MainAlign? mainAlign,
  required CrossAlign? crossAlign,
}) {
  // A destination is pressable with no callback: the press is what opens it, and a
  // control that does not ripple when it navigates reads as a dead one.
  final bool pressable =
      enabled && (onTap != null || onLongPress != null || url != null);

  // The room a taller target keeps above and below the shape, on each side.
  final double slop = tapTargetHeight != null && height != null
      ? ((tapTargetHeight - height) / 2).clamp(0, double.infinity)
      : 0;

  void press(BoxTapEvent event) => store.press(
    slop == 0 ? event.position : _insideShape(event.position, slop),
  );

  final BoxSemantics? resolvedSemantics =
      semantics ??
      (onTap == null ? null : const BoxSemantics(role: BoxRole.button));

  // The stack fills the well across its cross axis, so a well given a size is filled
  // rather than hugged: the tints belong to the whole region, not to the label inside
  // it. A *full width* well stretches by default — a web flex column otherwise shrinks
  // the stack to its content — while one with no width of its own is a chip in a row and
  // has nothing to stretch to. A caller can always say.
  final CrossAlign resolvedCross =
      crossAlign ??
      (width == double.infinity ? CrossAlign.stretch : CrossAlign.start);

  final UINode stack = StackNode(
    children: <UINode>[
      for (final MaterialInkDrop drop in state.drops) _dropView(drop, ink),
      // The content sizes the stack; a drop takes no room of its own.
      // The cell is a flex row on the web, which sizes its box to the content.
      Box(
        width: width == double.infinity ? double.infinity : null,
        crossAlign: width == double.infinity
            ? CrossAlign.stretch
            : CrossAlign.start,
        padding: padding,
        children: <UINode>[child],
      ),
    ],
  );

  // The three state layers, over whatever surface is under them.
  final Box tints = Box(
    // The shape's own size, so the tints cover it and not only the content inside it: a
    // tint is a box of its own, and a box takes its size from its own tokens. Stated once
    // on the shape alone, a `width` or a `height` never reached this layer, and the tints
    // hugged the label — 44 by 24 inside a 64 by 32 pill, a lozenge drawn in a lozenge.
    width: width,
    height: height,
    // The floor is the shape's too, for the same reason: a pill held up by `minHeight`
    // and a tint that only knows the label are two different boxes, so the layer the
    // pointer lights stopped short of the pill it belongs to. Where the shape's size comes
    // from outside the tree — a parent that stretches it, a `flex` share — the tint hugs
    // the content the shape hugs, which is why a well that must fill a stretched parent
    // still wants `width: double.infinity` or a `crossAlign` of its own.
    minWidth: minWidth,
    minHeight: minHeight,
    borderRadius: borderRadius,
    mainAlign: mainAlign,
    crossAlign: resolvedCross,
    transition: transition,
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
    children: <UINode>[stack],
  );

  // A well with a surface, or with a target taller than its shape, is layered: the
  // outer box is the surface and the clip, and the tints are one box inside it. A well
  // with neither stays one box, which is what it has always been.
  final bool layered = fill != null || border != null || slop > 0;

  /// The region the well draws, as the link [interactive] says it may be.
  ///
  /// The anchor goes where the press is: on the shape when the shape is the region, and on
  /// the target around it when one was added, because an `<a>` inside an `<a>` is not a link
  /// at all. A link is a box, so this is one node either way — the type is the only
  /// difference, which is why the reason for it is stated here and nowhere else.
  UINode shape({required bool interactive}) {
    final Box box = Box(
      onTap: interactive ? onTap : null,
      onTapDown: interactive && pressable ? press : null,
      onLongPress: interactive ? onLongPress : null,
      onHover: interactive ? onHover : null,
      enabled: enabled,
      margin: interactive ? margin : null,
      flex: interactive ? flex : null,
      semantics: interactive ? resolvedSemantics : null,
      width: width,
      height: height,
      // The floor belongs to the box that takes the press: a pill painted around a
      // control smaller than itself has ends that look pressable and are not.
      minWidth: minWidth,
      minHeight: minHeight,
      backgroundColor: fill,
      border: border,
      shadows: shadows,
      textStyle: textStyle,
      borderRadius: borderRadius,
      overflow: Overflow.hidden,
      mainAlign: mainAlign,
      crossAlign: resolvedCross,
      transition: transition,
      // With no surface of its own the tints are the shape, so they stay on this box.
      hoverStyle: layered ? null : tints.hoverStyle,
      stateStyles: layered ? null : tints.stateStyles,
      children: <UINode>[if (layered) tints else stack],
    );

    final String? href = interactive ? url : null;

    return href == null ? box : LinkNode.of(box, href, newTab: newTab);
  }

  if (slop == 0) {
    // One box: the region a caller presses is the region it paints.
    return shape(interactive: true);
  }

  final Box target = Box(
    onTap: onTap,
    onTapDown: pressable ? press : null,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    margin: margin,
    width: width,
    height: tapTargetHeight,
    flex: flex,
    // The shape is painted in the middle of the target, so the room a finger gets is
    // the same above and below the pill it aims at.
    mainAlign: MainAlign.center,
    crossAlign: CrossAlign.center,
    semantics: resolvedSemantics,
    children: <UINode>[shape(interactive: false)],
  );
  final String? href = url;

  return href == null ? target : LinkNode.of(target, href, newTab: newTab);
}

/// [position] moved into the shape, which a taller target centres in itself.
BoxPoint _insideShape(BoxPoint position, double slop) =>
    BoxPoint(position.x, (position.y - slop).clamp(0, double.infinity));

/// One drop: a circle centred on the press, growing as it fades.
///
/// It is a circle of [materialInkSpread] *scaled* out of nothing, not a circle that is given
/// a new size every frame. Both paint the same pixels — a scaled circle is a circle — and only
/// the first is affordable: a width, a height, a corner radius and the offset that keeps a
/// growing circle over the press are new numbers every frame, and on the web a number is a
/// class, so every frame of every press wrote a rule the sheet keeps for the life of the page.
/// A page that had been tapped a hundred times carried three thousand rules the ripple would
/// never wear again, and rewrote all of them sixty times a second because each frame added one
/// more.
///
/// Scaling moves two numbers, and they are the same two on every press, so a ripple needs a
/// fixed set of looks the sheet is asked for once: a well pressed a hundred times writes no
/// rule after the first press. That is the same reason `MaterialSpinStore` counts steps rather
/// than degrees — a turn that repeats its looks is a turn that stops costing anything.
///
/// The centre is snapped to a whole pixel for the same reason: a hundredth of a pixel of a 280
/// pixel circle is not a look, and two taps on one button should not be two of them. A drop is
/// placed by its wrapper and painted by its own box, so the press point lands in a rule written
/// once per pixel while the animation lands in rules shared by every press anywhere.
UINode _dropView(MaterialInkDrop drop, BoxColor ink) {
  const double radius = materialInkSpread / 2;

  return PositionedNode(
    // The corner of the box that puts the circle's centre on the pixel that was pressed.
    left: drop.position.x.roundToDouble() - radius,
    top: drop.position.y.roundToDouble() - radius,
    child: Box(
      width: materialInkSpread,
      height: materialInkSpread,
      borderRadius: radius,
      backgroundColor: ink,
      opacity: materialInkOpacity * (1 - drop.progress),
      transform: BoxTransform(scale: drop.progress),
    ),
  );
}
