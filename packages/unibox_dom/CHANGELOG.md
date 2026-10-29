# Changelog

## Unreleased

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
