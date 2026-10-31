# Changelog

## Unreleased

- **An icon button's count no longer takes the pointer.** The badge is decoration —
  `capturesPointer: false` — so the corner it covers keeps the control's hover, hand and press
  instead of answering with an arrow and no ink. The pill looks the same: 16 tall, `error`
  behind `onError`, pinned to the `topEnd` corner, out of the reading order.

- **The elevation scale is the design file's ladder, not Flutter's drawing.** A level is now
  one shade instead of three layers, fitted to `doc/shadows_material_3_pink_seed.png`: level one
  is `0 0.55px 0.61px` in black at 34% and clears within two and a half dp, where the three
  layers it replaces reached seven. On the page and in the app a card sat a level higher than
  the card beside it in the design file — level one read like the file's level two — and it no
  longer does. Levels two to five are one shade each at 40%, `0 0.95px 2.35px` up to
  `0 1.9px 6.5px`, so a surface still climbs the scale. A Flutter `Card` draws its own shadow
  with `Canvas.drawShadow` and is now a documented difference rather than the oracle: the
  example's suite pins each level against the ladder's measured rows instead of against a
  `Card`.

- **Breaking: `MaterialCard` is a surface, not a press.** `onTap`, `onLongPress` and
  `onHover` are gone from all four constructors, and the default padding is no longer 16.
  Flutter's `Card` has neither: a press belongs to the ink *inside* the card, which is the
  only composition that can paint a tint over the surface and clip the ink to its corners,
  and padding on the surface is room no press can reach. The recipe is *surface outside,
  ink inside, padding on the ink layer*:
  `MaterialCard(overflow: Overflow.hidden, children: [MaterialInkWell(url: ..., padding: BoxSpacing.all(16), child: content)])`.
  A caller who passed `onTap` gives the url or the callback to the well; one who relied on
  the 16 pixel padding states it where the room belongs.

- `MaterialInkWell` takes `url` (and `newTab`): the well becomes a `LinkNode` — a box that names
  a destination — and the anchor goes wherever the press goes: the shape in the plain case, the outer box when the
  well paints a surface, and the target when `tapTargetHeight` adds one. A url makes the well
  pressable with no callback, so it still ripples on tap-down. The region is built once and
  becomes a link with `LinkNode.of`, so the package keeps no copy of a box's fields.

- `MaterialInkWell` takes `shadows` and `textStyle`, so one well can be a whole surface: an
  interactive card is one element instead of a card around a well, with no ring of padding a
  press cannot reach and no equal-height problem in a grid.

- `MaterialButton`, `MaterialIconButton`, `MaterialListTile`, `MaterialChip` and
  `MaterialSegment` forward a `url` and a `newTab` to the well that carries their press, so a
  component is a destination by being given one. A chip with a url says which page it is
  (`aria-current`) instead of whether it is pressed, and it refuses an `onRemove`: a control
  inside a link is invalid HTML, so the two are composed side by side.

- `MaterialSegmentedButton` with segments that have a `url` is a set of links: each unchosen
  choice is one `<a href>`, the chosen one is the page being read — no link, not in the tab
  order, `aria-current="page"` — and `onSelect` is optional, because the destination is the
  press.

- `MaterialCard.filled` and `MaterialCard.outlined` say that they cast no shadow, instead
  of passing `null` through to a constructor whose default is the level one shadow. Nothing
  draws differently — a `null` shadow already painted nothing — but the signature now reads
  as the decision it is, and an empty list cannot be mistaken for "the default".

- `MaterialIconButton`: one glyph in a 40 pixel square, in the four Material 3 shapes
  (`standard`, `filled`, `tonal`, `outlined`), with the ink of a press, a name for a screen
  reader — the control has no text, so the name is all a reader has — and `badgeCount`, a
  count pill in `error`/`onError` over the top-right corner of the glyph, placed in the
  square rather than beside it so a number cannot grow the target a finger needs. Every
  application was drawing this by hand — Comover's filters control is a stack of a box, a
  glyph and a positioned pill — and the hand-built one loses the hover tint, the focus
  ring and the press it belongs to.

- `MaterialChip` takes `removeSemanticsLabel:`, the name its close announces. The cross of
  an input chip is a target with no text of its own, so it said "Remove" and nothing else:
  a row of applied filters read as the same button eleven times, and a screen reader could
  not tell a reader what was about to go. It defaults to "Remove", so nothing moves for a
  chip that does not name one.

- A label too long for its segment is cut with an ellipsis instead of failing the build.
  A segment is a share of the control's width, and the label was laid out at its own
  width: a translation, or any label at twice the text scale, raised
  `A RenderFlex overflowed by N pixels on the right` in Flutter and painted over the
  segment beside it on the web. A text is now one line, centred and ellipsised inside
  the room its segment gives it; a node that is not a text is cut at the share. A
  control with no width is untouched, because a row that scrolls has room for it.

- `MaterialSegmentedButton` takes `border:` — the line around the pill *and* the rules
  between its segments, which are one hairline the model draws as a box. It was a
  private `outline` constant, so an application that draws its segmented control with
  Material's quieter `outlineVariant`, as Flutter's own `SegmentedButton` does, had no
  way to say so. The default is the line it always drew, so nothing moves.

- A `MaterialSegmentedButton` with no `width:` lays out at the width of its labels in
  Flutter, where it used to throw. Every segment asked to fill `double.infinity`, which
  is a share of a width the caller never gave: in a bounded column it was clamped and
  looked right, and in a row — a horizontally scrolling one, which is where a control of
  a few labels belongs on a phone — Flutter refused the constraint before it drew
  anything. A segment now fills only a width the button was given, and hugs its label
  otherwise, which is what the browser was already doing.

- A card's shadow reads the same height on the web as in the app. The stylesheet wrote
  `MaterialElevation`'s blur in Flutter's unit, which a browser reads as half of it, so a web
  card carried a darker band under its edge than the card beside it in the application; the
  CSS renderer now writes the blur that paints the same spread.

- An ink well's ripple no longer grows a page's stylesheet as it is pressed. A drop used to be
  given a new width, height, corner radius and offset every frame, and on the web a number is a
  class: each press left 29 rules behind that the sheet keeps for the life of the page, and every
  frame of every press rewrote all of them into the document, so a button pressed all afternoon
  got slower with each press. A drop is now a circle of the spread, scaled out of nothing and
  placed on the pixel that was pressed, so the frames of a ripple are a fixed set of looks the
  sheet is asked for once: the first press in a place writes 30 rules, and a press after it
  writes none. The ripple paints the same pixels it did — a circle scaled is a circle.

- `MaterialElevation` is calibrated to what a Flutter card paints, as a ceiling rather than a
  match. The three layers — umbra, penumbra, ambient — keep the map's roles and stretch at 79%
  of its opacities, and each level's offsets, blurs and spreads follow `Canvas.drawShadow` at
  that height: a card reads `55, 39, 25, 14, 7` under its edge where Flutter reads `56, 40, 28,
  17, 9`, and `15, 6, 3` beside it where Flutter reads `21, 9, 3`, so no pixel of a shadow is
  heavier than the framework's — a shadow that overshoots by a few per cent reads as a surface
  raised higher than the one beside it. Level one's ambient layer stops at four pixels of blur
  rather than the map's five, because at five its last two rows came out a shade past the
  framework's. Two earlier readings are gone: the map copied as written (29% black under a
  card's edge against the framework's 22%, and gone within four pixels against its seven), and a
  pixel fit that matched the profile only by throwing the shadow up to fifteen pixels down the
  page, which read as a stain rather than a shadow. The example's Flutter suite now rasterises a
  card beside a real `Material` at the same height and compares the pixels, rather than
  comparing the list with a table. `MaterialCard.elevatedShadow` is `elevatedShadows` now, and
  every component passes the list a box takes.
- A text button is 40 pixels tall, like the other three shapes. It painted 36: Material's
  40 is a minimum size, and the text shape's 12 by 8 of room added up to less than that
  while the three filled shapes reached it with 20 by 10. All four now paint the same
  height, so a row of them lines up.
- Every button carries Material's minimum of 64 by 40, and its label is centred in the
  fill: a button pinned with `width:` used to draw its label against the left edge. The
  minimum is the caller's to move with the new `minWidth` and `height`, and `iconGap` and
  `border` are new too — the space between an icon and its label, and the line around an
  outlined button.
- The three filled shapes pad 24 across, which is Material's own, instead of 20. The text
  shape keeps 12, and neither number is fixed: `padding` replaces it.
- `MaterialButton.tonal`, `.outlined` and `.text` take `onLongPress`, `onHover` and
  `transition`. Only the filled constructor did, so a named shape silently dropped a
  long press and a hover the model and both renderers support.
- The spacing of every component is a parameter. `MaterialChip` takes `padding`, `height`,
  `tapTargetHeight`, `borderRadius`, `gap`, `labelStyle` and `onHover`;
  `MaterialListTile` takes `textGap`; `MaterialSegmentedButton` takes `height`,
  `borderRadius`, `padding`, `iconGap` and `labelStyle`; `MaterialTabBar` takes `height`,
  `indicatorHeight`, `tabPadding`, `labelGap` and `labelStyle`;
  `MaterialNavigationBar` takes `height`, `indicatorWidth`, `indicatorHeight`,
  `itemPadding` and `labelGap`; `MaterialTextField` takes `contentPadding` and
  `messageGap`; and `MaterialDialog` and `MaterialBottomSheet` take `color`, `padding`,
  `gap`, `borderRadius`, `actionGap` and `actionMargin`. Every default is the value the
  component already drew, so nothing moves that a caller does not ask to move.
- A bottom sheet's action row keeps the same 8 pixels above it that a dialog's does, so
  the two read as one component at two edges.
- The catalogue in the example shows a card at each of the first three heights, on the surface
  tone Material pairs with it, beside the outlined and the filled card.

- A **primary** tab bar's indicator sits under the tab that is chosen. It was laid from the
  centre of the bar and then moved one share per tab, so with three tabs the underline showed
  the *second* one while the first was chosen — and the third tab's underline ran off the end.
  It is laid from the start edge now, which is what makes `selected` alone place it.
- A **primary** bar hands its width down to its row of tabs, so a tab takes its share of the
  bar instead of hugging its label. The layer inside started rather than stretched, and a
  percentage inside a layer with no width resolves against its content: a 1080 pixel bar held
  210 pixels of tabs bunched at the left, and the indicator's share of the bar was really a
  share of the three labels.

- The navigation bar's pill answers a hover and a selection with two speeds, the way Material
  does: a hover fades a state layer over the pill in 50ms and never stretches it, while a
  selection keeps the 100ms fade and 500ms sideways stretch. A hovered destination that is
  also chosen now keeps its indicator colour and gains a tint, instead of replacing one with
  the other, and a press shows ink alone — Material's navigation destination has a
  transparent highlight, so the pill goes from the tick of ink to its new colour.

- `MaterialPalette.colorScheme`: read from the palette's own surface, so `light`, `dark` and
  `fromSeed(isDark:)` answer it without being told, and `MaterialPalette.theme` carries it.

- A **secondary** tab bar draws its indicator under the label rather than under a share of
  the bar. Its tabs are as wide as their labels, so the share-wide indicator that suits a
  primary bar landed under no tab at all: each tab now carries its own underline, pinned
  across the bottom of a stack its own label sizes, so the width is the text's without
  anyone measuring it. It fades between tabs instead of sliding, because the distance
  between two labels is the one thing a tree cannot state.

- The tab bar's indicator is one element, a share of the width, moved by a fraction of itself — so it
  **slides** to the chosen tab and a transition eases it, instead of appearing under one tab and not
  the other. It is a `transform`, which both targets already animate.
- A tab's tint covers the whole tab. It used to cover the label and stop above the indicator's three
  pixels: the tab laid the well and the indicator out as two children of a column, and a column hugs
  its content. Material tints the tab and draws the indicator over the tint.

- `MaterialTabBar` and `MaterialTabs`: Material 3 tabs — primary (evenly distributed) or
  secondary (as wide as their labels) — with the indicator under the chosen tab and, in
  `MaterialTabs`, the page of that tab drawn under it. A tab press swaps the page rather
  than sliding between pages: a controlled scroll position is not in the model yet.

- `MaterialProgressRing` is drawn the way Material 3 draws it: one arc **stroked** in a
  colour, with `round` caps, instead of a filled band whose ends were radial cuts. The outline
  is `BoxShape.arc` — a centreline inset by half the stroke, so the stroke meets the box's
  edge — and the paint is the box's `border`, whose `cap` states the rounded ends. The
  component is still three nodes and still adds no renderer code; what changed is that the
  model can now say what the ends of a stroke look like.

- `MaterialChip` and `MaterialSegmentedButton` state their choice with
  `BoxSemantics.pressed` rather than `selected`: both are toggle buttons, and a browser
  ignores `aria-selected` on a button, so the chosen chip and the chosen segment were
  announced as plain buttons on the web. `MaterialNavigationBar` keeps `current` alone,
  which is the state a navigation item has.

- `MaterialChip`'s target is 48 pixels around a pill that still paints 32. Material states
  one target for a touch screen and a 32 pixel chip is below it; the pill is centred in the
  room and the tints stay on the pill, so hovering the extra eight pixels takes the press
  and paints nothing. A chip takes 48 in a row now, which is what Flutter's padded tap
  target does too.
- `MaterialInkWell` can paint the surface it tints and take a target taller than its shape:
  `fill` and `border` put the surface on the well, under a layer of tints of its own, and
  `tapTargetHeight` adds room a finger can hit without painting it. A well with neither is
  the one box it has always been, so every other component is unchanged.
- `MaterialNavigationBar`'s indicator arrives the way Flutter draws it: stretched sideways
  out of the icon from 40% of its width over 500ms and faded over 100ms —
  `indicatorTransition`'s two parts — and it is the *only* thing that tints or inks. The
  pill is the colour, an ink well over it and the icon inside that well, all inside the
  destination's target: a hover tints the pill, a press leaves ink across it over the
  colour it settles to, and the icon is drawn whatever the state — fading the fill used to
  fade the picture with it. The destination around it is the control, and a click on the
  pill stops there. `BoxTransform` grew `scaleX`/`scaleY` for that sideways stretch, which one factor
  cannot say. The pill does not travel *along* the bar (that needs the width of its
  neighbours) and the icon still swaps rather than cross-fading. A destination announces
  `aria-current="page"` and no longer `aria-selected`: the latter is not valid on a
  button, and Flutter reads `current` as its selected state anyway.

- `MaterialNavigationBar`: Material 3's navigation bar — three to five destinations in
  one 80 pixel row on the new `surfaceContainer` role, an equal share each, the chosen
  destination's icon on a 64 by 32 `secondaryContainer` pill at radius 16 and its label
  in `onSurface` `labelMedium` (the rest in `onSurfaceVariant`). Every destination is a
  `MaterialInkWell`, so a press inks the whole share, and it announces itself as a
  button that is the current page. `MaterialNavigationDestination` carries the label,
  two optional glyphs and a screen-reader label; `activeIconColor` and
  `inactiveIconColor` are the roles to draw them in, because a picture keeps its own
  colour on both targets.
- `surfaceContainer` joins the colour roles: the tone Material paints a navigation bar
  on, one step above a resting card. `MaterialColorRole.surfaceContainer` and
  `MaterialPalette.surfaceContainer` are the role and its value, in both schemes.

- `MaterialPalette.fromSeed`: a whole palette from one brand colour — both schemes,
  the twenty roles and the state layers — by the algorithm Material's own themes run
  (`material_color_utilities`, the same one behind a Flutter `ColorScheme.fromSeed`,
  so a generated palette and the host theme agree). `MaterialSchemeVariant` chooses
  how the seed is spent (`tonalSpot`, the Material You default, through `fidelity`,
  `vibrant`, `neutral` to `monochrome`, `rainbow` and `fruitSalad`), and
  `contrastLevel` trades colour for legibility between `-1` and `1`.
- `unibox_material` now depends on `material_color_utilities` as well as
  `unibox_core`. Both are pure Dart: no Flutter, no `dart:ui`, no widget layer, and
  the renderers still know nothing of this package.

- `MaterialCheckMark` is Material's check without a font: the two strokes of the tick
  drawn as rotated bars, at the weight and the lengths of the glyph itself — a 2 pixel
  stroke, a 7.07 pixel short arm and a 14 pixel long one in its 24 pixel grid, with the
  elbow placed so the inked mark is centred. A chosen chip or segment can say what is on
  in an application that ships no icons, and a tick tuned by eye — a seventh of its box,
  nearly twice Material's weight — no longer reads as a pen stroke beside the type. A
  chosen segment of `MaterialSegmentedButton` draws it, and the example's chips use it
  instead of keeping a second tick of their own.

- `MaterialChip`'s close target centres the cross it holds, so the ring a hover or a
  focus draws around it sits on the cross rather than four pixels to its left: the well
  is a column, and without a cross alignment its node hugged the start of the target.

- `MaterialSegmentedButton` takes a `width`, and the segments share it equally. Without
  one each segment hugs its label: a `flex` in an unbounded row is a layout error in
  Flutter, so equal shares need a bound to divide.

## Unreleased

- A navigation bar destination lights its indicator pill when the pointer is anywhere in its
  share, which is where Material puts the hover and what a reader expects of a bar: before, only
  the pill itself answered, so hovering the label or the room around the icon did nothing. The
  look is one layer down from the pointer, and a box can style only itself, so a destination is
  now a `StatefulNode` that keeps the hover and its view paints the pill — the well over it stops
  tinting, so a hover is one layer rather than two over one shape. An unchosen destination shows
  Material's 8% state layer at full width; the chosen one keeps its indicator colour.

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

- `MaterialProgressRing` and `MaterialSpinner`: Material 3's circular progress
  indicator. The ring is two boxes painted in `BoxShape.ring` — the track, and the value
  as a sector of the same band — so no renderer knows what a progress indicator is; the
  value is clamped rather than refused. The spinner is that ring at three quarters of a
  turn, rotated one step per frame by a `MaterialSpinStore`, whose sixty steps repeat
  after one turn so a page settles instead of growing a class a frame.
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
