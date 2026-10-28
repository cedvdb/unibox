import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_testing/unibox_testing.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'harness.dart';

/// The presentation this renderer gave the root box rendered by [pumpNode].
///
/// The facts are read from the CSS the renderer emitted, never from the node
/// tree: every box is a flex container, so the first `div` of the page is the box
/// under test. The contract cases are resting boxes, which the renderer writes as
/// inline styles; a case that styled one of its states would move its
/// declarations into a scoped class rule and fail here, which is the direction a
/// token that stopped being rendered should fail in.
///
/// The Flutter suite reads the same facts out of the widget tree it built, and
/// both compare them with the table in `unibox_testing`.
BoxAppearance appearanceOf() {
  final Map<String, String> styles = stylesOf(find.tag('div').first);
  final String? border = styles['border'];
  final _Border? parsed = border == null ? null : _borderOf(border);

  return BoxAppearance(
    direction: _axisOf(styles['flex-direction']),
    mainAlign: _mainAlignOf(styles['justify-content']),
    crossAlign: _crossAlignOf(styles['align-items']),
    gap: _pixelsOrNull(styles['gap']),
    padding: _spacingOrNull(styles['padding']),
    margin: _spacingOrNull(styles['margin']),
    width: _dimensionOrNull(styles['width']),
    height: _dimensionOrNull(styles['height']),
    backgroundColor: _colorOrNull(styles['background-color']),
    borderRadius: _uniformRadiusOf(styles['border-radius']),
    corners: _cornersOf(styles['border-radius']),
    borderWidth: parsed?.width,
    borderColor: parsed?.color,
    transitionDuration: _transitionDurationOf(styles['transition']),
    transitionCurve: _transitionCurveOf(styles['transition']),
    opacity: _doubleOrNull(styles['opacity']),
    transform: _transformOf(styles['transform']),
  );
}

/// A CSS border, split into the width and the colour it draws.
final class _Border {
  /// Creates a border of [width] logical pixels in [color].
  const _Border({required this.width, required this.color});

  /// The width of the line.
  final double width;

  /// The colour of the line.
  final core.BoxColor color;
}

/// The axis a `flex-direction` names.
///
/// The renderer always writes the direction, so an unknown value is a failure to
/// read the output rather than a box that fell back to a column.
core.Axis _axisOf(String? value) {
  return switch (value) {
    'row' => core.Axis.horizontal,
    'column' => core.Axis.vertical,
    _ => throw FormatException('Not a flex direction: $value'),
  };
}

/// The main axis alignment a `justify-content` names.
///
/// CSS accepts `start` and `flex-start` for the same alignment, and Jaspr writes
/// the former.
core.MainAlign _mainAlignOf(String? value) {
  return switch (value) {
    'start' || 'flex-start' => core.MainAlign.start,
    'center' => core.MainAlign.center,
    'end' || 'flex-end' => core.MainAlign.end,
    'space-between' => core.MainAlign.spaceBetween,
    'space-around' => core.MainAlign.spaceAround,
    'space-evenly' => core.MainAlign.spaceEvenly,
    _ => throw FormatException('Not a justify-content: $value'),
  };
}

/// The cross axis alignment an `align-items` names.
core.CrossAlign _crossAlignOf(String? value) {
  return switch (value) {
    'start' || 'flex-start' => core.CrossAlign.start,
    'center' => core.CrossAlign.center,
    'end' || 'flex-end' => core.CrossAlign.end,
    'stretch' => core.CrossAlign.stretch,
    _ => throw FormatException('Not an align-items: $value'),
  };
}

/// The typesetting this renderer gave the text node rendered by [pumpNode].
///
/// The facts are read from the declarations the renderer emitted for the `<span>`
/// of the text node, and never from the node tree. That is what makes the answer
/// comparable with the `TextStyle` the Flutter renderer built: only what this
/// target *said* is compared, not what a font engine made of it.
///
/// Declarations the node left alone read back as `null` even though the browser
/// inherits a value from the `:root` rule, which is the same line the Flutter
/// suite draws with `DefaultTextStyle`.
///
/// A clamped text is reported as truncating with an ellipsis: `-webkit-line-clamp`
/// is the only way to end a text after a number of lines in CSS, and it ends the
/// last line with an ellipsis, which is why the model can leave `text-overflow`
/// out of the declarations it writes.
TextAppearance textAppearanceOf() => _textAppearance(stylesOf(_text));

/// The typesetting the text node is actually typeset in.
///
/// The default typography of the model comes from the `:root` rule and the tokens
/// of the node are laid over it, the way the cascade lays an inherited value under
/// a declared one — which is the same pair the Flutter suite resolves through
/// `DefaultTextStyle`.
TextAppearance resolvedTextAppearanceOf() {
  return _textAppearance(<String, String>{
    ...declarationsOf(':root'),
    ...stylesOf(_text),
  });
}

/// The span the renderer emitted for the text node.
Finder get _text => find.tag('span').first;

/// The characters the renderer put into the element it built.
String renderedTextOf() {
  return elementOf(_text).children
      .whereType<TestRenderText>()
      .map((TestRenderText child) => child.text)
      .join();
}

/// The typography a set of CSS declarations describes.
TextAppearance _textAppearance(Map<String, String> styles) {
  final String? clamp = styles['-webkit-line-clamp'];

  return TextAppearance(
    fontSize: _pixelsOrNull(styles['font-size']),
    fontWeight: _fontWeightOrNull(styles['font-weight']),
    color: _colorOrNull(styles['color']),
    lineHeight: _lineHeightOrNull(styles['line-height']),
    fontFamily: _familyOrNull(styles['font-family']),
    letterSpacing: _pixelsOrNull(styles['letter-spacing']),
    textAlign: _textAlignOrNull(styles['text-align']),
    maxLines: clamp == null ? null : int.parse(clamp),
    overflow: _textOverflowOrNull(
      styles['text-overflow'],
      clamped: clamp != null,
    ),
  );
}

/// The weight a `font-weight` names.
core.FontWeight? _fontWeightOrNull(String? value) {
  return switch (value) {
    null => null,
    '400' || 'normal' => core.FontWeight.normal,
    '500' => core.FontWeight.medium,
    '600' => core.FontWeight.semiBold,
    '700' || 'bold' => core.FontWeight.bold,
    _ => throw FormatException('Not a font weight of the model: $value'),
  };
}

/// The family a `font-family` names, without the quotes CSS writes it in.
/// The family a `font-family` names, without the quotes CSS writes it in.
///
/// `system-ui` reads back as `null`: it is how CSS spells the family the model
/// leaves unnamed — "the platform's UI font" — and Flutter says the same thing by
/// naming no family at all.
String? _familyOrNull(String? value) {
  if (value == null) {
    return null;
  }
  final String family = value.replaceAll(RegExp(r"""^['"]|['"]$"""), '');
  return family == 'system-ui' ? null : family;
}

/// The multiple of the font size a `line-height` names.
///
/// The renderer writes the line height unitless, which is the only spelling that
/// scales with a descendant's font size, so a unit here would be a difference the
/// model did not ask for.
double? _lineHeightOrNull(String? value) {
  if (value == null) {
    return null;
  }
  if (value.endsWith('px')) {
    throw FormatException('Not a unitless line height: $value');
  }
  return double.parse(value);
}

/// The alignment a `text-align` names.
core.TextAlign? _textAlignOrNull(String? value) {
  return switch (value) {
    null => null,
    'left' || 'start' => core.TextAlign.left,
    'center' => core.TextAlign.center,
    'right' || 'end' => core.TextAlign.right,
    'justify' => core.TextAlign.justify,
    _ => throw FormatException('Not a text-align: $value'),
  };
}

/// The truncation a `text-overflow` names.
///
/// A clamped box ([clamped]) truncates with an ellipsis without saying so, because
/// `-webkit-line-clamp` implies it; only an explicit `clip` overrules that.
core.TextOverflow? _textOverflowOrNull(String? value, {required bool clamped}) {
  return switch (value) {
    'clip' => core.TextOverflow.clip,
    'ellipsis' => core.TextOverflow.ellipsis,
    null => clamped ? core.TextOverflow.ellipsis : null,
    _ => throw FormatException('Not a text-overflow: $value'),
  };
}

/// The transform a `transform` declaration names, in the model's parts.
///
/// The renderer writes `translate(x, y) rotate(deg) scale(s)` in that order; a
/// declaration that does not match is not something this target can compare, so it
/// fails here instead of being read as "no transform".
core.BoxTransform? _transformOf(String? value) {
  if (value == null) {
    return null;
  }

  final RegExpMatch? match = _transformPattern.firstMatch(value);
  if (match == null) {
    throw FormatException('Not a transform of the model: $value');
  }

  final core.BoxTransform transform = core.BoxTransform(
    offsetX: _pixels(match.group(1)!),
    offsetY: _pixels(match.group(2)!),
    rotation: double.parse(match.group(3)!),
    scale: double.parse(match.group(4)!),
  );

  // An identity transform and no transform paint the same box.
  return transform.isIdentity ? null : transform;
}

/// The four numbers of the transform the renderer writes, in its order.
final RegExp _transformPattern = RegExp(
  r'translate\((-?[\d.]+)px, (-?[\d.]+)px\) '
  r'rotate\((-?[\d.]+)deg\) scale\((-?[\d.]+)\)',
);

/// The number [value] names, or `null` when there is no value.
double? _doubleOrNull(String? value) =>
    value == null ? null : double.parse(value);

/// The duration of a `transition` shorthand, from the first property it names.
///
/// Every property in the list carries the same duration and curve, so the first
/// one says what the whole transition does.
Duration? _transitionDurationOf(String? value) {
  final List<String>? parts = _transitionParts(value);
  if (parts == null) {
    return null;
  }
  return Duration(milliseconds: int.parse(parts[1].replaceAll('ms', '')));
}

/// The curve of a `transition` shorthand, read the same way.
core.BoxCurve? _transitionCurveOf(String? value) {
  final List<String>? parts = _transitionParts(value);
  if (parts == null) {
    return null;
  }
  return switch (parts[2]) {
    'linear' => core.BoxCurve.linear,
    'ease' => core.BoxCurve.ease,
    'ease-in' => core.BoxCurve.easeIn,
    'ease-out' => core.BoxCurve.easeOut,
    'ease-in-out' => core.BoxCurve.easeInOut,
    final String other => throw FormatException('Not a curve: $other'),
  };
}

/// The `property duration curve` triplet of a `transition` shorthand.
List<String>? _transitionParts(String? value) {
  if (value == null) {
    return null;
  }
  return value.split(',').first.trim().split(' ');
}

/// The number of pixels in [value], which CSS may write with a unit.
double _pixels(String value) {
  return double.parse(value.replaceAll('px', '').trim());
}

/// The pixels [value] names, or `null` when there is no value.
double? _pixelsOrNull(String? value) => value == null ? null : _pixels(value);

/// The size [value] names, [double.infinity] for a percentage.
double? _dimensionOrNull(String? value) {
  if (value == null) {
    return null;
  }
  return value.endsWith('%') ? double.infinity : _pixels(value);
}

/// The spacing a `padding` or `margin` shorthand names.
core.BoxSpacing? _spacingOrNull(String? value) {
  if (value == null) {
    return null;
  }

  final List<double> sides = <double>[
    for (final String side in value.split(' ')) _pixels(side),
  ];

  return switch (sides) {
    <double>[final double all] => core.BoxSpacing.all(all),
    <double>[final double vertical, final double horizontal] =>
      core.BoxSpacing.symmetric(vertical: vertical, horizontal: horizontal),
    <double>[final double top, final double horizontal, final double bottom] =>
      core.BoxSpacing(
        top: top,
        right: horizontal,
        bottom: bottom,
        left: horizontal,
      ),
    <double>[
      final double top,
      final double right,
      final double bottom,
      final double left,
    ] =>
      core.BoxSpacing(top: top, right: right, bottom: bottom, left: left),
    _ => throw FormatException('Not a spacing: $value'),
  };
}

/// The colour [value] names, or `null` when there is no value.
core.BoxColor? _colorOrNull(String? value) =>
    value == null ? null : _color(value);

/// The colour a CSS colour value names.
core.BoxColor _color(String value) {
  if (value.startsWith('#')) {
    final String hex = value.substring(1).trim();
    final int channels = int.parse(hex, radix: 16);
    return hex.length == 6
        ? core.BoxColor(channels | 0xFF000000)
        : core.BoxColor(channels);
  }

  final RegExpMatch match = _functionPattern.firstMatch(value)!;
  final List<String> channels = match
      .group(1)!
      .split(',')
      .map((String channel) => channel.trim())
      .toList();

  return core.BoxColor.rgba(
    int.parse(channels[0]),
    int.parse(channels[1]),
    int.parse(channels[2]),
    channels.length > 3 ? (double.parse(channels[3]) * 0xFF).round() : 0xFF,
  );
}

/// The arguments of an `rgb(...)` or `rgba(...)` value.
final RegExp _functionPattern = RegExp(r'rgba?\(([^)]*)\)');

/// The border a `border` shorthand names.
_Border _borderOf(String value) {
  final RegExpMatch? line = _linePattern.firstMatch(value);
  final RegExpMatch? color = _colorPattern.firstMatch(value);

  if (line == null || color == null) {
    throw FormatException('Not a border: $value');
  }

  return _Border(
    width: double.parse(line.group(1)!),
    color: _color(color.group(0)!),
  );
}

/// The width of a border line in a `border` shorthand.
final RegExp _linePattern = RegExp(r'([\d.]+)px');

/// A colour inside a `border` shorthand, which may be a hex value or a function.
final RegExp _colorPattern = RegExp(r'#[0-9a-fA-F]{3,8}|rgba?\([^)]*\)');

/// The one radius every corner shares, or `null` when they differ or are square.
double? _uniformRadiusOf(String? value) {
  final List<double>? radii = _radiiOf(value);

  if (radii == null || radii.toSet().length != 1 || radii.first == 0) {
    return null;
  }

  return radii.first;
}

/// The four corners, or `null` when the declaration gives every corner the same.
core.BoxCorners? _cornersOf(String? value) {
  final List<double>? radii = _radiiOf(value);

  if (radii == null || radii.toSet().length == 1) {
    return null;
  }

  return core.BoxCorners(
    topLeft: radii[0],
    topRight: radii[1],
    bottomRight: radii[2],
    bottomLeft: radii[3],
  );
}

/// A `border-radius` declaration as four radii in CSS order.
List<double>? _radiiOf(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final List<double> radii = <double>[
    for (final String part in value.trim().split(RegExp(r'\s+')))
      _pixelsOrNull(part) ?? 0,
  ];

  return switch (radii.length) {
    0 => null,
    1 => List<double>.filled(4, radii.first),
    2 => <double>[radii[0], radii[1], radii[0], radii[1]],
    3 => <double>[radii[0], radii[1], radii[2], radii[1]],
    _ => radii.sublist(0, 4),
  };
}
