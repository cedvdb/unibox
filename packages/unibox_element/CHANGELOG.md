# Changelog

## Unreleased

- The stylesheet finds a look's class by looking it up: a rendering asks for a class once per node,
  and asking was a scan of every look the page had, which made a page whose styling varies with its
  data cost more than its size. `Stylesheet.revision` says whether the sheet has changed since a
  renderer last wrote it into a page.

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
