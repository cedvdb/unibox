import 'package:unibox_core/unibox_core.dart' as core;

import 'token_difference.dart';

export 'token_difference.dart';

/// How a box is presented once it has been rendered.
///
/// The two renderers produce different kinds of output — a widget tree on one
/// side, HTML and CSS on the other — so the only thing that can be compared is
/// what the output *does* with a box: the axis it lays its children out on, how
/// it aligns and spaces them, how big it is and what it paints behind them.
///
/// A renderer suite reads these facts back from its own output and compares them
/// with the ones a [BoxCase] expects. Only what both targets can express exactly
/// is part of it: fonts, line breaking, shadow blur, placeholder and focus
/// colours and hit testing stay approximate on purpose, because a browser and a
/// Flutter `Text` never agree on them down to the pixel.
///
/// An absent token and a zero token describe the same presentation: both
/// renderers leave an empty padding, an empty gap and an invisible border out of
/// their output, so [differencesFrom] does not distinguish the two spellings.
final class BoxAppearance {
  /// Creates a description of the presentation of a rendered box.
  ///
  /// [direction], [mainAlign] and [crossAlign] have the same defaults the model
  /// resolves an unset token to, because both renderers state the layout of
  /// every box instead of leaving it to their own default.
  const BoxAppearance({
    this.direction = core.Axis.vertical,
    this.mainAlign = core.MainAlign.start,
    this.crossAlign = core.CrossAlign.start,
    this.gap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.aspectRatio,
    this.widthFraction,
    this.backgroundColor,
    this.borderRadius,
    this.corners,
    this.borderWidth,
    this.borderColor,
    this.transitionDuration,
    this.transitionCurve,
    this.opacity,
    this.transform,
  });

  /// The axis the children of the box are laid out on.
  final core.Axis direction;

  /// The alignment of the children along [direction].
  final core.MainAlign mainAlign;

  /// The alignment of the children across [direction].
  final core.CrossAlign crossAlign;

  /// The space the box keeps between two children, or `null` for none.
  final double? gap;

  /// The space the box keeps between its border and its children.
  final core.BoxSpacing? padding;

  /// The space the box keeps around its border.
  final core.BoxSpacing? margin;

  /// The width of the box in logical pixels, or `double.infinity` when it fills
  /// the space its parent gives it.
  final double? width;

  /// The width as a fraction of the parent's, or `null` when it is stated in pixels.
  final double? widthFraction;

  /// The height of the box in logical pixels, or `double.infinity` when it fills
  /// the space its parent gives it.
  final double? height;

  /// The width divided by the height the box keeps, or `null` for no ratio.
  ///
  /// Read back as a statement and not as a measurement: a ratio describes the shape
  /// the box will have at whatever width it is given, so the fact is the ratio the
  /// output declares — `aspect-ratio` on one side, the `AspectRatio` it built on the
  /// other — and not the size the box happened to settle on in one test surface.
  final double? aspectRatio;

  /// The colour painted behind the box, or `null` for none.
  final core.BoxColor? backgroundColor;

  /// The radius of the corners of the box, or `null` for square ones.
  final double? borderRadius;

  /// The four corners, when the box is not round on all four.
  final core.BoxBorderRadius? corners;

  /// The thickness of the line drawn around the box, or `null` for no border.
  final double? borderWidth;

  /// The colour of the border line, or `null` when there is no border.
  ///
  /// The colour only counts while [borderWidth] draws a line: a border that
  /// occupies no space is not painted, on either target.
  final core.BoxColor? borderColor;

  /// How long a change of look takes, or `null` when the box swaps instantly.
  ///
  /// A transition is the one part of a box that is about time rather than about
  /// paint, and it is expressible exactly on both targets — a duration and one of
  /// the five curves CSS and Flutter share the control points of — so the contract
  /// can pin it like any other token.
  final Duration? transitionDuration;

  /// The easing applied over [transitionDuration].
  final core.BoxCurve? transitionCurve;

  /// How opaque the box is, or `null` when it is solid.
  ///
  /// Like the transform, this is a paint of the box and not a layout token: a
  /// faded box keeps the room it was given.
  final double? opacity;

  /// How the box is moved, turned or scaled, or `null` when it is untransformed.
  ///
  /// An identity transform is compared as `null`: no transform and a transform
  /// that does nothing paint the same box.
  final core.BoxTransform? transform;

  /// Whether [borderWidth] draws a line at all.
  bool get _hasBorder => (borderWidth ?? 0) > 0;

  /// The tokens this appearance presents differently from [expected].
  ///
  /// Empty when the two describe the same presentation, which is what a renderer
  /// suite asserts. Comparing token by token is what makes a failure readable:
  /// the map names the token that drifted and shows what each side did with it.
  Map<String, TokenDifference> differencesFrom(BoxAppearance expected) {
    final Map<String, TokenDifference> differences =
        <String, TokenDifference>{};

    void compare(String token, Object? actualValue, Object? expectedValue) {
      if (actualValue != expectedValue) {
        differences[token] = (actual: actualValue, expected: expectedValue);
      }
    }

    compare('direction', direction, expected.direction);
    compare('mainAlign', mainAlign, expected.mainAlign);
    compare('crossAlign', crossAlign, expected.crossAlign);
    compare('gap', gap ?? 0, expected.gap ?? 0);
    compare(
      'padding',
      padding ?? core.BoxSpacing.zero,
      expected.padding ?? core.BoxSpacing.zero,
    );
    compare(
      'margin',
      margin ?? core.BoxSpacing.zero,
      expected.margin ?? core.BoxSpacing.zero,
    );
    compare('width', width, expected.width);
    compare('widthFraction', widthFraction, expected.widthFraction);
    compare('height', height, expected.height);
    compare('aspectRatio', aspectRatio, expected.aspectRatio);
    compare('backgroundColor', backgroundColor, expected.backgroundColor);
    compare('borderRadius', borderRadius ?? 0, expected.borderRadius ?? 0);
    compare('corners', corners, expected.corners);
    compare('borderWidth', borderWidth ?? 0, expected.borderWidth ?? 0);
    compare(
      'transitionDuration',
      transitionDuration,
      expected.transitionDuration,
    );
    compare('transitionCurve', transitionCurve, expected.transitionCurve);
    compare('opacity', opacity, expected.opacity);
    compare('transform', transform, expected.transform);
    compare(
      'borderColor',
      _hasBorder ? borderColor : null,
      expected._hasBorder ? expected.borderColor : null,
    );

    return differences;
  }

  @override
  bool operator ==(Object other) =>
      other is BoxAppearance && differencesFrom(other).isEmpty;

  @override
  int get hashCode => Object.hash(
    direction,
    mainAlign,
    crossAlign,
    gap ?? 0,
    padding ?? core.BoxSpacing.zero,
    margin ?? core.BoxSpacing.zero,
    width,
    height,
    aspectRatio,
    backgroundColor,
    borderRadius ?? 0,
    corners,
    borderWidth ?? 0,
    _hasBorder ? borderColor : null,
    transitionDuration,
    transitionCurve,
    opacity,
    transform,
  );

  @override
  String toString() {
    return 'BoxAppearance('
        'direction: $direction, '
        'mainAlign: $mainAlign, '
        'crossAlign: $crossAlign, '
        'gap: $gap, '
        'padding: $padding, '
        'margin: $margin, '
        'width: $width, '
        'height: $height, '
        'aspectRatio: $aspectRatio, '
        'backgroundColor: $backgroundColor, '
        'borderRadius: $borderRadius, '
        'corners: $corners, '
        'borderWidth: $borderWidth, '
        'borderColor: $borderColor, '
        'transitionDuration: $transitionDuration, '
        'transitionCurve: $transitionCurve, '
        'opacity: $opacity, '
        'transform: $transform'
        ')';
  }
}
