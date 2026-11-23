part of 'box.dart';

/// A line that is as tall — or as wide — as its tallest item when nothing gave it an end.
///
/// A stretch is CSS's `align-items: stretch`, and the half of it that Flutter's own
/// `CrossAxisAlignment.stretch` cannot express is where the line's extent comes from: a
/// browser makes the line as tall as its tallest item and fills the rest to it, so a row
/// inside a column that scrolls has a height although nothing above it stated one. A flex
/// handed an endless cross axis refuses instead — "BoxConstraints forces an infinite height"
/// — because it is asked to fill an extent that does not exist yet.
///
/// So the line is laid out twice when it has no end: once as it is, to find the tallest item,
/// and once tight to that extent, which is the extent the items then fill. A line that *was*
/// given an end — a row in a box that states its height, a `flex` child of a column — is laid
/// out once and costs nothing, which is every stretch that already worked.
class _StretchedLine extends SingleChildRenderObjectWidget {
  const _StretchedLine({required this.across, required super.child});

  /// The axis the items fill: the cross axis of the line, which is the axis of the extent
  /// that has to be measured.
  final Axis across;

  @override
  _RenderStretchedLine createRenderObject(BuildContext context) =>
      _RenderStretchedLine(across);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStretchedLine renderObject,
  ) {
    renderObject.across = across;
  }
}

class _RenderStretchedLine extends RenderProxyBox {
  _RenderStretchedLine(this._across);

  Axis _across;

  set across(Axis value) {
    if (value == _across) {
      return;
    }

    _across = value;
    markNeedsLayout();
  }

  bool _hasEnd(BoxConstraints constraints) => _across == Axis.vertical
      ? constraints.hasBoundedHeight
      : constraints.hasBoundedWidth;

  @override
  void performLayout() {
    final RenderBox? child = this.child;

    if (child == null) {
      size = constraints.smallest;

      return;
    }

    if (_hasEnd(constraints)) {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);

      return;
    }

    // No end to fill: the line is as tall as the tallest item, which is what a browser
    // resolves `align-items: stretch` against. Measured on a first pass and filled on a
    // second, so the items are handed a number rather than an infinity.
    final BoxConstraints unbounded = _across == Axis.vertical
        ? constraints.copyWith(maxHeight: double.infinity)
        : constraints.copyWith(maxWidth: double.infinity);

    child.layout(unbounded, parentUsesSize: true);

    final double extent = _across == Axis.vertical
        ? child.size.height
        : child.size.width;
    final BoxConstraints tight = _across == Axis.vertical
        ? constraints.copyWith(minHeight: extent, maxHeight: extent)
        : constraints.copyWith(minWidth: extent, maxWidth: extent);

    child.layout(tight, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}

/// Fills the room it is offered on one axis, and asks for nothing when there is none.
///
/// This is the other half of a stretch: an item whose cross size is `auto` fills the line,
/// and the line is as tall as its tallest item. `SizedBox(height: double.infinity)` was the
/// earlier spelling and could not express the second half — an infinity inside a line that
/// has no end is the constraint Flutter refuses, and it is also a number an intrinsic pass
/// cannot measure, so the line could not be measured before it was filled.
///
/// The fill is only ever as big as the room offered: a line measured at 300 fills 300, and a
/// line with no end at all leaves the child at its own size, which is what makes the two-pass
/// layout of [_StretchedLine] possible.
class _FillCross extends SingleChildRenderObjectWidget {
  const _FillCross({required this.across, required super.child});

  /// The axis to fill.
  final Axis across;

  @override
  _RenderFillCross createRenderObject(BuildContext context) =>
      _RenderFillCross(across);

  @override
  void updateRenderObject(BuildContext context, _RenderFillCross renderObject) {
    renderObject.across = across;
  }
}

class _RenderFillCross extends RenderProxyBox {
  _RenderFillCross(this._across);

  Axis _across;

  set across(Axis value) {
    if (value == _across) {
      return;
    }

    _across = value;
    markNeedsLayout();
  }

  /// The constraints that fill [available] on this axis, or `null` when there is nothing to
  /// fill because the axis has no end.
  BoxConstraints? _fill(BoxConstraints available) {
    if (_across == Axis.vertical) {
      return available.hasBoundedHeight
          ? BoxConstraints.tightFor(height: available.maxHeight)
                .enforce(available)
          : null;
    }

    return available.hasBoundedWidth
        ? BoxConstraints.tightFor(width: available.maxWidth).enforce(available)
        : null;
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;

    if (child == null) {
      size = constraints.smallest;

      return;
    }

    child.layout(_fill(constraints) ?? constraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}
