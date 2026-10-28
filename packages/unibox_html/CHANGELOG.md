# Changelog

## Unreleased

- A new package: the web renderer, pure Dart with no dependencies, so a document can be
  produced in a server, in a build step, in a CLI, or compiled to JavaScript for a host
  whose backend is not Dart.

- The element plan, as a value: `ElementPlan` says which tag a node becomes, which
  attributes it carries, in what order, and which class it wears, without writing any
  markup. A string renderer writes it to HTML; a DOM renderer would build nodes from the
  same value and adopt the page rather than repaint it.

- A first set of nodes, one at a time: a `Box` (its element from `semantics.element`, its
  role only when the element does not already imply it, `aria-disabled` and no `tabindex`
  when it is disabled, its state rules in the sheet), a `TextNode` (a `<span>`, or `<h1>`
  to `<h6>` at the level it states, with the user agent's heading look cancelled), an
  `ImageNode` (a block that reserves its box with `width`/`height` and states only the
  loading hints it asks for) and a `LinkNode` (a real `<a href>`, `rel="noopener
  noreferrer"` in a new tab, and no browser underline). A node outside that set throws
  rather than shipping a page with a piece missing.

- A `GridNode` is a grid that counts its tracks from the width it is given, and a
  `StackNode` puts every child in a cell of its own: the cell is the renderer's, not a
  node's, so it carries no `data-unibox-node` — an element without the attribute is not
  part of the description. A child placed by offsets is placed, one placed by an alignment
  fills its cell, and a `PositionedNode` with no stack to be placed in throws, as
  `validateTree` reports it.

- `toHtml()` writes one `<style>` in front of the fragment: the typography of the model,
  the colours of the theme, then every class the tree wears, once each.

- Escaping first, because it is the only place a string renderer can be unsafe:
  `escapeText` for content, `escapeAttribute` for a double-quoted attribute, and `safeUrl`
  for an `href` or a `src`, which turns a `javascript:` or `vbscript:` URL into `#` — the
  scheme arrives from data, never from the tree. `isRiskyUrl` is public so a validator can
  report such a tree rather than only patching what it renders.
