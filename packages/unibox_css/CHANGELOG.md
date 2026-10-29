# Changelog

## Unreleased

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
