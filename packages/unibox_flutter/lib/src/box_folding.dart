part of 'box.dart';

class _FoldedBox extends SingleChildRenderObjectWidget {
  const _FoldedBox({
    required this.position,
    required this.fold,
    required this.resting,
    required this.folded,
    required super.child,
  });

  /// The scroll the fold follows, which is the nearest one above the box.
  final ScrollPosition position;

  /// The fold: which looks move, how far it takes, and how they ease.
  final core.BoxFold fold;

  /// The look the box has at rest.
  final core.BoxStyle resting;

  /// The look it has once it has left.
  final core.BoxStyle folded;

  @override
  _RenderFoldedBox createRenderObject(BuildContext context) => _RenderFoldedBox(
    position,
    fold,
    resting,
    folded,
    Directionality.maybeOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderFoldedBox renderObject) {
    renderObject
      ..position = position
      ..fold = fold
      ..resting = resting
      ..folded = folded
      ..textDirection = Directionality.maybeOf(context);
  }
}

/// Where a [_FoldedBox] paints, and how far into the fold it is.
class _RenderFoldedBox extends RenderProxyBox {
  _RenderFoldedBox(
    this._position,
    this._fold,
    this._resting,
    this._folded,
    this._textDirection,
  );

  ScrollPosition _position;
  core.BoxFold _fold;
  core.BoxStyle _resting;
  core.BoxStyle _folded;
  TextDirection? _textDirection;

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

  set fold(core.BoxFold value) {
    if (value == _fold) {
      return;
    }

    _fold = value;
    markNeedsPaint();
  }

  set resting(core.BoxStyle value) {
    if (value == _resting) {
      return;
    }

    _resting = value;
    markNeedsPaint();
  }

  set folded(core.BoxStyle value) {
    if (value == _folded) {
      return;
    }

    _folded = value;
    markNeedsPaint();
  }

  set textDirection(TextDirection? value) {
    if (value == _textDirection) {
      return;
    }

    _textDirection = value;
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

  /// Repaints the box under the look the scroll offset now asks for.
  void _scrollChanged() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// How far into the fold the box is, from where it sits in its viewport.
  ///
  /// The quantity a browser takes from `view()`: the box's leading edge has travelled from the
  /// scrollport's start edge to a whole box above it, which is zero at rest and one once the box
  /// has gone. A box that has never reached the top, or a page with no viewport at all, reads as
  /// the resting look rather than as a fold that has arrived.
  double get _progress {
    final RenderObject? found = RenderAbstractViewport.maybeOf(this);

    if (found is! RenderBox || !found.attached || !attached || size.isEmpty) {
      return 0;
    }

    final double viewport = found.size.height;

    if (viewport <= 0) {
      return 0;
    }

    final double top = localToGlobal(Offset.zero, ancestor: found).dy;
    final double left = (-top / size.height).clamp(0.0, 1.0);

    return toCurve(_fold.curve).transform(_fold.progressAt(left));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double t = _progress;
    final BoxDecoration? decoration = _decorationAt(t);

    if (decoration != null) {
      // A decoration paints through a painter of its own: `BoxDecoration` has no `paint`, and
      // the painter is the one thing that knows how a shape is drawn at a size.
      final BoxPainter painter = decoration.createBoxPainter();

      painter.paint(
        context.canvas,
        offset,
        ImageConfiguration(size: size, textDirection: _textDirection),
      );
      painter.dispose();
    }

    final RenderBox? child = this.child;

    if (child == null) {
      return;
    }

    final double opacity = lerpDouble(
      (_resting.opacity ?? 1).clamp(0.0, 1.0),
      (_folded.opacity ?? 1).clamp(0.0, 1.0),
      t,
    )!;
    final Matrix4? matrix = _matrixAt(t);

    void paintChild(PaintingContext context, Offset offset) {
      if (matrix == null) {
        context.paintChild(child, offset);
        return;
      }

      context.pushTransform(
        false,
        offset,
        matrix,
        (PaintingContext context, Offset offset) =>
            context.paintChild(child, offset),
      );
    }

    if (opacity >= 1) {
      paintChild(context, offset);
      return;
    }

    context.pushOpacity(offset, (opacity * 255).round(), paintChild);
  }

  /// The decoration at [t], or `null` when the fold moves none of it.
  BoxDecoration? _decorationAt(double t) {
    final Set<core.BoxProperty> looks = _fold.looks;
    final bool moves =
        looks.contains(core.BoxProperty.backgroundColor) ||
        looks.contains(core.BoxProperty.borderColor) ||
        looks.contains(core.BoxProperty.borderRadius) ||
        looks.contains(core.BoxProperty.shadows);
    final BoxDecoration? from = toDecoration(_resting);

    if (!moves) {
      return from;
    }

    return BoxDecoration.lerp(from, toDecoration(_folded) ?? from, t);
  }

  /// The transform at [t], or `null` when the box is not moved.
  ///
  /// The matrix is applied about the box's centre, as a resting `transform` is, and the fraction
  /// of the box's own size is added as the translation a `FractionalTranslation` would make.
  Matrix4? _matrixAt(double t) {
    if (!_fold.looks.contains(core.BoxProperty.transform)) {
      return null;
    }

    final core.BoxTransform value = core.BoxTransform.lerp(
      _resting.transform ?? const core.BoxTransform(),
      _folded.transform ?? const core.BoxTransform(),
      t,
    );
    final Matrix4 matrix = toMatrix4(value);

    if (value.fractionX != 0 || value.fractionY != 0) {
      matrix.multiply(
        Matrix4.translationValues(
          value.fractionX * size.width,
          value.fractionY * size.height,
          0,
        ),
      );
    }

    final Offset centre = size.center(Offset.zero);

    return Matrix4.translationValues(centre.dx, centre.dy, 0)
      ..multiply(matrix)
      ..multiply(Matrix4.translationValues(-centre.dx, -centre.dy, 0));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;
    final Matrix4? matrix = _matrixAt(_progress);

    if (child == null) {
      return false;
    }

    if (matrix == null) {
      return child.hitTest(result, position: position);
    }

    // A box that is scaled is pressed where it is painted, which is what a resting transform
    // already does through the `Transform` widget.
    return child.hitTest(
      result,
      position: MatrixUtils.transformPoint(Matrix4.inverted(matrix), position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Matrix4? matrix = _matrixAt(_progress);

    if (matrix != null) {
      transform.multiply(matrix);
    }
  }
}
