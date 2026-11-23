part of 'box.dart';

/// How one look group of a box is animated: over what, and with which curve.
///
/// The curve is an `Interval` when the look waits for another one to settle, which
/// is how a delay is expressed without a controller.
typedef _Timing = ({Duration duration, Curve curve});

/// A bar drawn over its viewport at the edge it pins to.
///
/// It takes the whole width of the viewport and the height its own content asks for, and
/// paints at the place the scroll offset puts it. Painting rather than rebuilding is what
/// makes the pin cheap: a scroll asks the layer to repaint, the bar's own subtree is built
/// once, and a field or a menu inside it keeps its state while it is being carried around.
///
/// The height is measured rather than stated, which is what lets a bar whose content wraps
/// pin: the slot it keeps in the flow reads [height] back, so a filter row that takes a
/// second line on a narrow window is as tall as the label it could not fit.
///
/// The slot the bar keeps in the flow is a [RenderObject] of its own, and the bar reads
/// its position from it in [RenderBox.performLayout] — after the flow has been laid out and
/// before anything is painted, so the first frame is drawn where the bar belongs.
class _PinnedBar extends SingleChildRenderObjectWidget {
  const _PinnedBar({
    super.key,
    required this.scroll,
    required this.pin,
    required this.slot,
    required this.inset,
    required super.child,
  });

  /// The scroll offset the bar follows.
  ///
  /// The controller rather than its position: a bar is built before the viewport it
  /// belongs to is, so the position it will follow does not exist yet at that moment.
  final ScrollController scroll;

  /// The edge it comes to rest at.
  final core.BoxPin pin;

  /// The slot it keeps in the flow, whose position is where it settles back to.
  final GlobalKey slot;

  /// The room it keeps from the edge while it is pinned.
  final double inset;

  @override
  _RenderPinnedBar createRenderObject(BuildContext context) =>
      _RenderPinnedBar(scroll, pin, slot, inset);

  @override
  void updateRenderObject(BuildContext context, _RenderPinnedBar renderObject) {
    renderObject
      ..scroll = scroll
      ..pin = pin
      ..slot = slot
      ..inset = inset;
  }
}

/// Where a [_PinnedBar] paints: the layout of a box, the geometry of a sticky one.
class _RenderPinnedBar extends RenderProxyBox {
  _RenderPinnedBar(this._scroll, this._pin, this._slot, this._inset);

  ScrollController _scroll;
  core.BoxPin _pin;
  GlobalKey _slot;
  double _inset;

  /// The height the bar measured for itself in the last layout, which is the room its slot
  /// keeps in the flow.
  double _height = 0;

  set scroll(ScrollController value) {
    if (identical(value, _scroll)) {
      return;
    }

    if (attached) {
      _scroll.removeListener(_scrollChanged);
      value.addListener(_scrollChanged);
    }

    _scroll = value;
    markNeedsLayout();
  }

  set pin(core.BoxPin value) {
    if (value == _pin) {
      return;
    }

    _pin = value;
    markNeedsLayout();
  }

  set slot(GlobalKey value) {
    if (identical(value, _slot)) {
      return;
    }

    _slot = value;
    markNeedsLayout();
  }

  /// The height the bar laid itself out at, which is the room it keeps in the flow.
  ///
  /// Read by the slot the flow holds open for it, in the same layout pass and after this
  /// bar: the layer lays its children out in reverse for exactly this reason.
  double get height => _height;

  set inset(double value) {
    if (value == _inset) {
      return;
    }

    _inset = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scroll.addListener(_scrollChanged);
  }

  @override
  void detach() {
    _scroll.removeListener(_scrollChanged);
    super.detach();
  }

  /// Redraws the bar where the offset now puts it.
  ///
  /// A bar that moved is also a rectangle a screen reader has to be told about, and
  /// marking both is what keeps the announced box where the painted one is. With no
  /// semantics owner — the ordinary case — the second call is a flag check.
  void _scrollChanged() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    final BoxConstraints constraints = this.constraints;

    if (child != null) {
      // The bar keeps the width the viewport hands it — a viewport that is itself unconstrained
      // across leaves the bar its own width rather than an infinity no box can be laid out in —
      // and it is as tall as its own content asks. Measuring it is what the slot in the flow
      // reads, so a bar that wraps needs no stated height and no second build to learn one.
      child.layout(
        BoxConstraints(
          minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
          maxWidth: constraints.hasBoundedWidth
              ? constraints.maxWidth
              : double.infinity,
        ),
        parentUsesSize: true,
      );

      _height = child.size.height;
    }

    // The layer fills the viewport, and takes the bar's own height where the viewport was
    // not given an end to fill.
    size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : 0,
        constraints.hasBoundedHeight ? constraints.maxHeight : _height,
      ),
    );
  }

  /// The place the bar is painted, in this layer's coordinates.
  ///
  /// At rest it is where the flow put it. Once the content would have carried it past the
  /// edge it named, it keeps that edge's distance, and it goes no further than the box it
  /// is drawn in allows — the box a browser keeps a sticky element inside, which is why a
  /// bar that has nothing after it never comes away from its slot.
  ///
  /// Read when the bar is painted rather than once per layout: a scroll repaints without
  /// laying anything out, and the place a bar belongs is a fact about the scroll offset.
  double get _top {
    if (!_scroll.hasClients) {
      return 0;
    }

    final ScrollPosition position = _scroll.position;

    if (!position.hasViewportDimension || !position.hasContentDimensions) {
      return 0;
    }

    final double viewport = position.viewportDimension;
    final double scroll = position.pixels;
    final double edge = _pin == core.BoxPin.start
        ? _inset
        : viewport - _inset - _height;
    final double at = _slotTop ?? edge;

    if (_pin == core.BoxPin.start) {
      // It is never lifted above its slot, and never past the end of the content.
      final double end = position.maxScrollExtent + viewport - scroll - _height;

      return math.min(math.max(at, edge), end);
    }

    // The end edge is the mirror of the start one: never pushed below its slot, never
    // above the start of the content.
    return math.max(math.min(at, edge), -scroll);
  }

  /// Where the slot sits right now, in this layer's coordinates: where the bar would be
  /// if it did not pin.
  ///
  /// Read from the slot's own place in the tree rather than counted from the children above
  /// it, which would mean laying them out here a second time. The scroll offset is part of
  /// the transform, so this is the position on screen and not the position in the content.
  double? get _slotTop {
    final RenderObject? found = _slot.currentContext?.findRenderObject();
    final RenderObject? layer = parent;

    if (found is! RenderBox || !found.attached || layer == null) {
      return null;
    }

    final RenderBox slot = found;

    return slot.localToGlobal(Offset.zero, ancestor: layer).dy -
        localToGlobal(Offset.zero, ancestor: layer).dy;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;

    if (child != null) {
      context.paintChild(child, offset + Offset(0, _top));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;

    if (child == null) {
      return false;
    }

    return result.addWithPaintOffset(
      offset: Offset(0, _top),
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  // The bar is laid out where the flow would have put it and painted elsewhere, so the
  // offset it was painted at is the one everything else has to be told about: the position
  // a test reads, the rectangle a screen reader announces, and the box a press lands in.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(Matrix4.translationValues(0, _top, 0));
  }
}

/// A pin that the box it pins to does not hold: laid out in its parent's flow and painted
/// where the scroll puts it, inside that parent.
///
/// A browser states this as `position: sticky` on an element that is not the scroll
/// container's child, and resolves two rectangles — the scrollport the edge is measured
/// from, and the containing block the box may not leave. A viewport's own layer draws the
/// bars it holds; this is the other shape: a panel beside a column of cards, which comes to
/// rest under the header while the cards scroll and leaves with the column's bottom edge
/// rather than with the page's.
///
/// The layout is the flow's, so the slot keeps the room the panel takes and nothing below it
/// moves. Only the paint moves, which is why a field inside the panel keeps its state while
/// it is carried around: a scroll costs a repaint and never a rebuild.
class _NestedPin extends SingleChildRenderObjectWidget {
  const _NestedPin({
    required this.position,
    required this.pin,
    required this.inset,
    required super.child,
  });

  /// The scroll the pin follows, which is the nearest one above the box.
  final ScrollPosition position;

  /// The edge it comes to rest at.
  final core.BoxPin pin;

  /// The room it keeps from that edge.
  final double inset;

  @override
  _RenderNestedPin createRenderObject(BuildContext context) =>
      _RenderNestedPin(position, pin, inset);

  @override
  void updateRenderObject(BuildContext context, _RenderNestedPin renderObject) {
    renderObject
      ..position = position
      ..pin = pin
      ..inset = inset;
  }
}

/// Where a [_NestedPin] paints: the layout of a box, the geometry of a sticky one.
class _RenderNestedPin extends RenderProxyBox {
  _RenderNestedPin(this._position, this._pin, this._inset);

  ScrollPosition _position;
  core.BoxPin _pin;
  double _inset;

  set position(ScrollPosition value) {
    if (identical(value, _position)) {
      return;
    }

    if (attached) {
      _position.removeListener(_scrollChanged);
      value.addListener(_scrollChanged);
    }

    _position = value;
    markNeedsPaint();
  }

  set pin(core.BoxPin value) {
    if (value == _pin) {
      return;
    }

    _pin = value;
    markNeedsPaint();
  }

  set inset(double value) {
    if (value == _inset) {
      return;
    }

    _inset = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position.addListener(_scrollChanged);
  }

  @override
  void detach() {
    _position.removeListener(_scrollChanged);
    super.detach();
  }

  /// Redraws the pin where the offset now puts it.
  ///
  /// A box that moved is also a rectangle a screen reader has to be told about, and
  /// marking both is what keeps the announced box where the painted one is. With no
  /// semantics owner — the ordinary case — the second call is a flag check.
  void _scrollChanged() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The distance the box is painted from where the flow put it.
  ///
  /// Read when the box is painted rather than once per layout: a scroll repaints without
  /// laying anything out, and where a pin belongs is a fact about the scroll offset. The two
  /// rectangles are the ones a browser resolves the same way, read from the render tree
  /// instead of counted — the scrollport the edge is measured from, and the box that bounds
  /// the travel.
  double get _dy {
    final RenderObject? scrollport = RenderAbstractViewport.maybeOf(this);
    final RenderBox? holder = _containingBlock(scrollport);
    final ScrollPosition position = _position;

    if (!attached ||
        scrollport is! RenderBox ||
        holder == null ||
        !position.hasViewportDimension) {
      return 0;
    }

    final double at = localToGlobal(Offset.zero, ancestor: scrollport).dy;
    final double top = holder
        .localToGlobal(Offset.zero, ancestor: scrollport)
        .dy;
    final double bottom = top + holder.size.height;

    // The room the box it sits in leaves it. A browser bounds a sticky element by its
    // containing block, so a parent shorter than the panel leaves it nowhere to travel, and
    // the floor is the parent's own edge rather than a rectangle above it.
    final double lowest = math.max(top, bottom - size.height);
    final double edge = _pin == core.BoxPin.start
        ? _inset
        : position.viewportDimension - _inset - size.height;
    final double want = _pin == core.BoxPin.start
        // Never lifted above its slot, and never below the end of its parent.
        ? math.min(math.max(at, edge), lowest)
        // The mirror of it: never pushed below its slot, and never above the start of its
        // parent.
        : math.max(math.min(at, edge), top);

    return want - at;
  }

  /// The box the pin may not leave: its nearest box ancestor, unless that is the scrollport.
  ///
  /// A bar drawn straight into a viewport has no containing block to be held inside, and a pin
  /// that is a page of a pager sits in a sliver, where the nearest box above it is the viewport
  /// itself. `validateTree` reports both trees, and neither is translated here.
  RenderBox? _containingBlock(RenderObject? scrollport) {
    RenderObject? above = parent;

    while (above != null && above is! RenderBox) {
      above = above.parent;
    }

    final RenderObject? box = above;

    if (box is! RenderBox || identical(box, scrollport)) {
      return null;
    }

    return box;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;

    if (child != null) {
      context.paintChild(child, offset + Offset(0, _dy));
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // A press arrives at the place the box was painted, and the rectangle
    // `RenderBox.hitTest` measures it against is the one the flow laid out — so the point is
    // read back into the layout before the box decides it is over it.
    if (!size.contains(position - Offset(0, _dy)) ||
        !hitTestChildren(result, position: position)) {
      return false;
    }

    result.add(BoxHitTestEntry(this, position));

    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;

    if (child == null) {
      return false;
    }

    return result.addWithPaintOffset(
      offset: Offset(0, _dy),
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  // The panel is laid out where the flow would have put it and painted elsewhere, so the offset
  // it was painted at is the one everything else has to be told about: the position a test
  // reads, the rectangle a screen reader announces, and the box a press lands in.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(Matrix4.translationValues(0, _dy, 0));
  }
}

/// The content of a box that holds pinned bars: the flow, with the bars layered over it.
///
/// A `Stack` would almost do, and does not, for one reason: a stack lays its children out in
/// the order it paints them, and this layer needs the reverse. The slot a bar keeps in the
/// flow is the height the bar laid itself out at, so the bars have to be laid out *before*
/// the flow that reads them — and painted *after* it, because a bar covers the content that
/// scrolls under it.
class _PinnedLayer extends MultiChildRenderObjectWidget {
  const _PinnedLayer({required super.children});

  @override
  _RenderPinnedLayer createRenderObject(BuildContext context) =>
      _RenderPinnedLayer();
}

/// Where a child of a [_PinnedLayer] sits, which is nowhere: every child fills the layer.
final class _PinnedLayerData extends ContainerBoxParentData<RenderBox> {}

class _RenderPinnedLayer extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PinnedLayerData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PinnedLayerData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PinnedLayerData) {
      child.parentData = _PinnedLayerData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() {
    final Size extent = constraints.biggest;
    final BoxConstraints tight = BoxConstraints.tight(extent);

    // The flow is the first child and the bars follow it, which is the order they are painted
    // in; the order they are laid out in is the reverse, so the slot a bar leaves in the flow
    // is filled with a height this pass measured rather than the one the pass before it did.
    final List<RenderBox> ordered = <RenderBox>[];
    RenderBox? child = firstChild;

    while (child != null) {
      ordered.add(child);
      child = childAfter(child);
    }

    for (final RenderBox each in ordered.reversed) {
      // `parentUsesSize` on every one of them: a bar that grows its content has to relayout
      // the flow that keeps its room, and a slot is read from a bar, not owned by it.
      each.layout(tight, parentUsesSize: true);
    }

    size = extent;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A box painted under the look a fold has reached, in the viewport that scrolls it.
///
/// The layer paints; it does not rebuild. The decoration, the opacity and the transform are
/// interpolated when the box is painted, from how far it has travelled out of its viewport, so
/// a scroll costs a repaint of one layer and the box's children are built once. That is the
/// whole reason a fold may not move a layout: a frame of it is a look, and a look is a paint.

/// The room a pinned bar keeps in the flow, read from the bar's own layout.
///
/// A bar with no stated height is as tall as its content, which nobody knows until it has
/// been laid out: this is the widget that turns that measurement into the space the flow
/// holds open, so nothing below the bar moves when it is away at the edge. The number is read
/// from the bar's render object rather than passed through a callback, because a callback
/// would mean a rebuild and a frame drawn at the height of the frame before.
class _PinnedSlot extends LeafRenderObjectWidget {
  const _PinnedSlot({required this.bar, super.key});

  /// The key of the bar this slot keeps the room for.
  final GlobalKey bar;

  @override
  _RenderPinnedSlot createRenderObject(BuildContext context) =>
      _RenderPinnedSlot(bar);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPinnedSlot renderObject,
  ) {
    renderObject.bar = bar;
  }
}

class _RenderPinnedSlot extends RenderBox {
  _RenderPinnedSlot(this._bar);

  GlobalKey _bar;

  set bar(GlobalKey value) {
    if (identical(value, _bar)) {
      return;
    }

    _bar = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final RenderObject? found = _bar.currentContext?.findRenderObject();
    final double height = found is _RenderPinnedBar ? found.height : 0;

    // A slot keeps the room and no width: it sits in a column, where the cross axis is the
    // box's own business.
    size = constraints.constrain(Size(0, height));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => Size.zero;

  // The slot draws nothing — the bar it stands for is painted by the layer — so it takes no
  // press either: a press where the bar came from belongs to the content underneath it.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}
