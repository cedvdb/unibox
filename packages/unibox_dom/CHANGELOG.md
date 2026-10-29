# Changelog

## Unreleased

- `DomView.adopt(tree, root)`: draws a tree into the markup a server already wrote, keeping
  the elements rather than replacing them, so a reader who has scrolled or focused a field
  keeps their place and the page a crawler reads stays the page a reader uses.

- `DomView.mount(tree, host)` for a page with nothing to adopt, and `render(tree)` to swap
  the tree of a view that is already drawing — which is what a palette change is.

- Patches at `StatefulNode` boundaries: a publish re-plans that node's subtree and patches
  it in place, so a field keeps its focus and a list keeps its elements when it reorders.

- `dispose()` unsubscribes every store and removes every listener it added.
