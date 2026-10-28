# Changelog

## Unreleased

- `MaterialChip`'s close target centres the cross it holds, so the ring a hover or a
  focus draws around it sits on the cross rather than four pixels to its left: the well
  is a column, and without a cross alignment its node hugged the start of the target.

- `MaterialSegmentedButton` takes a `width`, and the segments share it equally. Without
  one each segment hugs its label: a `flex` in an unbounded row is a layout error in
  Flutter, so equal shares need a bound to divide.

## 0.1.0

- `MaterialSegmentedButton` draws the check of the chosen segment, in place of its
  icon, the way Material does — drawn from boxes, because an icon font is a host asset
  — with `showSelectedIcon: false` for a control whose fill is enough. `iconSize`
  states Material's 18 for a segment's icon and for that check, and a disabled control
  fades as one at 38% instead of looking pressable.

- `MaterialChip` follows Material 3's chip metrics rather than approximating them:
  `controlHeight` states the 32 the pill is, whatever glyph it carries (a leading node
  used to be able to make one chip taller than its neighbours); the padding is taken
  per side, 16 where the label reaches the edge and 8 where an `iconSize` = 18 node
  sits; and a disabled chip is drawn at 38% with no ink instead of looking pressable.

- `MaterialButton` keeps its fill — and the ink well inside it — the size of its label,
  so a parent that stretches its children (a card's column, a grid track) no longer
  paints a hover tint as a band wider than the button. `width:` pins the fill when a
  full-width button is what is wanted.
- `MaterialListTile`'s row fills the width the tile was given, which is what the
  trailing node needed to sit at the far edge instead of against the subtitle. The
  README has claimed the row fills since the tile was written; now the row does.

- `MaterialChip` takes `leading` and `trailing` nodes, and `onRemove` makes it an input
  chip: the trailing node is wrapped in a round 18 pixel target of its own, so a press
  on the cross removes the chip rather than choosing it. `MaterialSegment` grew the same
  idea the other way round — a segment's `icon` sits before its label.

- `MaterialSegmentedButton`: Material 3's segmented button — two to five choices in one
  40 pixel pill at radius 20, a 1 pixel outline around it and between its segments,
  equal shares, the chosen one filled with `secondaryContainer` and announced as
  selected. A chosen segment has no checkmark: that is a glyph from a font the package
  does not ship, and `MaterialSegment.icon` is how one is given.
- `MaterialInkWell` takes `mainAlign` and `crossAlign` and stretches its stack, so a
  well given a size is filled rather than hugged: the tints belong to the whole region,
  which a segmented button needs and a chip was already getting by having one child.

- `MaterialChip`: a Material 3 filter chip — the small 8 pixel shape at 32 pixels tall,
  a 1 pixel `outline` line and an `onSurfaceVariant` label when it is not chosen, a
  `secondaryContainer` fill and an `onSecondaryContainer` label when it is, 16 pixels
  of room in the well and a button role that says whether it is chosen. The room sits
  in the ink well alone, so a hover tint reaches exactly the edge of the pill.
- `secondary`, `onSecondary`, `secondaryContainer` and `onSecondaryContainer` join the
  colour roles: the accent a chosen control wears, which a chip and a segmented button
  fill with.

- `MaterialElevation`: the five levels of Material 3 as the shadow each one casts,
  plus the upward level a sheet throws. `MaterialCard.elevatedShadow`,
  `MaterialDialog.elevation` and the bottom sheet's shadow are now this scale rather
  than three near-copies, and a dialog's level is stated at the level's own value
  (0 4px 8px at 15%) instead of a shadow of its own.

- `MaterialCard` stretches the children it holds (`crossAlign: CrossAlign.stretch`,
  still a parameter). A card's content spans the card, and a `width: double.infinity`
  inside it means the same thing on both targets: a browser resolves `100%` against a
  parent's width, so inside a column that hugged its content the rows of a card
  stopped half way across it on the web while Flutter filled the width it was handed.

- `MaterialTextField.initialValue` seeds the text of a field the form does not control,
  where `value` takes it over; the gallery's two fields are the same field in the
  label's two positions now, both validating.
- A full-width `MaterialInkWell` (and so a `MaterialListTile`) fills its row on the web: a
  trailing part sits at the edge instead of beside the text.
- `MaterialTextField` stretches across the width it is given, so a web page draws it
  as wide as the Flutter one instead of as wide as its label.
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
- `MaterialTextField` is a `StatefulNode`: `MaterialFieldStore` holds the text, the
  focus and whether the user has touched the field, so it draws its own focus line,
  floating label and error, and a `validator` is asked as the address is typed. `value`
  and `error` still let a form control the text and show a message of its own. This
  replaces `focused:`, `invalid:` and `message:`, which the host had to keep for it.
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
- Every component states its name (`material-card`, `material-list-tile`,
  `material-text-field`, `material-icon`, `material-dialog`, `material-bottom-sheet`),
  so an inspector reads the component rather than the box it extends.
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
- `MaterialButton`: the four Material 3 shapes — `filled`, `tonal`, `outlined` and
  `text` — as one `Box` around a `MaterialInkWell`, so a press inks the button over its
  fill. Every colour is a role, the label is `labelLarge`, the radius is 20, an optional
  `icon` sits before the label, and a disabled button keeps its place without its ink.
- `MaterialListTile` is now a row wrapped in a `MaterialInkWell`, so a press inks it
  where it landed instead of only tinting it, and its state layers are roles the host
  theme answers. `MaterialListTile.row` is the row itself, and a `borderRadius`
  parameter clips the tile's own tint and ink.
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
