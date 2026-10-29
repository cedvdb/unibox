import 'box_color.dart';

/// The values a tree's roles stand for.
///
/// A role is a name the application owns — its primary, its surface, its error —
/// and a theme is the one place those names are given colours. It is a **value**,
/// passed to a renderer, never something a node looks up: two pages rendered in one
/// process can carry different themes, a tree stays `const`, and nothing resolves
/// at paint time.
///
/// ```dart
/// enum AppColor { primary, onPrimary, surface, outline }
///
/// const theme = UniboxTheme(
///   colors: <AppColor, BoxColor>{
///     AppColor.primary: BoxColor(0xFF6750A4),
///     AppColor.surface: BoxColor(0xFFFEF7FF),
///   },
/// );
///
/// const Box(backgroundColor: BoxColor.role(AppColor.primary));
/// ```
///
/// The web renderer writes the theme once, in a `:root` block, and points every role
/// at its custom property, so a host stylesheet or a dark-mode block can outrank it.
/// The Flutter renderer resolves each role while it builds the widget tree. Both read
/// the same value, which is what stops the palette from being a third copy of the
/// design system.
/// The scheme a theme's values are painted in.
///
/// It is not a preference: it is the fact a `color-scheme` declaration states, so the chrome the
/// tree does not draw — scrollbars, the caret, the canvas before the stylesheet applies, a
/// `<select>` popup — is painted to match the page rather than to match the reader's operating
/// system. A light page in a dark-mode browser otherwise gets dark scrollbars and a white caret,
/// which is the one place a system preference legitimately leaked into a tree that never asked
/// for it.
///
/// The default is [light], which is what values making no claim about their own brightness
/// imply. No renderer ever reads `prefers-color-scheme` or a platform's brightness on its own: a
/// host that wants to follow the reader picks a theme, and says which one it installed.
enum BoxColorScheme {
  /// Light surfaces, dark ink.
  light,

  /// Dark surfaces, light ink.
  dark,
}

final class UniboxTheme {
  /// Creates a theme from [colors], painted in [colorScheme].
  const UniboxTheme({
    this.colors = const <Enum, BoxColor>{},
    this.colorScheme = BoxColorScheme.light,
  });

  /// The scheme these values are painted in.
  ///
  /// A theme that states nothing is [BoxColorScheme.light], because light is what values with no
  /// brightness claim imply — and a dark palette answers [BoxColorScheme.dark], so the host that
  /// installs one never writes the fact twice.
  final BoxColorScheme colorScheme;

  /// The colour of every role, keyed by the role itself.
  ///
  /// The key is the enum *value*, so a lookup is an identity comparison — no
  /// string, no name matching, and a role from another enum simply is not found.
  final Map<Enum, BoxColor> colors;

  /// A theme with no values.
  static const UniboxTheme none = UniboxTheme();

  /// Whether the theme defines nothing.
  bool get isEmpty => colors.isEmpty;

  /// The colour of [role], or `null` when the theme does not define it.
  BoxColor? colorOf(Enum role) => colors[role];

  /// [color] with its role looked up here.
  ///
  /// A colour that carries its own channels comes back unchanged, so a tree can
  /// mix roles and values. A role this theme does not define throws, naming it.
  BoxColor resolve(BoxColor color) {
    final Enum? role = color.role;

    if (role == null) {
      return color;
    }

    final BoxColor? value = colors[role];

    if (value == null) {
      throw StateError(
        'The role $role is not in this theme. Add it to UniboxTheme.colors, or '
        'use a colour that carries its own value.',
      );
    }

    return value;
  }

  /// This theme with [other]'s colours laid over it.
  ///
  /// A page built from one design system and drawn with another's components needs
  /// both vocabularies: the roles of the second fill in what the first does not
  /// define, and a role both define keeps the value of this theme.
  UniboxTheme merge(UniboxTheme other) {
    if (other.isEmpty) {
      return this;
    }

    // This theme wins a role both define: it is the page's own vocabulary, and the
    // other is lending the roles the page does not name.
    return UniboxTheme(
      colors: <Enum, BoxColor>{...other.colors, ...colors},
      colorScheme: colorScheme,
    );
  }

  /// The CSS custom property a colour role is written as: `--unibox-color-primary`.
  ///
  /// The name is the enum member in kebab case, so it is stable, greppable and
  /// typed where it is written. One colour enum per application keeps two roles
  /// from claiming the same property; `UniboxTheme.variables` reports a clash.
  static String cssNameOf(Enum role) => '--unibox-color-${_kebab(role.name)}';

  /// Every colour of the theme as a custom property and a CSS value.
  ///
  /// Declaration order, so the emitted `:root` block is stable for a given theme.
  Map<String, BoxColor> get variables => <String, BoxColor>{
    for (final MapEntry<Enum, BoxColor> entry in colors.entries)
      cssNameOf(entry.key): entry.value,
  };

  /// The role names two members of different enums share, if any.
  ///
  /// A clash would give two roles one custom property, so the last one would win
  /// silently on the web — worth reporting rather than discovering.
  List<String> get clashes {
    final Set<String> seen = <String>{};
    final List<String> clashes = <String>[];

    for (final Enum role in colors.keys) {
      if (!seen.add(cssNameOf(role))) {
        clashes.add(cssNameOf(role));
      }
    }

    return clashes;
  }

  /// `onPrimary` to `on-primary`, which is what a CSS property is spelled like.
  static String _kebab(String name) {
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < name.length; i++) {
      final String character = name[i];
      final bool upper = character.toUpperCase() == character;

      if (i > 0 && upper && character.toLowerCase() != character) {
        buffer.write('-');
      }

      buffer.write(character.toLowerCase());
    }

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is UniboxTheme && _sameColors(other.colors);

  @override
  int get hashCode => Object.hashAllUnordered(
    colors.entries.map(
      (MapEntry<Enum, BoxColor> e) => Object.hash(e.key, e.value),
    ),
  );

  bool _sameColors(Map<Enum, BoxColor> other) {
    if (colors.length != other.length) {
      return false;
    }

    for (final MapEntry<Enum, BoxColor> entry in colors.entries) {
      if (other[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  @override
  String toString() =>
      'UniboxTheme(${colors.entries.map((MapEntry<Enum, BoxColor> e) => '${e.key}: ${e.value}').join(', ')})';
}
