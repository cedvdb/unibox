import 'package:unibox_core/unibox_core.dart' as core;

/// A number without a needless `.0`, which both CSS and a reader prefer.
///
/// It is the one spelling of a number in this package: a declaration, a class
/// name and a test all read the same text, so `8` cannot become `8.0px` in one
/// place and `8px` in another.
String cssNumber(double value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// [value] in logical pixels, as CSS writes a length.
String cssPixels(double value) => '${cssNumber(value)}px';

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
String cssAlignItems(core.CrossAlign align) => switch (align) {
  core.CrossAlign.start => 'start',
  core.CrossAlign.center => 'center',
  core.CrossAlign.end => 'end',
  core.CrossAlign.stretch => 'stretch',
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

/// A model [core.FontWeight] as the number CSS wants.
///
/// The model names four weights and CSS accepts any hundreds value; the number is
/// written rather than `normal` or `bold`, so a host that sets a weight between two
/// of the model's cannot be surprised by what `bold` resolves to.
String cssFontWeight(core.FontWeight weight) => switch (weight) {
  core.FontWeight.normal => '400',
  core.FontWeight.medium => '500',
  core.FontWeight.semiBold => '600',
  core.FontWeight.bold => '700',
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
/// CSS states the style first, then the colour, then the width, which is the order
/// the declaration is written in here.
String cssBorder(core.BoxBorder border) =>
    'solid ${cssColor(border.color)} ${cssPixels(border.width)}';

/// A model [core.BoxShadow] as CSS writes one shadow.
///
/// Offset, blur, spread, colour — the order CSS reads them in.
String cssBoxShadow(core.BoxShadow shadow) => <String>[
  cssPixels(shadow.offsetX),
  cssPixels(shadow.offsetY),
  cssPixels(shadow.blurRadius),
  cssPixels(shadow.spreadRadius),
  cssColor(shadow.color),
].join(' ');

/// The four corner radii of [corners], in CSS's order: top left, top right,
/// bottom right, bottom left.
String cssCorners(core.BoxBorderRadius corners) =>
    corners.radii.map(cssPixels).join(' ');
