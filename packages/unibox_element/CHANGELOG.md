# Changelog

## Unreleased

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
