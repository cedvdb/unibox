# Changelog

## Unreleased

- A box that scrolls keeps its overscroll to itself: `overscroll-behavior: contain` is written
  beside `overflow`, so a panel that reaches its end does not hand the rest of the scroll to the
  page. Flutter's viewport keeps that overscroll already, and the browser chaining it is what made
  an inner list scroll the page out from under the reader. The pull the box keeps reveals the
  box's own `backgroundColor`, so a panel that states the surface of the bar at its edge reads as
  that bar gaining room rather than as a gap in the list.

- A box that scrolls keeps its children at the size the tree states: `scrollRules` writes
  `flex-shrink: 0` for the children of any `overflow: auto` box, not only for a pager's pages.
  A flex item shrinks to fit by default, so a hero, a bar and five rows inside a box shorter than
  all three were squashed until the box had nothing to scroll — Flutter scrolls them, and the page
  did not, which is how a sticky band came out as a bar that never moved. A row of chips that
  overflows now scrolls instead of narrowing its chips for the same reason.

- A box that states `fold` is written as an animation the reader drives: `animation-timeline:
  view()` so the subject is the box's own exit from whatever scrolls it, `animation-range: exit`
  (or `exit 0% exit <over>%` when the fold finishes early), and `animation-duration: auto`, which
  a browser without scroll-driven animations drops — the resting look it then paints is the one
  the tree shows before anything moves. `CssKeyframes` is the new at-rule value, named by a hash
  of its frames so one fold is one block, and `foldDeclarations` calls it from the box's rule.

- A box that states `pin` is written as `position: sticky`, at `top: 0` for `BoxPin.start`
  and `bottom: 0` for `BoxPin.end`, with `pinOffset` as that inset — and with `z-index: 1`,
  because a sticky box is painted in the flow order it was written in and the content that
  scrolls under it would otherwise paint over it. `cssPinEdge` names the property. The three
  declarations belong to the resting rule: a state rule never restates them, and a shaped box
  is `sticky` where it used to be `relative`.

- An overlay's layer bounds its content and scrolls what does not fit. `overlayDeclarations()`
  writes `overflow: auto` on the fixed layer, and the content is placed by a margin —
  `overlayContentDeclarations(alignment)`: `margin-inline: auto` and one block margin at
  `auto` — where the layer used to write `align-items` and `justify-content`. A flex item is
  allowed to be taller than the box it is centred in, so a dialog holding more than the
  window was as tall as its content on the page while Flutter drew it no taller than the
  window: one node, two heights, which the example's sign-up card showed. A margin rather
  than a keyword because a keyword puts the start edge of an oversize item outside the
  scrollport, where no scroll reaches, while an auto margin centres what fits and falls back
  to zero when it does not. `overlayBarrierDeclarations` scrims with `position: fixed` for
  the same reason — an absolutely positioned scrim belongs to the scroll and would be
  carried off the screen at the end of a long dialog — and `overlayDeclarations` no longer
  takes the alignment, which is the content's placement now.

- `boxDeclarations` takes `anchor:`, which adds the two declarations a browser gives every
  link — `color: inherit`, `text-decoration: none` — to the box's own rule. A box that
  navigates is painted by its look and not by the user agent, and the two declarations are
  in the anchor's class rather than in a global rule, so a look still costs one rule.

- A box that states `wrap: true` is a `flex-wrap: wrap` container whose lines are packed
  from the start (`align-content: flex-start`), which is what a Flutter `Wrap` does with
  its runs and not what a browser does by default.

- A shadow's blur is written in the unit a browser reads, so a shadow is as wide on the page
  as it is in the app. Flutter reads a `BoxShadow.blurRadius` of `r` as a gaussian of
  `0.57735 * r + 0.5`, where CSS reads a `blur-radius` of `b` as a gaussian of `b / 2`;
  written through untouched, the shadow under a card's edge read 60, 34, 19, 10, 4, 1 —
  darkness out of 255 — on the page where the app read 55, 39, 25, 14, 7, 3: darker at the
  edge and gone sooner, which reads as a card raised higher. The renderer now writes the
  inverse, `2 * (0.57735 * r + 0.5)`, and the same card reads 54, 40, 23, 12, 5, 2 against the
  app's 55, 39, 25, 14, 7, 3. A shadow with no blur stays a hard edge, because a hairline is
  drawn as one.

- `rootDeclarations()`: what a page starts from — the typography of the model, and
  `-webkit-tap-highlight-color: transparent`. A touch browser paints a highlight of its own
  over whatever it thinks was pressed, which is a blue flash over a control whose tree already
  answers a press with ink and a state layer; the property is inherited, so one declaration on
  the root is enough.

- `BoxStyle.aspectRatio` is written `aspect-ratio`, so a box keeps its shape at any
  width. It is written as the number a browser divides (`1.5`, not `3 / 2`), which is
  how the Flutter renderer states it too.

- `CrossAlign.baseline` is written `align-items: baseline`, so a row whose children
  are typeset at different sizes shares a line instead of an edge. It is the
  alphabetic baseline, the only one CSS can name.

- A box's shadows are written as one comma separated `box-shadow` list, in the order the model
  states them, so the three layers of an elevation are three declarations CSS paints at once. A
  shadow whose colour is a role keeps its custom property, which the old single-shadow path could
  only do when the whole shadow was a role.

- `Box.gridSpan` is written `grid-column: span n` on the card, so a banner can take
  several of the tracks the grid laid out. It is a declaration on the child and not
  on the grid, and a browser clamps it to the count the width gives.

- `decoration`, `decorationColor` and `decorationThickness` are written as
  `text-decoration`, `text-decoration-color` and `text-decoration-thickness`, in that
  order: the shorthand resets the two longhands, so they have to come after it.

- `FontWeight.light` is written `font-weight: 300`, so a light label is no longer
  written as a normal one.
- A look's declarations are sorted and joined once, and kept: a class name and the rule it becomes
  read the same text, and a page with thousands of nodes read it thousands of times.

- A pager as `scroll-snap-type` on the box and `scroll-snap-align: start` on the children
  it lays out, which is the one place a parent can describe its own children.

- A new package, and the one place the web's CSS is written down. A token becomes a
  declaration here rather than in a renderer, so `unibox_html` and any renderer built
  on a web framework produce the same text for the same tree — which is what keeps a
  class name stable, since a class name is a hash of its declarations. It answers a
  colour (`#112233`, `rgba(17, 34, 51, 0.502)`, or `var(--unibox-color-primary)` for a
  role), a dimension (`8px`, `100%` for `double.infinity`), a padding or a margin in
  CSS's four-value order, and an image fit.

- A text input draws no frame of its own: `font: inherit` and `color: inherit` make it
  adopt the typography and the colour of the box around it, and the border, padding,
  background and focus ring are stripped, because the box around a field draws the frame
  on both targets. The cost is stated in the code: a focused field shows its caret and
  nothing else, on both targets, which is worth more than a browser frame on one.

- A state is a rule with a selector: `:hover` under `@media (hover: hover)` so a touch
  screen cannot get stuck in a hovered look, `:focus-visible` so a pointer press paints no
  ring, `:active`, and `[aria-disabled="true"]` so the visual state and the announced one
  cannot disagree. Each declares only what its state states.

- A theme is written as custom properties in one `:root` block, and `CssRule` carries a
  selector, its declarations and an optional media condition, so a string renderer and a
  DOM renderer write the same rules two ways from one value.

- A box can wear an outline instead of its rectangle: `cssShapePath`, `cssShapeClipPath` and
  `cssShapeClipId` write a `BoxShape` as SVG path data, in the units it was authored in and, for
  a clip, in bounding box units so one definition fits whatever element it is applied to. A
  shaped box's declarations send its fill and stroke to the layer as custom properties — which
  a state rule can paint — and replace its background, border, radius and shadow.

- A stack is a relative grid whose single row is the height of the stack rather than of
  its content, so a list inside it scrolls instead of growing the document; each child
  gets a cell it cannot escape; a child placed by offsets or by an alignment takes no
  pointer of its own, because a wrapper is a placement and not a control. Four equal
  offsets collapse into one `inset`, and an aligned child fills the stack with
  `inset: 0`.

- A grid counts its tracks from the width it is given. A text writes only the typography
  it states, clamps with the prefixed box layout when it is given a line count, and
  cancels what a user agent brings to a heading. An image is a block with an `object-fit`
  always stated, because an unset one lets a browser stretch the picture over its box.

- A box, as the web draws it: `boxDeclarations` states the flex container the
  model resolves to, the paint it names, the two floors a flex item needs, and the
  typography it installs for its subtree. `declaredOnly` emits only what the style
  states, which is what a state rule needs — a `:hover` rule that restated the layout
  would turn a row into a column. A transition belongs to the resting rule alone.

- `CssDeclarations` holds a list of declarations rather than a map: CSS allows a
  property to be written twice as a fallback, and `text` is the canonical spelling —
  sorted by property, insertion order within one property — that a class name is
  hashed from.
