# Changelog

## Unreleased

- A link is a box with a `url`, so the click rule binds there and nowhere else: a plain
  click is cancelled and answered, and a modifier, a middle click and a `newTab` stay the
  browser's.

- A box with a `url` and an `onTap` answers a press the way a link does: a plain click is
  cancelled and the callback runs, while a modifier, a middle click and a `newTab` stay the
  browser's. A box with a url and no callback binds nothing, so the browser follows the
  `href`. The `Enter` key is not bound for an anchor — a browser turns `Enter` on a link into
  a click the listener above already answers, and `Space` does nothing on a link.

- The view holds its stylesheet to the looks the page wears. A view lives as long as the page, so
  every look a store minted — a list whose styling follows its data, a ripple pressed in a new
  place — left a rule behind for good. Every 64 rules the view walks the plans it holds and
  forgets the rest, and writes the sheet again whole because a rule cannot be lifted out of a
  page one at a time. A look that comes back gets the name it had.
- The page's stylesheet is written once and appended to after that. A publish that adds a rule
  used to hand the browser the whole sheet again — every rule on the page, thrown away and
  re-parsed; it inserts the one rule now, which measured 38 ms → 0 on a sheet of 300 KB. A publish
  that adds no rule still writes nothing at all, and a sheet the page no longer holds is written
  from the top.
- A page the client adopted gets a sheet of its own the first time a store publishes a rule the
  document was not served with. That rule used to have nowhere to go: adoption leaves the view
  without a sheet, and an ink drop on an adopted page was an element with a class nothing
  described.
- The page's stylesheet is written only when a publish has added a rule. A store that publishes
  every frame — an ink ripple, a spinner — used to re-serialise and hand the browser a sheet that
  could not have changed, which made the browser re-parse every rule on the page sixty times a
  second.
- A keyed list is matched through an index rather than by asking every element for its key, and an
  adopted page is walked once rather than once per element: both were quadratic, and both happen
  where the page is biggest.
- A publish no longer dies on a shaped box: the class is written as an attribute, because an
  `<svg>`'s `className` is an object rather than a string, which threw and left the pass half
  applied.

- The view writes its stylesheet *beside* the one a document was served with instead of over it.
  Adoption keeps elements it never planned — a shape's `<svg>` layer and its `<path>` are invented
  by the plan, not by the tree — so writing over the served rules deleted the `fill` and `stroke`
  they were painted by, and an SVG with no `fill` is black: the example's progress ring and its
  badges came out as black discs.

- A store stays with the element that drew it. A repaint of a `StatefulNode` plans its view from
  the node's own address in the tree, so the components inside it keep their stores — and their
  elements — while their parent publishes: a ripple is drawn under the control that was pressed
  rather than under a different one, and a nested field keeps what it holds while the frame
  around it changes.

- `Box.onScroll` is bound to the element's own `scroll` event and reports `scrollTop` or
  `scrollLeft`, chosen by the box's direction. A document rendered without a runtime has no
  scroll report — the callback is behaviour, and a static page has none.

- `DomView.adopt(tree, root)`: draws a tree into the markup a server already wrote, keeping
  the elements rather than replacing them, so a reader who has scrolled or focused a field
  keeps their place and the page a crawler reads stays the page a reader uses.

- `DomView.mount(tree, host)` for a page with nothing to adopt, and `render(tree)` to swap
  the tree of a view that is already drawing — which is what a palette change is.

- Patches at `StatefulNode` boundaries: a publish re-plans that node's subtree and patches
  it in place, so a field keeps its focus and a list keeps its elements when it reorders.

- `dispose()` unsubscribes every store and removes every listener it added.
