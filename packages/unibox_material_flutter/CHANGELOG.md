# Changelog

## Unreleased

- **`uniboxThemeOf(ColorScheme)`**, the inverse of `materialThemeData`: an application that already has a `ColorScheme` hands it a tree, and every role the model names is answered from it. Growing a palette from the same seed would be a second run of the colour algorithm, which agrees until a tone is overridden. A design system's own roles are passed with `also:`; the four state layers are the alpha they are painted with.
- **A substituted card wears the tree's corner, fill and clip.** `MaterialCard` states a radius, a colour role and `overflow: hidden`, and the mapping drew `Card` with `CardTheme`'s square corners and the theme's colour, so a ripple ran past the edge and an application's palette stopped at the card. The widget now takes all three from the node.
- **The map is the standard wiring of a Flutter host**, not an experiment: a document is served
  first and the application takes it over, so the app draws Material nodes with Flutter's own
  widgets on every screen. `MaterialListTile` (as `ListTile`),
  `MaterialTextField` (as `TextField`) and `MaterialSpinner` (as `CircularProgressIndicator`)
  join it — the last two because the door now reaches a `StatefulNode` too, which is how a
  field, a tab set or a spinner is drawn by a widget of its own.

- `MaterialSegmentedButton` stays out too: Flutter's `SegmentedButton` hugs its labels where
  the node divides the width equally, so the swap changes the layout rather than the surface.

- `MaterialTabBar` stays out deliberately: a `TabBar` is half a component — a controller and a
  view — and Flutter asserts the tab role on its children, which a strip drawn from a node
  cannot promise. So do `MaterialScaffold`, `MaterialTabs`, `MaterialDialog` and
  `MaterialBottomSheet`, whose slots and policy live in the node.

- `materialThemeData(palette)` is the other half of the map: a `ThemeData` built role by role
  from a `MaterialPalette`. A substituted widget takes its colours from `ColorScheme` and its
  type from `TextTheme`, so without one it paints Flutter's baseline purple beside a page that
  was drawn in the brand's colours. Built from the roles rather than from a seed, so there is no
  second run of the colour algorithm to keep in step; the roles a `ColorScheme` names and the
  palette does not (`tertiary`, `inverseSurface`, `onErrorContainer`) keep Flutter's defaults.

- `materialComponents()` is the map an application hands to `renderFlutter` to draw
  `unibox_material`'s components with the platform's own widgets: a `MaterialCard` as a `Card`,
  a `MaterialNavigationBar` as a `NavigationBar`, and now a button (as `FilledButton`,
  `FilledButton.tonal`, `OutlinedButton` or `TextButton`), a chip (as `FilterChip`, or
  `InputChip` when it has a cross), an icon button (as `IconButton`) and a progress ring (as
  `CircularProgressIndicator`). The words, the order of the destinations and
  the chosen page survive the swap; the pixel does not, by design.
