/// Draws `unibox_material`'s components with Flutter's own widgets.
///
/// A tree describes a screen for two renderers, and by default both draw the model's values,
/// which is what keeps a page and an application the same screen. This package is the door an
/// application uses when it would rather keep the behaviour of the widget it already had — the
/// platform's ink, its click, the reader's text scale, the accessibility work the framework has
/// done — for the material components whose look is a component and not a token.
///
/// It depends on both packages and nothing depends on it: a renderer knows nothing of a design
/// system, and a design system knows nothing of a renderer. The application installs the map.
///
/// **Experimental.** The rule it serves is settled — `design.md` §5.22 — and this is its first
/// draft: two components, a signature that may move, and open questions about how far a
/// substitution should reach. See the package README.
library;

export 'src/theme_of_color_scheme.dart' show uniboxThemeOf;
export 'src/material_components.dart'
    show materialComponents, materialThemeData;
