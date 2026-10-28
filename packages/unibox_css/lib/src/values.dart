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
