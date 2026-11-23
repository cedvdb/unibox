# Changelog

## Unreleased

- Preserve declared card outlines, chip corners and compact targets, and button widths when substituting native controls; buttons without a width hug their labels.

- Require native widget rendering for the retained vocabulary; preserve destinations, disabled state and chip selection. Unregistered icon glyphs are reported instead of approximated.

- **A glyph the host did not name is drawn as text, not as a run-time `IconData`.** `flutter build`
  records every `IconData` construction and refuses to subset the icon fonts when an argument is
  not a constant — *"This application cannot tree shake icons fonts. It has non-constant instances
  of IconData."* — and the fallback built one from the node's codepoint, which is exactly such an
  argument. Every application that drew a `MaterialIcon` node through this mapping could not be
  built with tree shaking on. The glyph is now the character itself, out of the family the node
  names, at the node's size and ink and with `TextScaler.noScaling` — the same glyph from the same
  font, which is what the document draws. A codepoint the host's `icons:` list does name still
  draws with `Icon` and its constant, which is what keeps it in the subset.
- **A segmented pill is outlined with the node's hairline.** `SegmentedButton` otherwise draws
  `ColorScheme.outline`, a step darker than the `outlineVariant` a tree names — so the same
  control was two colours: the application's against the document's.
- **A `MaterialIcons` glyph names its family.** The mapping built `IconData(codePoint)` and left the family to `IconData`'s default — which is Flutter's, not the platform's: a fork that defaults to no family draws the glyph from whatever font the text uses, and the value compares unequal to the `Icons.*` constant that names the same glyph (a `find.byIcon` cannot find it). The family is stated, as the Material Symbols one already was.
- **A segmented button hugs inside a row that scrolls, and expands where the page bounds it.** The mapping told `SegmentedButton` to expand always, which lays out at an infinite width inside a scrolling row — the action bar's row — and throws. What the document does with a grid of `width: 100%` is now the rule the app reads off its constraints: expand in a parent that bounds the pill, hug in one that sizes to content.
- **A chip with a cross answers its own pill as well as the cross.** `MaterialChip(onTap:, onRemove:)` states both ways to drop a filter, and the mapping dropped the first: the whole pill now removes, as it does on the page.
- **`uniboxThemeOf` answers the new roles.** `tertiary`, `onTertiary`, `primaryFixedDim` and `secondaryFixedDim` are read from the `ColorScheme` like the rest, so a tree that names them needs no map of its own.
- **`materialComponents(icons: …)`.** The icon mapping now takes the application's own `IconData` list and draws an icon with the constant it finds there. This is not decoration: Flutter's icon subsetter keeps a glyph only while an `IconData` naming it is part of the program, and a codepoint read out of one — `Icons.sell.codePoint` — is folded to an integer and dropped, so the glyph silently leaves the font. A glyph the list does not name is still drawn, from a `IconData` built at run time, with the caveat stated in the docs.
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
