# Changelog

## Unreleased

- `boxAttributes` writes `aria-pressed` for `BoxSemantics.pressed`, so a toggle button states
  whether it is on: a chip and a segment were written as an ordinary button with no state, and
  the fill and the check were the only things saying which choice was on. Both `true` and
  `false` are written, because a toggle always states its state, and a link still writes none —
  a destination says `aria-current`, never a press.

- A scrolling box writes one rule for its children — `flex-shrink: 0`, from `scrollRules` — so a
  browser does not shrink them into the box and leave it with nothing to scroll. A pager's child
  rule keeps only `scroll-snap-align`, because the shrink belongs to every box that scrolls.

- A box that states `fold` puts its `@keyframes` block into the sheet once, named by a hash of its
  frames, so two boxes folding the same way cost one block. `Stylesheet.keyframes` registers it,
  `mark` and `rulesSince` carry it so a renderer that writes its rules in pieces still writes the
  block, and nothing prunes it: a page mints as many blocks as it has folds.

- A heading wears a class of its own: whether a text is a heading is part of the look the sheet
  remembers. `textDeclarations` writes the reset that cancels a user agent's heading margin,
  size and weight, and the look it was filed under did not say so — a plain text of the same
  typography, planned first, minted the class the `<h2>` then wore, and the markup said nothing
  about the element: the browser drew the example's sign-up title at `1.5em` with `0.83em`
  margins, a third taller than Flutter drew the same node, and the card with it.

- A box that states `capturesPointer: false` is planned with `pointer-events: none` however
  much it holds, so a decoration over a control no longer takes the hover, the cursor or the
  press in the corner it covers; `true` writes `auto` for a leaf that is a target of its own.
  The flag is part of the class, like the pointer the box was already given.

- An overlay's class carries the placement of its content rather than of its layer:
  `_planOverlay` asks `overlayContentDeclarations(node.alignment)`. The alignment became a
  margin on the content — the layer scrolls what does not fit, and an item a keyword centres
  loses the start edge no scroll can reach — so the rule that states it is the content's.

- A `url` on a box whose element is not an anchor writes no `href` and no `tabindex`. The
  pair is reported by `validateTree`, but the render a release build makes of a reported
  tree has to be harmless: it was a `<nav href="/rooms" tabindex="0">`, an anchor
  nothing followed in markup a keyboard could reach.

- `elementOf(box)` is the one place that decides which tag a box becomes: the element it
  states, or the anchor a `url` makes it. Every derived decision — the tag, the `href`, the
  class and the attributes — reads it, so they cannot disagree, and an anchor with no `href`
  is written as the placeholder it is.

- A `LinkNode` is planned as an `<a>`: the same class, the same declarations and the same
  children it would have had as a box, with the destination's `href` — and `target`/`rel` for
  `newTab` — written by the new `linkAttributes`. The look key includes the tag, so a link and
  the same box without a destination are two looks: the anchor's rule carries the two
  declarations that cancel the browser's blue and underline.

- `boxAttributes` writes no `role`, no `tabindex`, no `aria-checked` and no `aria-selected`
  for a box that navigates. The tag is the role, an anchor is already in the tab order, and
  those two states are a control's; a component that passed `BoxRole.button` therefore
  announces a link without changing anything. `aria-label` and `aria-current` stay.

- `Stylesheet.retain` forgets every rule of a class a page no longer wears, and the look it
  remembered for it. A class name is a hash of the declarations, so a look that comes back is
  registered again under the name it had. The sheet says whether it dropped anything, which is
  what tells a renderer to write the page again whole.
- `Stylesheet.mark` and `Stylesheet.rulesSince` answer what a page a renderer already wrote is
  missing: a renderer keeps the mark of the rules it wrote and appends only the ones a publish
  added, instead of handing the browser the whole sheet — every rule on the page — again. The
  rules are the same rules and the same bytes; `css` is built from them.
- A look is composed once per rendering, not once per node that wears it. A row of a list
  builds its declarations, sorts them, joins them into the canonical text and hashes that
  text — about three microseconds — and every row of a thousand-row list did it again only
  to be told the class it already had. `Stylesheet.classForLook` remembers the class a look
  is given, and the plan of a page of shared looks went from 14.6 ms to 2.8 ms at 12,001
  nodes. A page whose every look is new pays about a microsecond a node for the key and gets
  nothing back, which is why the benchmark keeps both shapes.

- A document's `:root` block starts from `rootDeclarations()`: the typography of the model and
  the switched-off tap highlight. A touch browser used to paint its blue flash over a control
  whose tree already draws the press, and the flash is inherited, so the root is where it goes.

- The stylesheet finds a look's class by looking it up: a rendering asks for a class once per node,
  and asking was a scan of every look the page had, which made a page whose styling varies with its
  data cost more than its size. `Stylesheet.revision` says whether the sheet has changed since a
  renderer last wrote it into a page.
- A document states the scheme of the theme it drew, as `color-scheme` in its `:root` block.

- A snapping box writes the rule that makes its children the stops: `.class > *`
  `{scroll-snap-align: start}`, alongside the state and threshold rules of the same class.

- A shaped box is planned as an `<svg>` layer over it, first among its children: one `<path>`
  whose outline is the shape, stretched to the box rather than fitted inside it, and the
  `clipPath` definition the box's rule points at when it clips its content. The layer is absolute
  with `z-index: -1` and takes no pointer, so a shaped box behaves like a painted one.

- The element plan moves out of the string renderer: which tag a node becomes, the attributes it
  carries and in what order, the class it wears and the elements inside it. A web renderer reads
  this package rather than deciding again what a `Box` looks like, which is what keeps a second
  one — a DOM renderer — from drawing the same tree its own way.

- `ElementPlan` holds values, not markup: escaping belongs to whoever writes the page, and a DOM
  renderer sets the same values as properties. The one exception is `raw`, which is markup the
  host wrote and trusts.

- `isRiskyUrl` and `safeUrlValue` live here because a `javascript:` href is a script that runs
  when a reader clicks, whichever target set the attribute.

- `Stylesheet` moves with the plan: the class a look wears is a hash of its declarations, so both
  renderers give one look one name.
