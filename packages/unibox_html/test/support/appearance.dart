import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_testing/unibox_testing.dart';

/// The presentation this renderer gave the root box of [html].
///
/// The facts are read from the output the renderer produced — the class the root element
/// wears, and the declarations that class is given — and never from the node tree, so they
/// describe what this target *did* with the node. The Flutter suite reads the same facts
/// out of the widget tree, and both compare them with the table in `unibox_testing`.
BoxAppearance appearanceOf(String html) {
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
    height: _lengthOf(declarations['height']),
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

/// A CSS length as the model writes it: pixels, or the space available.
double? _lengthOf(String? value) {
  if (value == null) {
    return null;
  }

  return value == '100%' ? double.infinity : _pixelsOf(value);
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

/// A transform as CSS writes it: translate, rotate, scale.
core.BoxTransform? _transformOf(String? value) {
  if (value == null) {
    return null;
  }

  final RegExpMatch? match = RegExp(
    r'translate\((-?[0-9.]+)(?:px)?, (-?[0-9.]+)(?:px)?\) '
    r'rotate\((-?[0-9.]+)deg\) scale\((-?[0-9.]+)\)',
  ).firstMatch(value);

  if (match == null) {
    throw StateError('A transform this suite cannot read: $value');
  }

  return core.BoxTransform(
    offsetX: double.parse(match.group(1)!),
    offsetY: double.parse(match.group(2)!),
    rotation: double.parse(match.group(3)!),
    scale: double.parse(match.group(4)!),
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
  _ => core.CrossAlign.start,
};

/// The presentation this renderer gave the root text of [html].
///
/// Read from the class the text element wears, never from the node: the tokens a text
/// states are the ones the document wrote, and everything else is inherited from the box
/// around it, exactly as a Flutter `Text` inherits from `DefaultTextStyle`.
TextAppearance textAppearanceOf(String html) {
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
    textAlign: _textAlignOf(declarations['text-align']),
    maxLines: lines,
    overflow: _overflowOf(declarations, lines: lines),
  );
}

/// A family as CSS writes it: one family, quoted.
String? _familyOf(String? value) {
  if (value == null) {
    return null;
  }

  return value.replaceAll("'", '').replaceAll('"', '');
}

core.FontWeight? _fontWeightOf(String? value) => switch (value) {
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
