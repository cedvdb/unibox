import 'package:unibox_core/unibox_core.dart' as core;

import 'declarations.dart';

/// A number without a needless `.0`, which both CSS and a reader prefer.
///
/// It is the one spelling of a number in this package: a declaration, a class
/// name and a test all read the same text, so `8` cannot become `8.0px` in one
/// place and `8px` in another.
String cssNumber(double value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// [value] in logical pixels, as CSS writes a length.
///
/// A zero is written `0` rather than `0px`: CSS accepts either, and the short one is
/// what an author writes. It is one rule for every length here, so a padding, a gap
/// and a radius cannot spell the same nothing two ways.
String cssPixels(double value) => value == 0 ? '0' : '${cssNumber(value)}px';

/// A model dimension as CSS writes it.
///
/// `double.infinity` expands to the space available (`100%`), which is the one
/// length the model states that is not a number of pixels; every other value is.
/// `null` stays `null`, so a caller can leave the property out altogether.
String? cssLength(double? value) {
  if (value == null) {
    return null;
  }

  return value.isInfinite ? '100%' : cssPixels(value);
}

/// A model [core.BoxSpacing] as CSS writes it.
///
/// A uniform spacing collapses into the one-value shorthand (`8px`), anything else
/// becomes the four-value shorthand (`8px 12px 16px 4px`, in CSS's order: top,
/// right, bottom, left). Zero is written `0px` rather than dropped, because a
/// declaration that cancels what a user agent applies has to be stated.
String cssSpacing(core.BoxSpacing spacing) {
  if (spacing.left == spacing.top &&
      spacing.top == spacing.right &&
      spacing.right == spacing.bottom) {
    return cssPixels(spacing.left);
  }

  return <String>[
    cssPixels(spacing.top),
    cssPixels(spacing.right),
    cssPixels(spacing.bottom),
    cssPixels(spacing.left),
  ].join(' ');
}

/// A model [core.BoxColor] as CSS writes it.
///
/// Opaque colours become `#rrggbb`; translucent ones an `rgba(...)` function whose
/// alpha is rounded to three decimals, which is more precise than the eight-bit
/// channel it originates from.
///
/// A role colour is written as a custom property instead, through
/// [cssRoleReference]: its value lives once, in the `:root` block a theme produces,
/// so a host stylesheet or a dark-mode block can outrank the tree.
String cssColor(core.BoxColor color) {
  if (color.isOpaque) {
    final String hex = (color.value & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');

    return '#$hex';
  }

  final double alpha = double.parse(color.opacity.toStringAsFixed(3));

  return 'rgba(${color.red}, ${color.green}, ${color.blue}, $alpha)';
}

/// The custom property of a role colour, or `null` for a colour with its own
/// channels.
///
/// A role is written as `var(--unibox-color-primary)`, so its value lives once, in
/// the `:root` block the renderer emits for the theme. The name comes from the enum
/// member, so a role is spelled the same way in the tree, in the theme and in the
/// CSS.
String? cssRoleReference(core.BoxColor color) {
  final Enum? role = color.role;

  return role == null ? null : 'var(${core.UniboxTheme.cssNameOf(role)})';
}

/// [color] as a declaration value: its role when it names one, its channels
/// otherwise.
String cssColorOrRole(core.BoxColor color) =>
    cssRoleReference(color) ?? cssColor(color);

/// A model [core.ImageFit] as the CSS `object-fit` keyword.
///
/// `scaleDown` is a CSS keyword as well, so the model's default means the same
/// thing here as `BoxFit.scaleDown` does in Flutter.
String cssObjectFit(core.ImageFit fit) {
  return switch (fit) {
    core.ImageFit.cover => 'cover',
    core.ImageFit.contain => 'contain',
    core.ImageFit.fill => 'fill',
    core.ImageFit.scaleDown => 'scale-down',
  };
}

/// A model [core.Axis] as the CSS `flex-direction` keyword.
String cssFlexDirection(core.Axis axis) => switch (axis) {
  core.Axis.horizontal => 'row',
  core.Axis.vertical => 'column',
};

/// A model [core.MainAlign] as the CSS `justify-content` keyword.
String cssJustifyContent(core.MainAlign align) => switch (align) {
  core.MainAlign.start => 'start',
  core.MainAlign.center => 'center',
  core.MainAlign.end => 'end',
  core.MainAlign.spaceBetween => 'space-between',
  core.MainAlign.spaceAround => 'space-around',
  core.MainAlign.spaceEvenly => 'space-evenly',
};

/// A model [core.CrossAlign] as the CSS `align-items` keyword.
///
/// `baseline` is the alphabetic baseline: CSS has no way to ask for another one, and
/// the alphabetic baseline is what Flutter is told to align on.
String cssAlignItems(core.CrossAlign align) => switch (align) {
  core.CrossAlign.start => 'start',
  core.CrossAlign.center => 'center',
  core.CrossAlign.end => 'end',
  core.CrossAlign.stretch => 'stretch',
  core.CrossAlign.baseline => 'baseline',
};

/// A model [core.Overflow] as the CSS `overflow` keyword.
///
/// A scrollable box maps to `auto`, so scrollbars appear only when the content
/// actually overflows — which is what a Flutter `SingleChildScrollView` does too.
String cssOverflow(core.Overflow overflow) => switch (overflow) {
  core.Overflow.visible => 'visible',
  core.Overflow.hidden => 'hidden',
  core.Overflow.scroll => 'auto',
};

/// How a scrolling box settles, as `scroll-snap-type`, or `null` for a box that does not.
///
/// The axis is the box's own, which is why this is a function of the style rather than of the
/// token alone: a row of pages pages sideways and a column of pages pages down, and CSS wants
/// that axis written out.
String? cssScrollSnap(core.ScrollSnap? snap, core.Axis axis) => switch (snap) {
  null || core.ScrollSnap.none => null,
  core.ScrollSnap.page =>
    axis == core.Axis.horizontal ? 'x mandatory' : 'y mandatory',
};

/// A model [core.BoxPin] as the CSS property that names its edge.
///
/// `top` and `bottom` rather than a logical pairing: the two edges a pin holds are the
/// vertical ones, and a vertical scroller is what the model lets one sit in. The value is
/// the box's own inset, written next to the property.
String cssPinEdge(core.BoxPin pin) => switch (pin) {
  core.BoxPin.start => 'top',
  core.BoxPin.end => 'bottom',
};

/// A model [core.FontWeight] as the number CSS wants.
///
/// The model names four weights and CSS accepts any hundreds value; the number is
/// written rather than `normal` or `bold`, so a host that sets a weight between two
/// of the model's cannot be surprised by what `bold` resolves to.
String cssFontWeight(core.FontWeight weight) => switch (weight) {
  core.FontWeight.light => '300',
  core.FontWeight.normal => '400',
  core.FontWeight.medium => '500',
  core.FontWeight.semiBold => '600',
  core.FontWeight.bold => '700',
};

/// A model [core.TextDecoration] as the CSS `text-decoration` keyword.
///
/// The shorthand, not `text-decoration-line`, so the whole of the line is stated:
/// the three values the model has are solid, and a shorthand is what resets a
/// decoration style a host stylesheet may have set. `none` is written rather than
/// left out, because it is how a run of text takes back a propagated line.
String cssTextDecoration(core.TextDecoration decoration) =>
    switch (decoration) {
      core.TextDecoration.none => 'none',
      core.TextDecoration.lineThrough => 'line-through',
      core.TextDecoration.underline => 'underline',
    };

/// A model [core.TextAlign] as the CSS `text-align` keyword.
String cssTextAlign(core.TextAlign align) => switch (align) {
  core.TextAlign.left => 'left',
  core.TextAlign.center => 'center',
  core.TextAlign.right => 'right',
  core.TextAlign.justify => 'justify',
};

/// A model [core.BoxBorder] as CSS writes a `border`.
///
/// Width, style, colour: the order a stylesheet is written in by hand, and the one a
/// reader scanning the output expects. CSS accepts the three in any order.
String cssBorder(core.BoxBorder border) =>
    '${cssPixels(border.width)} solid ${cssColor(border.color)}';

/// A model [core.BoxShadow] as CSS writes one shadow.
///
/// Offset, blur, spread, colour — the order CSS reads them in. A role colour is written
/// as its custom property, so a shadow follows the theme the way a fill does, and the blur
/// goes through [cssShadowBlur], because the two hosts state a blur in different units.
String cssBoxShadow(core.BoxShadow shadow) => <String>[
  cssPixels(shadow.offsetX),
  cssPixels(shadow.offsetY),
  cssShadowBlur(shadow.blurRadius),
  cssPixels(shadow.spreadRadius),
  cssColorOrRole(shadow.color),
].join(' ');

/// A shadow's blur as CSS writes it, so the shadow is as wide as that number in Flutter.
///
/// The two hosts measure a blur differently. Flutter reads a `BoxShadow.blurRadius` of `r`
/// as a gaussian with a standard deviation of `0.57735 * r + 0.5` — the formula
/// `BoxShadow.toPaint` uses — while a browser reads a `blur-radius` of `b` as a gaussian of
/// `b / 2`. Written through untouched, one token paints two shadows: a card's level one
/// blur of two is a deviation of 1.65 in the application and of one in the browser, so the
/// shadow under its edge read 60, 34, 19, 10, 4, 1 — darkness out of 255, row by row below
/// the card — on the page where the app read 55, 39, 25, 14, 7, 3: darker at the edge and
/// gone sooner, which is a card that reads as raised higher than the one beside it.
///
/// So the number is inverted on the way out: `2 * (0.57735 * r + 0.5)`, to two decimals,
/// which is finer than a blur can be seen. The same card then reads 54, 40, 23, 12, 5, 2
/// against the app's 55, 39, 25, 14, 7, 3.
///
/// A radius of nothing stays nothing. Flutter's formula leaves half a pixel of standard
/// deviation there, which is invisible, where a whole CSS pixel of it would not be: a
/// hairline drawn as a shadow with no blur — the model's way of drawing a line — would
/// soften into a smear.
String cssShadowBlur(double blurRadius) {
  if (blurRadius == 0) {
    return cssPixels(0);
  }

  final double cssBlur =
      2 * (_blurSigmaPerRadius * blurRadius + _blurSigmaBase);

  return cssPixels((cssBlur * 100).roundToDouble() / 100);
}

/// How much of a blur radius becomes a gaussian's standard deviation, in Flutter.
const double _blurSigmaPerRadius = 0.57735;

/// The half pixel Flutter adds to the deviation of every blur, whatever its radius.
const double _blurSigmaBase = 0.5;

/// The shadows of a box as CSS writes a `box-shadow` list.
///
/// One shadow per entry, comma separated, in the order the model states them — which is
/// the order CSS paints them in, the first on top. An elevation is several layers in
/// Material and in Flutter, so a box that writes one shadow is the special case here.
String cssBoxShadows(List<core.BoxShadow> shadows) =>
    shadows.map(cssBoxShadow).join(', ');

/// A font family as CSS writes it: one family, quoted.
///
/// A quoted name is one family; an unquoted list of words would be read as a
/// fallback chain, which is a different thing and is the host's to write. A name
/// that contains a single quote is wrapped in double quotes instead of being
/// escaped, which keeps the declaration readable.
String cssFontFamily(String family) {
  final bool hasSingle = family.contains("'");

  return hasSingle ? '"$family"' : "'$family'";
}

/// The declarations that make the descendants of a box inherit its typography.
///
/// Every token maps to a property CSS inherits by default — `font-size`,
/// `font-weight`, `font-family`, `line-height`, `letter-spacing` and `color` — which
/// is what makes a box behave like the `DefaultTextStyle` a Flutter box installs. The
/// line height is written unitless so descendants scale with their own font size,
/// exactly like `TextStyle.height`.
///
/// Returns `null` when [style] sets no token, so a box without typography emits no
/// font declaration at all and inherits from its parent, as it does in Flutter.
CssDeclarations? typographyDeclarations(core.BoxTextStyle style) {
  if (style.isEmpty) {
    return null;
  }

  final double? fontSize = style.fontSize;
  final core.FontWeight? fontWeight = style.fontWeight;
  final core.BoxColor? color = style.color;
  final String? fontFamily = style.fontFamily;
  final double? letterSpacing = style.letterSpacing;
  final double? lineHeight = style.lineHeight;
  final core.TextDecoration? decoration = style.decoration;
  final core.BoxColor? decorationColor = style.decorationColor;
  final double? decorationThickness = style.decorationThickness;

  return CssDeclarations()
    ..addIf('font-size', fontSize == null ? null : cssPixels(fontSize))
    ..addIf(
      'font-weight',
      fontWeight == null ? null : cssFontWeight(fontWeight),
    )
    ..addIf('color', color == null ? null : cssColorOrRole(color))
    ..addIf(
      'font-family',
      fontFamily == null ? null : cssFontFamily(fontFamily),
    )
    ..addIf(
      'letter-spacing',
      letterSpacing == null ? null : cssPixels(letterSpacing),
    )
    ..addIf('line-height', lineHeight == null ? null : cssNumber(lineHeight))
    // The shorthand is declared before the two longhands, and the sheet sorts by
    // property name, so `text-decoration` stays ahead of them: the shorthand resets
    // a decoration's colour and thickness, and the two have to follow it to win.
    ..addIf(
      'text-decoration',
      decoration == null ? null : cssTextDecoration(decoration),
    )
    ..addIf(
      'text-decoration-color',
      decorationColor == null ? null : cssColorOrRole(decorationColor),
    )
    ..addIf(
      'text-decoration-thickness',
      decorationThickness == null ? null : cssPixels(decorationThickness),
    );
}

/// The typography a document starts from.
///
/// The tokens are [core.BoxTextStyle.defaults], so both renderers answer with the
/// same numbers. Only the family is spelled here: the model names none, because a
/// font file is an asset of the application, and unset means "the platform's UI
/// font" — which Flutter gets by saying nothing, and CSS by naming the generic
/// `system-ui`. The family is written unquoted, because a quoted `'system-ui'` would
/// name a font that no platform installs.
CssDeclarations defaultTypographyDeclarations() {
  final CssDeclarations declarations =
      typographyDeclarations(core.BoxTextStyle.defaults) ?? CssDeclarations();

  return declarations..add('font-family', 'system-ui');
}

/// The declarations a page starts from, before a box states one of its own.
///
/// [defaultTypographyDeclarations] is the model's typography, and the one other declaration is
/// browser chrome no node draws: a touch browser paints a highlight of its own over whatever it
/// thinks was pressed, which is a blue flash over a control whose tree already answers a press
/// with ink and a state layer. The property is inherited, so the root switches it off once and
/// no control has to know about it.
CssDeclarations rootDeclarations() =>
    defaultTypographyDeclarations()
      ..add('-webkit-tap-highlight-color', 'transparent');

/// The four corner radii of [corners], in CSS's order: top left, top right,
/// bottom right, bottom left.
String cssCorners(core.BoxBorderRadius corners) =>
    corners.radii.map(cssPixels).join(' ');

/// A model [core.BoxTransform] as CSS writes a `transform`, or `null` when it
/// changes nothing.
///
/// The three functions are always listed in the model's order — translate, rotate,
/// scale — because CSS only interpolates two transforms function by function when the
/// lists match. `transform-origin` is not written: CSS centres a transform by default
/// and the Flutter renderer turns and scales about the middle of the box too.
/// A fraction of the parent, as CSS writes it: `0.5` becomes `50%`.
String? cssFraction(double? fraction) =>
    fraction == null ? null : '${cssNumber(fraction * 100)}%';

String? cssTransform(core.BoxTransform? transform) {
  if (transform == null || transform.isIdentity) {
    return null;
  }

  // The two axes are separate, and each multiplies the one factor: a control can grow
  // sideways at its full height, which a single `scale` cannot say.
  final String x = cssNumber(transform.scale * transform.scaleX);
  final String y = cssNumber(transform.scale * transform.scaleY);

  // Two translate functions where both kinds are stated, which is how CSS composes them: the
  // pixels land first, then the multiple of the box's own size. One function could not say both.
  final bool hasPixels = transform.offsetX != 0 || transform.offsetY != 0;
  final bool hasFractions =
      transform.fractionX != 0 || transform.fractionY != 0;

  return <String>[
    if (hasPixels)
      'translate(${cssPixels(transform.offsetX)}, '
          '${cssPixels(transform.offsetY)})',
    if (hasFractions)
      'translate(${cssNumber(transform.fractionX * 100)}%, '
          '${cssNumber(transform.fractionY * 100)}%)',
    'rotate(${cssNumber(transform.rotation)}deg) scale($x, $y)',
  ].join(' ');
}

/// The CSS property of every look, in the order a transition lists them.
///
/// The paint first, then what is painted on top of it. A border width is left out on
/// purpose: CSS animates it as a layout change and Flutter as a paint change, so the
/// two targets would agree on the duration and disagree on what moves.
const Map<core.BoxProperty, String> transitionedProperties =
    <core.BoxProperty, String>{
      core.BoxProperty.backgroundColor: 'background-color',
      core.BoxProperty.borderColor: 'border-color',
      core.BoxProperty.borderRadius: 'border-radius',
      core.BoxProperty.shadows: 'box-shadow',
      core.BoxProperty.opacity: 'opacity',
      core.BoxProperty.transform: 'transform',
    };

/// A model [core.BoxTransition] as CSS writes the `transition` shorthand.
///
/// Only the paint properties are listed, for the reason [transitionedProperties]
/// gives.
String cssTransition(core.BoxTransition transition) => <String>[
  for (final MapEntry<core.BoxProperty, String> entry
      in transitionedProperties.entries)
    '${entry.value} ${cssTiming(transition, entry.key)}',
].join(', ');

/// The `duration curve delay` of [look], as CSS writes it.
///
/// The delay is omitted when a part does not have one, which is the common case and
/// the shorter declaration.
String cssTiming(core.BoxTransition transition, core.BoxProperty look) {
  final core.BoxTransitionTiming timing = transition.timingOf(look);
  final String base =
      '${timing.duration.inMilliseconds}ms ${cssCurve(timing.curve)}';

  return timing.delay == Duration.zero
      ? base
      : '$base ${timing.delay.inMilliseconds}ms';
}

/// The CSS timing function of [curve].
String cssCurve(core.BoxCurve curve) => switch (curve) {
  core.BoxCurve.linear => 'linear',
  core.BoxCurve.ease => 'ease',
  core.BoxCurve.easeIn => 'ease-in',
  core.BoxCurve.easeOut => 'ease-out',
  core.BoxCurve.easeInOut => 'ease-in-out',
};

/// The colours of a theme, as the `:root` block a document starts from.
///
/// A theme answers the roles a tree names, once, and every rule that names a role is
/// written as `var(--unibox-color-primary)`. Writing them here is what lets a host
/// stylesheet or a dark-mode block outrank the tree without touching it.
///
/// A theme whose roles clash is the theme's problem to report, not this function's:
/// `UniboxTheme.clashes` names the two roles that would claim one property.
CssDeclarations themeDeclarations(core.UniboxTheme theme) {
  final CssDeclarations declarations = CssDeclarations();

  for (final MapEntry<String, core.BoxColor> entry in theme.variables.entries) {
    declarations.add(entry.key, cssColorOrRole(entry.value));
  }

  return declarations;
}
