# Changelog

## 0.1.0

- `MaterialTextField` and `MaterialBottomSheet` draw Material's shape: round at the
  top, square where they meet the line or the edge, now that the model has a
  corner token.
- `MaterialInkWell` is a tappable region: Material's hover, focus and press tints as
  roles, a 100ms fade, a button role when it can be tapped, and **the ink a press
  spreads** — a 12% drop that starts where the pointer landed, grows to 280 pixels and
  fades over 450ms. The ripple is state rather than a renderer feature, so both targets
  draw it out of nodes they already draw; a page with no client runtime shows the
  resting well. It paints no surface of its own, so the filled box goes around it.
- The first release: Material 3 as a package of values, plus the components built
from them. Every value here is a plain token of `unibox_core`, so neither renderer
has to know this package exists.

- `MaterialCard.filled`, `.outlined` and `.elevated` take the card's whole parameter list,
  as `Card.filled` and `Card.outlined` do in Flutter, and let the surface, the line
  and the shadow they start from be replaced.
- `MaterialTextField` has Material 3's two label states: empty and unfocused, the
  label is the line inside the field at body size in the quieter colour and the hint
  waits behind it; with a value or focus, the label shrinks to the top of the fill and
  the value takes the row below, so the field is 56 pixels in both states. The move
  steps rather than eases: a layout change has no transition in the model.
- `MaterialTextField` is Material 3's filled field: `surfaceContainerHighest`, a 4 pixel radius, a bottom line drawn as a shadow (one pixel, two when focused, the error colour when invalid), the label inside the fill and the padding on the input, so the whole field takes focus.
- `MaterialIcon`: one glyph of an icon font in a square `Box`, by codepoint (which the
  Flutter tree shaker can subset from a const `IconData`) or by ligature name (which it
  cannot), recoloured and scaled like text. The font is a host asset.
- Fidelity pass against Material 3: `MaterialCard.elevated`/`.filled`/`.outlined` on the
  palette; list tile with 8 pixel vertical padding and palette colours; text field with
  a 56 pixel minimum height, 2 pixel focused outline, primary focused label, hover
  outline and disabled opacity; dialog content in `onSurfaceVariant` and `primary`
  `labelLarge` actions; a full-width bottom sheet with a drag handle and a rising shadow.
- `MaterialTypography`: the fifteen roles of the Material 3 type scale as `const`
  `BoxTextStyle` values, with `MaterialTypeRole` to name one in a table or a test and
  `MaterialTypography.of` to look one up.
- `MaterialPalette` and `MaterialColorRole`: the colour roles as `const` `BoxColor`
  values, with a baseline light and dark scheme and the state layers Material derives
  from `onSurface` — 8% hover, 10% focus and press, 16% dragged, and the 32% scrim.
  `MaterialPalette.lightTheme` and `darkTheme` are those palettes as a `UniboxTheme`,
  which is what a component's role resolves against.
- `MaterialCard`: a card as a node that extends `Box` — 16 of padding, a white
  surface, a 12 pixel radius, the shade of elevation level one and `bodyMedium` for
  the texts inside, every one of them a parameter.
- `MaterialListTile`: the list row — a leading node, a title with an optional
  subtitle and a trailing node, 16 between its parts, the one and two line heights
  Material gives a tile (and their dense pair), `bodyLarge` for the title,
  `bodyMedium` in `onSurfaceVariant` for the subtitle, the 8% and 10% hover and press
  layers, and the button role when the tile can be tapped.
- ~~`MaterialInkWell`~~ was withdrawn: a button is a box with a state layer, and the
  name promised an ink ripple the web cannot draw yet.
- `MaterialTextField`: a label, an outlined box and a message around a
  `TextInputNode`, its outline taking the accent on focus and the error colour when
  invalid.
- `MaterialDialog` and `MaterialBottomSheet`: `OverlayNode`s with the policy they
  need — scrim, dismissal, alignment — and a raised surface with a title and a row of
  actions.

Every component names a **role** rather than a colour, so one theme restyles all of
them: a dark application renders the same tree with `theme: MaterialPalette.darkTheme`.
The components no longer take a `palette:` argument, because a role is the indirection
that argument used to provide.

What the components leave to the platform is written on each of them: the floating
label, the caret and selection colours, and Material's modal transitions.
