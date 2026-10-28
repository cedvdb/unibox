# Changelog

## Unreleased

- `HtmlEmbed`, the door for markup the model does not describe: a web component, a
  `<video>`, a chart from another package. It is written verbatim rather than escaped,
  which is the point of the node and the whole risk of it — a `String` this target trusts,
  never one assembled from data a reader supplied. An embed carrying a payload for another
  target is reported, not skipped.

- `bootScript(src, whenIdle: …)`: the handover, as one script. It loads the application on
  intent — a pointer, a touch, a key, a focus — and, for a page that exists for its
  application, when the browser is idle after the load. The url it is given is escaped both
  as a JavaScript string and for a raw text element, because a parameter that becomes markup
  is an injection.

- `toDocument(prefetch: …)`: the bundle is fetched at a low priority while the reader reads,
  so a boot that waits for intent is never a boot on a cold cache. Deferring the execution
  is the point; deferring the download as well is how a page gets a good score and a
  two-second dead click.

- The client code is a folder: `client/press.dart` holds the record and the script that
  keeps it, and `client/all.dart` is the name a host includes. The scroll recorder joins
  them when `unibox_jaspr` goes, so every line of client code ends up in one place.

- **Ink is withdrawn from the renderer.** A script that paints a drop, its marker and its
  declarations were written and then removed: the marker came from "this box listens", so
  a plain `Box(onTap: …)` would have shown ink on the web and nothing at all in Flutter —
  a look one target draws and the other cannot, which is the one thing this package exists
  to prevent. Ink belongs to the ink well, whose node paints it in Flutter because the tree
  says so; the web gets it when `unibox_material` can declare it, and that needs a token
  both renderers honour rather than a rule in a renderer.

- `uniboxClientScript`: a document has no state to change, so a press can only be
  remembered. It records the press — the key of the element it landed on, and the position
  inside that element, in the same pixels a Flutter renderer reports — and hands the record
  to the application that takes the page over, once. One optional file, guarded so that
  including it twice does nothing the second time.

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
