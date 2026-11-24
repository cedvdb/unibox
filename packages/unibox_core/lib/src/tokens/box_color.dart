/// An immutable 32-bit ARGB color value (`0xAARRGGBB`).
///
/// Colors are platform agnostic: the renderers translate the channel values to
/// Flutter's `Color` or to a CSS color function.
///
/// ```dart
/// const brand = BoxColor.rgb(0x2D, 0x6C, 0xF3);
/// final overlay = brand.withOpacity(0.5);
/// ```
///
/// This class is one color. The palette of common names lives next door in
/// [BoxColors]; anything else is [BoxColor.rgb], [BoxColor.rgba] or a raw value.
///
/// A color can also be a **role**: [BoxColor.role] names a color the application
/// owns (its primary, its surface, its error) instead of fixing a value in the
/// tree. A role has no channels of its own — a [UniboxTheme] gives it one, on the
/// web as a CSS custom property (`var(--unibox-color-primary)`) and in Flutter by
/// resolving it while the widget tree is built. Reading [value] from a role that
/// was never resolved throws, so a missing theme is a loud failure rather than a
/// transparent box.
final class BoxColor {
  /// Creates a color from a raw `0xAARRGGBB` value.
  const BoxColor(int value)
    : _value = value,
      role = null,
      _roleAlpha = 0xFF,
      assert(value >= 0 && value <= 0xFFFFFFFF, 'value must fit in 32 bits');

  /// Creates a color the theme defines under [role], painted at [alpha].
  ///
  /// The role is an `enum` member, so a misspelling is a compile error and the
  /// theme's map is keyed by the same value: a role the theme forgets is found by
  /// `validateTree`, not by a reader looking at a blank box.
  ///
  /// [alpha] is the one thing a tree may state about a role besides which role it is, and
  /// it is what a state layer is made of: `BoxColor.role(onPrimary, 20)` is the accent
  /// content colour at eight percent, which is what Material tints a filled button with
  /// while the pointer rests on it. A theme resolves the role and keeps the alpha, so the
  /// page (a `color-mix` of the custom property) and the application (the resolved colour)
  /// paint the same tint without either of them naming a value.
  const BoxColor.role(this.role, [int alpha = 0xFF])
    : assert(alpha >= 0 && alpha <= 0xFF, 'alpha must be between 0 and 255'),
      _value = 0,
      _roleAlpha = alpha;

  /// Creates an opaque color from its red, green and blue channels.
  const BoxColor.rgb(int red, int green, int blue)
    : assert(red >= 0 && red <= 0xFF, 'red must be between 0 and 255'),
      assert(green >= 0 && green <= 0xFF, 'green must be between 0 and 255'),
      assert(blue >= 0 && blue <= 0xFF, 'blue must be between 0 and 255'),
      _value = 0xFF000000 | (red << 16) | (green << 8) | blue,
      role = null,
      _roleAlpha = 0xFF;

  /// Creates a color from its red, green, blue and alpha channels.
  ///
  /// [alpha] is expressed as `0` (fully transparent) to `255` (fully opaque).
  const BoxColor.rgba(int red, int green, int blue, [int alpha = 0xFF])
    : assert(red >= 0 && red <= 0xFF, 'red must be between 0 and 255'),
      assert(green >= 0 && green <= 0xFF, 'green must be between 0 and 255'),
      assert(blue >= 0 && blue <= 0xFF, 'blue must be between 0 and 255'),
      assert(alpha >= 0 && alpha <= 0xFF, 'alpha must be between 0 and 255'),
      _value = (alpha << 24) | (red << 16) | (green << 8) | blue,
      role = null,
      _roleAlpha = 0xFF;

  /// A fully transparent color.
  static const BoxColor transparent = BoxColor(0x00000000);

  /// Opaque black.
  static const BoxColor black = BoxColor(0xFF000000);

  /// Opaque white.
  static const BoxColor white = BoxColor(0xFFFFFFFF);

  /// The role this color names, or `null` when it carries channels of its own.
  final Enum? role;

  /// Whether this color is a role a theme has to resolve.
  bool get isRole => role != null;

  final int _value;

  /// The alpha a role is painted at. A colour with channels of its own carries its alpha in
  /// [_value], so this is the opaque default for it.
  final int _roleAlpha;

  /// The raw `0xAARRGGBB` value of this color.
  ///
  /// Throws for a role, which has no colour until a theme gives it one: reading
  /// it anyway means the renderer was given a tree with roles and no theme, and
  /// failing here says so instead of painting nothing.
  int get value {
    final Enum? named = role;

    if (named != null) {
      throw StateError(
        'This color is the role $named and has no value until a theme resolves '
        'it. Pass a UniboxTheme to the renderer, or to validateTree.',
      );
    }

    return _value;
  }

  /// The alpha channel, `0` (transparent) to `255` (opaque).
  ///
  /// A role states one too, and reading it is not reading [value]: the colour is the
  /// theme's to give, while the alpha is the tree's to state.
  int get alpha => role == null ? (_value >> 24) & 0xFF : _roleAlpha;

  /// The red channel, `0` to `255`.
  int get red => (value >> 16) & 0xFF;

  /// The green channel, `0` to `255`.
  int get green => (value >> 8) & 0xFF;

  /// The blue channel, `0` to `255`.
  int get blue => value & 0xFF;

  /// The alpha channel as a fraction between `0.0` and `1.0`.
  double get opacity => alpha / 0xFF;

  /// Whether this color has no visible alpha.
  bool get isTransparent => alpha == 0;

  /// Whether this color is fully opaque.
  bool get isOpaque => alpha == 0xFF;

  /// Returns a copy of this color with the given [alpha] channel (`0`-`255`).
  ///
  /// A role stays a role: what changes is the alpha it is painted at, which is how a state
  /// layer names a colour the theme supplies rather than one the tree fixes.
  BoxColor withAlpha(int alpha) => role == null
      ? BoxColor.rgba(red, green, blue, alpha)
      : BoxColor.role(role!, alpha);

  /// Returns a copy of this color with the given [opacity] (`0.0`-`1.0`).
  BoxColor withOpacity(double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    return withAlpha((clamped * 0xFF).round());
  }

  @override
  bool operator ==(Object other) =>
      other is BoxColor &&
      other.role == role &&
      other._value == _value &&
      other._roleAlpha == _roleAlpha;

  @override
  int get hashCode => Object.hash(role, _value, _roleAlpha);

  @override
  String toString() => role == null
      ? 'BoxColor(0x${_value.toRadixString(16).padLeft(8, '0').toUpperCase()})'
      : 'BoxColor.role($role${isOpaque ? '' : ', ${opacity.toStringAsFixed(2)}'})';
}
