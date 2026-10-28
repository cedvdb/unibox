# Changelog

## Unreleased

- `uniboxClientScript`, the one behaviour a document has: it paints the ink where a press
  landed and records the press, so the application that takes the page over can replay the
  intent instead of losing it. It is one optional file — `data-unibox-ink` without it is
  inert markup, which is how a page opts out of ink: it includes no script. The tree says
  *where* a press may paint, the host says *whether* it does.

- The drop's own rule is written into the stylesheet once, and only when a press is marked,
  so a page with nothing to press carries no animation it cannot use.

- Overlay dismissal is **not** part of the script, deliberately: nothing can open an overlay
  until a client renderer exists, so a dismissal path would be code nothing can reach. It
  arrives with `unibox_dom`.

- The conformance suite, which is what makes this a renderer rather than a second design:
  every case in `unibox_testing` is rendered to a document, the presentation is read back
  out of the class the root element wears, and compared with the table the Flutter suite is
  held to. Twenty-one box cases and fourteen text cases, describing the same output two
  ways.

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

- A `TextInputNode` is the `<input>` or `<textarea>` a browser already knows: the type that
  gives a phone the right keyboard (`email`, `tel`, `url`, `number`, `password`), the
  `autocomplete` hint a password manager reads, `aria-required`/`aria-invalid`/`
  `aria-description`, and a row count for a text area instead of the user agent's two. Its
  hint is a `::placeholder` rule of its own and part of the class key, or two fields that
  differ only in their hint would share a class.

- `toDocument()` writes a page: the encoding and the language first, then the title, the
  description, the canonical url and the Open Graph pair a link preview uses, then the
  stylesheet — in the head, so nothing flashes unstyled — then the scripts the host needs,
  deferred. Metadata a host needs and the model does not know goes through `meta`, and a
  script is a `DocumentScript` value rather than a string of markup, so a `src` cannot be
  assembled wrong and an inline body can take a `nonce`.

- An `OverlayNode` is **hidden** in a document, not drawn: it exists for a state a client
  renderer draws, and nothing in a static page can ask for it. `showOverlays: true` is for
  a page whose purpose *is* the dialog — a `/signup` url that publishes that state — and
  changes nothing about what the node means.

- A `StatefulNode` is drawn as the state its store starts in. The store is created only to
  be read: `onMount` is not called and no listener is added, which is what the store's own
  contract asks for, so a server render never starts the request or the timer an
  application would.

- `toHtml()` writes one `<style>` in front of the fragment: the typography of the model,
  the colours of the theme, then every class the tree wears, once each.

- Escaping first, because it is the only place a string renderer can be unsafe:
  `escapeText` for content, `escapeAttribute` for a double-quoted attribute, and `safeUrl`
  for an `href` or a `src`, which turns a `javascript:` or `vbscript:` URL into `#` — the
  scheme arrives from data, never from the tree. `isRiskyUrl` is public so a validator can
  report such a tree rather than only patching what it renders.
