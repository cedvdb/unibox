/// A shape a box can be painted in, instead of its rectangle.
///
/// A shape is a path in a **view box**: the outline is written in the coordinates
/// it was authored in and then stretched to the box, so one value draws the same
/// silhouette at any size. The view box is what makes a shape reusable — paste an
/// SVG's `viewBox` and its `d` and the outline is the same, without dividing every
/// number by the box's width.
///
/// ```dart
/// // A hexagon badge: six edges of a 100 by 100 view box.
/// const BoxShape hexagon = BoxShape(
///   viewBoxWidth: 100,
///   viewBoxHeight: 100,
///   commands: <BoxPathCommand>[
///     BoxPathMoveTo(50, 0),
///     BoxPathLineTo(93, 25),
///     BoxPathLineTo(93, 75),
///     BoxPathLineTo(50, 100),
///     BoxPathLineTo(7, 75),
///     BoxPathLineTo(7, 25),
///     BoxPathClose(),
///   ],
/// );
///
/// Box(width: 40, height: 40, shape: hexagon, backgroundColor: BoxColor.white)
/// ```
///
/// **What a shape is.** The box's painted region: its background fills the path,
/// its border is a stroke along the path, and [fillRule] decides what counts as
/// inside — [BoxFillRule.evenOdd] is what turns two circles into a ring. The
/// box's layout does not change: children are laid out in the same rectangle as
/// before, and a shape clips them only when the box also says
/// `overflow: Overflow.hidden`.
///
/// **What a shape is not.** It does not cast a shadow, it cannot be eased (there
/// are no numbers to interpolate between two outlines), and it cannot combine two
/// outlines: `validateTree` reports a shaped box with a shadow, and an effect that
/// has to union or subtract outlines is what `EmbedNode` is for.
///
/// Coordinates are read the way SVG reads them: `y` grows downwards and an arc
/// sweeps clockwise. Both renderers build their path from [commands] — Flutter a
/// `Path`, the web an SVG `d` — so neither parses what the other wrote.
final class BoxShape {
  /// Creates a shape drawn in a [viewBoxWidth] by [viewBoxHeight] space.
  const BoxShape({
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.commands,
    this.fillRule = BoxFillRule.nonZero,
  });

  /// A circle filling a square view box.
  ///
  /// Two half turns rather than an ellipse primitive, because that is what the
  /// command vocabulary has — and a renderer that draws two arcs is drawing
  /// exactly what the web writes in its `d`.
  static const BoxShape circle = BoxShape(
    viewBoxWidth: 100,
    viewBoxHeight: 100,
    commands: <BoxPathCommand>[
      BoxPathMoveTo(50, 0),
      BoxPathArcTo(50, 100, radiusX: 50, radiusY: 50),
      BoxPathArcTo(50, 0, radiusX: 50, radiusY: 50),
    ],
  );

  /// The width of the coordinate space the [commands] are written in.
  final double viewBoxWidth;

  /// The height of the coordinate space the [commands] are written in.
  final double viewBoxHeight;

  /// The outline, one command at a time, painted in order.
  final List<BoxPathCommand> commands;

  /// Which parts of the outline count as inside.
  final BoxFillRule fillRule;

  /// Whether this shape draws nothing.
  ///
  /// A shape with no command paints an empty path, so a box wearing one shows no
  /// background and no border; `validateTree` reports it, because it is almost
  /// always a mistake.
  bool get isEmpty => commands.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is BoxShape &&
      other.viewBoxWidth == viewBoxWidth &&
      other.viewBoxHeight == viewBoxHeight &&
      other.fillRule == fillRule &&
      other.commands.length == commands.length &&
      <int>[for (int i = 0; i < commands.length; i++) i]
          .every((int i) => other.commands[i] == commands[i]);

  @override
  int get hashCode => Object.hash(
    viewBoxWidth,
    viewBoxHeight,
    fillRule,
    Object.hashAll(commands),
  );

  @override
  String toString() =>
      'BoxShape(${viewBoxWidth}x$viewBoxHeight, $fillRule, '
      '${commands.length} commands)';
}

/// Which parts of a shape's outline count as inside it.
enum BoxFillRule {
  /// A point is inside when a ray from it crosses the outline an odd number of
  /// times in either direction: overlapping subpaths fill.
  nonZero,

  /// A point is inside when a ray from it crosses the outline an odd number of
  /// times: a subpath drawn inside another punches a hole, which is what turns
  /// two circles into a ring.
  evenOdd,
}

/// One command of a [BoxShape], in the shape's view box.
///
/// The commands are the ones SVG's `d` attribute has, and every renderer has a

/// Starts a new subpath at ([x], [y]).
final class BoxPathMoveTo extends BoxPathCommand {
  /// Creates a move to ([x], [y]).
  const BoxPathMoveTo(this.x, this.y);

  /// The x coordinate in the shape's view box.
  final double x;

  /// The y coordinate in the shape's view box.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is BoxPathMoveTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'BoxPathMoveTo($x, $y)';
}

/// Draws a straight line from the current point to ([x], [y]).
final class BoxPathLineTo extends BoxPathCommand {
  /// Creates a line to ([x], [y]).
  const BoxPathLineTo(this.x, this.y);

  /// The x coordinate in the shape's view box.
  final double x;

  /// The y coordinate in the shape's view box.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is BoxPathLineTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'BoxPathLineTo($x, $y)';
}

/// Draws a cubic Bézier curve from the current point to ([x], [y]).
final class BoxPathCubicTo extends BoxPathCommand {
  /// Creates a cubic curve to ([x], [y]) through two control points.
  const BoxPathCubicTo(
    this.control1X,
    this.control1Y,
    this.control2X,
    this.control2Y,
    this.x,
    this.y,
  );

  /// The x of the first control point.
  final double control1X;

  /// The y of the first control point.
  final double control1Y;

  /// The x of the second control point.
  final double control2X;

  /// The y of the second control point.
  final double control2Y;

  /// The x the curve ends at.
  final double x;

  /// The y the curve ends at.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is BoxPathCubicTo &&
      other.control1X == control1X &&
      other.control1Y == control1Y &&
      other.control2X == control2X &&
      other.control2Y == control2Y &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode =>
      Object.hash(control1X, control1Y, control2X, control2Y, x, y);

  @override
  String toString() =>
      'BoxPathCubicTo($control1X, $control1Y, $control2X, $control2Y, $x, $y)';
}

/// Draws a quadratic Bézier curve from the current point to ([x], [y]).
final class BoxPathQuadraticTo extends BoxPathCommand {
  /// Creates a quadratic curve to ([x], [y]) through one control point.
  const BoxPathQuadraticTo(this.controlX, this.controlY, this.x, this.y);

  /// The x of the control point.
  final double controlX;

  /// The y of the control point.
  final double controlY;

  /// The x the curve ends at.
  final double x;

  /// The y the curve ends at.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is BoxPathQuadraticTo &&
      other.controlX == controlX &&
      other.controlY == controlY &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(controlX, controlY, x, y);

  @override
  String toString() => 'BoxPathQuadraticTo($controlX, $controlY, $x, $y)';
}

/// method for each: `M`, `L`, `C`, `Q`, `A` and `Z`.
sealed class BoxPathCommand {
  /// Creates a command.
  const BoxPathCommand();
}

/// Draws an elliptical arc from the current point to ([x], [y]).
///
/// [clockwise] and [largeArc] are SVG's sweep and large-arc flags: with the two
/// of them and the radii, exactly one arc is described, which is why an arc can be
/// written without knowing where it started.
final class BoxPathArcTo extends BoxPathCommand {
  /// Creates an arc to ([x], [y]) with the given radii.
  const BoxPathArcTo(
    this.x,
    this.y, {
    required this.radiusX,
    required this.radiusY,
    this.rotation = 0,
    this.largeArc = false,
    this.clockwise = true,
  });

  /// The x the arc ends at.
  final double x;

  /// The y the arc ends at.
  final double y;

  /// The radius of the ellipse along its own x axis.
  final double radiusX;

  /// The radius of the ellipse along its own y axis.
  final double radiusY;

  /// The rotation of the ellipse in degrees, clockwise.
  final double rotation;

  /// Whether the arc takes the long way round.
  final bool largeArc;

  /// Whether the arc is drawn clockwise.
  final bool clockwise;

  @override
  bool operator ==(Object other) =>
      other is BoxPathArcTo &&
      other.x == x &&
      other.y == y &&
      other.radiusX == radiusX &&
      other.radiusY == radiusY &&
      other.rotation == rotation &&
      other.largeArc == largeArc &&
      other.clockwise == clockwise;

  @override
  int get hashCode =>
      Object.hash(x, y, radiusX, radiusY, rotation, largeArc, clockwise);

  @override
  String toString() =>
      'BoxPathArcTo($x, $y, radiusX: $radiusX, radiusY: $radiusY, '
      'rotation: $rotation, largeArc: $largeArc, clockwise: $clockwise)';
}

/// Closes the current subpath, joining its last point to its first.
final class BoxPathClose extends BoxPathCommand {
  /// Creates a close command.
  const BoxPathClose();

  @override
  bool operator ==(Object other) => other is BoxPathClose;

  @override
  int get hashCode => const BoxPathClose().runtimeType.hashCode;

  @override
  String toString() => 'BoxPathClose()';
}
