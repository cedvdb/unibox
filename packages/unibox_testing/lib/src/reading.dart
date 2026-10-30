import 'dart:math' as math;

import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_testing/unibox_testing.dart';

/// The presentation this renderer gave the root box of [html].
///
/// The facts are read from the output the renderer produced — the class the root element
/// wears, and the declarations that class is given — and never from the node tree, so they
/// describe what this target *did* with the node. The Flutter suite reads the same facts
/// out of the widget tree, and both compare them with the table in `unibox_testing`.
BoxAppearance boxAppearanceIn(String html) {
  final Map<String, Map<String, String>> rules = rulesOf(html);
  final String? className = rootClassOf(html);

  if (className == null) {
    throw StateError('The root element of\n$html\ncarries no class.');
  }

  final Map<String, String> declarations =
      rules[className] ?? const <String, String>{};
  final ({double width, core.BoxColor color})? border = _borderOf(
    declarations['border'],
  );
  final ({Duration duration, core.BoxCurve curve})? transition = _transitionOf(
    declarations['transition'],
  );
  final ({double? radius, core.BoxBorderRadius? corners}) radius = _radiusOf(
    declarations['border-radius'],
  );

  return BoxAppearance(
    direction: declarations['flex-direction'] == 'row'
        ? core.Axis.horizontal
        : core.Axis.vertical,
    mainAlign: mainAlignOf(declarations['justify-content']),
    crossAlign: crossAlignOf(declarations['align-items']),
    gap: _lengthOf(declarations['gap']),
    padding: _spacingOf(declarations['padding']),
    margin: _spacingOf(declarations['margin']),
    width: _lengthOf(declarations['width']),
    widthFraction: _fractionOf(declarations['width']),
    height: _lengthOf(declarations['height']),
    aspectRatio: _numberOf(declarations['aspect-ratio']),
    backgroundColor: colorOf(declarations['background-color']),
    borderRadius: radius.radius,
    corners: radius.corners,
    borderWidth: border?.width,
    borderColor: border?.color,
    transitionDuration: transition?.duration,
    transitionCurve: transition?.curve,
    opacity: _numberOf(declarations['opacity']),
    transform: _transformOf(declarations['transform']),
  );
}

/// Every rule of the `<style>` element, by class name.
///
/// The format is this renderer's own — one class, one flat block — so it is read with a
/// split rather than a parser. A rule whose declarations differ from the table is exactly
/// what the conformance suite looks for.
Map<String, Map<String, String>> rulesOf(String html) {
  final RegExpMatch? style = RegExp(
    '<style>(.*?)</style>',
    dotAll: true,
  ).firstMatch(html);

  if (style == null) {
    throw StateError('The rendering has no stylesheet:\n$html');
  }

  final Map<String, Map<String, String>> rules =
      <String, Map<String, String>>{};

  for (final RegExpMatch rule in RegExp(
    r'\.([a-z-]+-[0-9a-f]{8})\{([^}]*)\}',
  ).allMatches(style.group(1)!)) {
    rules[rule.group(1)!] = _declarationsOf(rule.group(2)!);
  }

  return rules;
}

/// The class of the first element after the stylesheet, which is the root of the tree.
String? rootClassOf(String html) {
  final int body = html.indexOf('</style>');
  final RegExpMatch? match = RegExp(r'class="([^"]+)"')
      .firstMatch(html.substring(body < 0 ? 0 : body));

  return match?.group(1);
}

Map<String, String> _declarationsOf(String text) {
  final Map<String, String> declarations = <String, String>{};

  for (final String declaration in text.split(';')) {
    final int colon = declaration.indexOf(':');

    if (colon == -1) {
      continue;
    }

    declarations[declaration.substring(0, colon)] = declaration.substring(
      colon + 1,
    );
  }

  return declarations;
}

double? _numberOf(String? value) => value == null ? null : double.parse(value);

/// A percentage of the parent read back out of CSS, or `null` when the value is not one.
///
/// `50%` is a fraction of the parent and `50px` is a length: the same property and two different
/// statements, so the reader tells them apart by the unit.
double? _fractionOf(String? value) {
  if (value == null || !value.endsWith('%')) {
    return null;
  }

  final double fraction =
      double.tryParse(value.substring(0, value.length - 1))! / 100;

  // `100%` is how the model writes "the space available", which is a length and not a share. The
  // two statements render the same, so the reader reports the one the model calls a size.
  return fraction == 1 ? null : fraction;
}

/// A CSS length as the model writes it: pixels, or the space available.
double? _lengthOf(String? value) {
  if (value == null) {
    return null;
  }

  // `100%` is the space available; any other percentage is a share, which is a different token and
  // is read by `_fractionOf`. A length is neither, so it is parsed only when it is a length.
  if (value == '100%') {
    return double.infinity;
  }

  return value.endsWith('%') ? null : _pixelsOf(value);
}

double _pixelsOf(String value) =>
    double.parse(value.replaceAll('px', '').trim());

/// A spacing as CSS writes it, back to four edges.
core.BoxSpacing? _spacingOf(String? value) {
  if (value == null) {
    return null;
  }

  final List<double> edges = value
      .split(' ')
      .map(_pixelsOf)
      .toList(growable: false);

  return switch (edges) {
    <double>[final double all] => core.BoxSpacing.all(all),
    <double>[final double vertical, final double horizontal] =>
      core.BoxSpacing.symmetric(horizontal: horizontal, vertical: vertical),
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
    _ => throw StateError('A spacing of ${edges.length} values: $value'),
  };
}

/// A colour as CSS writes it, back to the model's channels.
core.BoxColor? colorOf(String? value) {
  if (value == null) {
    return null;
  }

  if (value.startsWith('#')) {
    return core.BoxColor(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }

  final RegExpMatch? match = RegExp(r'rgba\((\d+), (\d+), (\d+), ([0-9.]+)\)')
      .firstMatch(value);

  if (match == null) {
    throw StateError('A colour this suite cannot read: $value');
  }

  return core.BoxColor.rgba(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    (double.parse(match.group(4)!) * 0xFF).round(),
  );
}

/// A border as CSS writes it: width, style, colour.
({double width, core.BoxColor color})? _borderOf(String? value) {
  if (value == null) {
    return null;
  }

  final List<String> parts = value.split(' ');

  return (width: _pixelsOf(parts.first), color: colorOf(parts.last)!);
}

({double? radius, core.BoxBorderRadius? corners}) _radiusOf(String? value) {
  if (value == null) {
    return (radius: null, corners: null);
  }

  final List<double> radii = value
      .split(' ')
      .map(_pixelsOf)
      .toList(growable: false);

  if (radii.length == 1) {
    return (radius: radii.first, corners: null);
  }

  return (
    radius: null,
    corners: core.BoxBorderRadius(
      topLeft: radii[0],
      topRight: radii[1],
      bottomRight: radii[2],
      bottomLeft: radii[3],
    ),
  );
}

/// A transition as CSS writes it: the first property carries the duration and the curve
/// that a case stating one shares.
({Duration duration, core.BoxCurve curve})? _transitionOf(String? value) {
  if (value == null) {
    return null;
  }

  final List<String> parts = value.split(', ').first.split(' ');

  return (
    duration: Duration(milliseconds: int.parse(parts[1].replaceAll('ms', ''))),
    curve: switch (parts[2]) {
      'linear' => core.BoxCurve.linear,
      'ease' => core.BoxCurve.ease,
      'ease-in' => core.BoxCurve.easeIn,
      'ease-out' => core.BoxCurve.easeOut,
      _ => core.BoxCurve.easeInOut,
    },
  );
}

/// A transform as CSS writes it: translate, rotate, scale — with a percentage translate when the
/// model states a fraction of the box's own size, which is a second function and not the same one.
core.BoxTransform? _transformOf(String? value) {
  if (value == null) {
    return null;
  }

  final RegExpMatch? fraction = RegExp(
    r'translate\((-?[0-9.]+)%, (-?[0-9.]+)%\)',
  ).firstMatch(value);
  final RegExpMatch? pixels = RegExp(
    r'translate\((-?[0-9.]+)(?:px)?, (-?[0-9.]+)(?:px)?\)',
  ).firstMatch(value);
  final RegExpMatch? match = RegExp(
    r'rotate\((-?[0-9.]+)deg\) scale\((-?[0-9.]+), (-?[0-9.]+)\)',
  ).firstMatch(value);

  if (match == null) {
    throw StateError('A transform this suite cannot read: $value');
  }

  return core.BoxTransform(
    offsetX: pixels == null ? 0 : double.parse(pixels.group(1)!),
    offsetY: pixels == null ? 0 : double.parse(pixels.group(2)!),
    fractionX: fraction == null ? 0 : double.parse(fraction.group(1)!) / 100,
    fractionY: fraction == null ? 0 : double.parse(fraction.group(2)!) / 100,
    rotation: double.parse(match.group(1)!),
    scaleX: double.parse(match.group(2)!),
    scaleY: double.parse(match.group(3)!),
  );
}

core.MainAlign mainAlignOf(String? value) => switch (value) {
  'center' => core.MainAlign.center,
  'end' => core.MainAlign.end,
  'space-between' => core.MainAlign.spaceBetween,
  'space-around' => core.MainAlign.spaceAround,
  'space-evenly' => core.MainAlign.spaceEvenly,
  _ => core.MainAlign.start,
};

core.CrossAlign crossAlignOf(String? value) => switch (value) {
  'center' => core.CrossAlign.center,
  'end' => core.CrossAlign.end,
  'stretch' => core.CrossAlign.stretch,
  'baseline' => core.CrossAlign.baseline,
  _ => core.CrossAlign.start,
};

/// The presentation this renderer gave the root text of [html].
///
/// Read from the class the text element wears, never from the node: the tokens a text
/// states are the ones the document wrote, and everything else is inherited from the box
/// around it, exactly as a Flutter `Text` inherits from `DefaultTextStyle`.
TextAppearance textAppearanceIn(String html) {
  final Map<String, Map<String, String>> rules = rulesOf(html);
  final String? className = rootClassOf(html);

  if (className == null) {
    throw StateError('The root element of\n$html\ncarries no class.');
  }

  final Map<String, String> declarations =
      rules[className] ?? const <String, String>{};
  final int? lines = declarations['-webkit-line-clamp'] == null
      ? null
      : int.parse(declarations['-webkit-line-clamp']!);

  return TextAppearance(
    fontSize: _lengthOf(declarations['font-size']),
    fontWeight: _fontWeightOf(declarations['font-weight']),
    color: colorOf(declarations['color']),
    // Written unitless, so descendants scale with their own font size.
    lineHeight: _numberOf(declarations['line-height']),
    fontFamily: _familyOf(declarations['font-family']),
    letterSpacing: _lengthOf(declarations['letter-spacing']),
    decoration: _decorationOf(declarations['text-decoration']),
    decorationColor: colorOf(declarations['text-decoration-color']),
    textAlign: _textAlignOf(declarations['text-align']),
    maxLines: lines,
    overflow: _overflowOf(declarations, lines: lines),
  );
}

/// The core decoration of a CSS `text-decoration` keyword.
core.TextDecoration? _decorationOf(String? value) => switch (value) {
  'none' => core.TextDecoration.none,
  'line-through' => core.TextDecoration.lineThrough,
  'underline' => core.TextDecoration.underline,
  _ => null,
};

/// A family as CSS writes it: one family, quoted.
String? _familyOf(String? value) {
  if (value == null) {
    return null;
  }

  return value.replaceAll("'", '').replaceAll('"', '');
}

core.FontWeight? _fontWeightOf(String? value) => switch (value) {
  '300' => core.FontWeight.light,
  '400' => core.FontWeight.normal,
  '500' => core.FontWeight.medium,
  '600' => core.FontWeight.semiBold,
  '700' => core.FontWeight.bold,
  _ => null,
};

core.TextAlign? _textAlignOf(String? value) => switch (value) {
  'left' => core.TextAlign.left,
  'center' => core.TextAlign.center,
  'right' => core.TextAlign.right,
  'justify' => core.TextAlign.justify,
  _ => null,
};

/// How a text truncates, read back from the declarations that do it.
///
/// A clamp is a line count; without one, an ellipsis is a single truncated line and a
/// clip is a single line cut off without the mark.
core.TextOverflow? _overflowOf(
  Map<String, String> declarations, {
  required int? lines,
}) {
  if (declarations['overflow'] == null) {
    return null;
  }

  if (lines != null) {
    return declarations['text-overflow'] == 'clip'
        ? core.TextOverflow.clip
        : core.TextOverflow.ellipsis;
  }

  return declarations['text-overflow'] == 'ellipsis'
      ? core.TextOverflow.ellipsis
      : core.TextOverflow.clip;
}

/// The tracks each child of a rendered grid occupies in [html].
///
/// The span is read from the `grid-column` declaration of the class the child's
/// element wears, and clamped to the column count the case's width gives — which is
/// how both renderers read a span wider than the grid. The element is found by the
/// key its node carried, because a class list in document order is every element a
/// child contains and not the children themselves.
GridAppearance gridAppearanceIn(String html, {required GridCase gridCase}) {
  final Map<String, Map<String, String>> rules = rulesOf(html);
  final int columns = gridCase.columns;

  return GridAppearance(
    spans: <int>[
      for (final core.UINode child in gridCase.node.children)
        _spanOf(html, rules, child.key, columns),
    ],
  );
}

/// The tracks the child [key] was given, read from the class its element wears.
int _spanOf(
  String html,
  Map<String, Map<String, String>> rules,
  Object? key,
  int columns,
) {
  if (key == null) {
    throw StateError('A grid case needs a key on every child.');
  }

  final RegExpMatch? element = RegExp(
    'class="([^"]+)"[^>]*data-unibox-key="${RegExp.escape('$key')}"',
  ).firstMatch(html);

  if (element == null) {
    throw StateError('No element in\n$html\ncarries the key $key.');
  }

  final Map<String, String> declarations =
      rules[element.group(1)!] ?? const <String, String>{};
  final String? value = declarations['grid-column'];

  if (value == null) {
    return 1;
  }

  final int declared = int.tryParse(value.replaceFirst('span ', '')) ?? 1;

  return math.min(math.max(declared, 1), math.max(columns, 1));
}

/// The presentation this renderer gave the root overlay of [html].
///
/// The barrier colour comes from the rule its own element wears and the alignment from the
/// keywords the layer is given, so neither is read from the node.
OverlayAppearance overlayAppearanceIn(String html) {
  final Map<String, Map<String, String>> rules = rulesOf(html);
  final List<String> classes = RegExp(r'class="([^"]+)"')
      .allMatches(html.substring(html.indexOf('</style>')))
      .map((RegExpMatch match) => match.group(1)!)
      .toList(growable: false);

  // The layer, then the barrier it holds: the first two classes of the rendering.
  final Map<String, String> layer =
      rules[classes.first] ?? const <String, String>{};
  final Map<String, String> barrier =
      rules[classes.length > 1 ? classes[1] : ''] ?? const <String, String>{};

  return OverlayAppearance(
    barrierColor: colorOf(barrier['background-color'])!,
    alignment: switch (layer['align-items']) {
      'start' => core.OverlayAlignment.top,
      'end' => core.OverlayAlignment.bottom,
      _ => core.OverlayAlignment.center,
    },
  );
}
