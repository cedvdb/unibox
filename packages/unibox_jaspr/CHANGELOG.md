# Changelog

## Unreleased

- A box whose semantics state `pressed` writes `aria-pressed`, which is the state a
  browser honours on a `button`. A toggle button — a filter chip, a segment of a
  segmented button — used to write `aria-selected` instead, and a browser ignores that
  outside an option, a tab, a row or a grid cell: the chosen state of both controls was
  announced by nothing on the web while Flutter announced it.

- A stack paints its children in source order again, as Flutter's `Stack` does. A plain
  child's cell is now `position: relative`: it was static, and CSS paints an absolutely
  positioned sibling *above* every static one whatever the order, so a layer written
  first sat on top of everything written after it. The ink of a press painted over the
  label it belongs under, and `MaterialNavigationBar`'s indicator pill covered the hover
  tint and the ripple that should have painted across it.

- A box that paints and holds nothing takes no pointer, and a stack cell is a placement
  rather than a control: before, a decoration drawn over a control swallowed the press
  meant for it, so a button under a paint layer — or anywhere under a floating one — was
  dead on the web alone. A box with a listener keeps the pointer, and so does one with
  anything inside it, because its text is selectable and its links are links.

## 0.1.0

- A `LinkNode` with an `onTap` cancels the navigation: a plain click runs the handler and
  the browser does not follow the `href` as well, so a page that opens a dialog from a link
  no longer flashes a full page load on the way. A click with a modifier, a middle click
  and a `newTab` link keep the browser's behaviour.

- A `StackNode` writes `grid-template-rows: 100%`, so its cell is the stack rather than the
  height of what sits in it: a list inside a stack that states a height scrolls in the
  window instead of growing the document, and a control pinned to the bottom of the page
  stays there while the page scrolls. A stack with no height of its own still sizes to its
  content.

- `PositionedNode.alignment` renders as `inset: 0` with a flex alignment, the twin of
  the other target's `Positioned.fill` and `Align`.
- A box that states `flex` writes `min-width: 0` and `min-height: 0`: a flex item keeps
  its content as an automatic minimum, which is why a page of 1953 pixels of listings
  refused to shrink into a window while the same tree in Flutter filled it.
- A `JasprStatefulNode` draws the node its parent hands it on every redraw and keeps
  only the store, so a nested node whose look depends on the parent's state (a
  selected chip inside an ink well) no longer keeps its first look.

- A shaped box paints an `<svg>` layer with one `<path>` written from the same
  commands Flutter turns into a `Path`. The fill and the stroke are custom properties
  the box's rule sets, so a state rule can paint a shape and a transition can ease
  it; `overflow: hidden` clips through a `clip-path` in bounding box units.
- A `BoxBorderRadius` becomes one `border-radius` with four values, in CSS's order, so a
  box that rounds only two corners needs no wrapper and no clipped overlay.
- Every element a node draws carries `data-unibox-node="<name>"`, so an inspector
  reads the tree instead of a wall of hashes. It is written always, with no flag: a
  name adds no class, no rule and no element, and two node types with the same look
  still share one class while carrying different names. A wrapper the renderer
  invents carries no name, since no node drew it.
- In a browser the stylesheet is an element in the head rather than the tree's
  `<style>`, and a look a redrawn subtree registers is appended to it: before, only
  the tree the server wrote had a rule, so a dialog opened by a store arrived
  without its `position: fixed` layer.
- `Escape` dismisses an overlay in a browser: the key is heard on the document while
  the overlay is up, because nothing inside it holds focus yet.

- A `TextInputNode.placeholderStyle` becomes a `::placeholder` rule next to the field's
  own class, and its declarations are part of that class's key, so two fields that
  differ only in the colour of their hint do not share a class.

- A box with `onTapDown` writes a `pointerdown` listener that reports the press where
  it landed inside *the box*, the same local frame Flutter reports, and the device
  through `pointerType`. Like every other listener it stays inert until the client
  runtime exists, so a static export costs nothing.
- The press position is measured against the element that listens, not against the one
  the pointer hit. `offsetX`/`offsetY` are relative to the hit target, which is a label
  as soon as the press lands on text, so an ink drop placed in that frame started
  somewhere else — and the typed getters throw outright on the fractional coordinates a
  scaled browser reports, so a press on a label did nothing at all. The coordinates are
  read through `dart:js_interop` for that reason, in a file a browser build uses and the
  VM suites compile a stub for.
- A `StatefulNode` that sits in a tree is a component like the page it is drawn in: a
  browser subscribes to its store, calls `onMount` and redraws that node when it is
  notified, while a server still reads only the first state. Until now a node inside a
  page was drawn once and its store released, so any state inside a page — a ripple, a
  tab strip — was inert, and only a whole page could react.

The first release of the Jaspr renderer: one node tree becomes HTML and CSS, rendered
on the server and readable without a client bundle.

- The barrier of an `OverlayNode` carries the `click` that dismisses, and the layer the
  `Escape` key that does the same, so the page behaves like the Flutter overlay once the
  client runtime is on it.
- A `TextInputNode` with padding writes it on the `<input>`/`<textarea>` itself, so the padding is inside the control the pointer hits.
- `JasprGrid` writes a `GridNode` as one `repeat(auto-fill, minmax(…))`
  declaration with the clamped minimum and the derived cap, so a build sends no
  media query and a resize sends no request.
- `renderJaspr(node)` and `node.toComponent()` render any node, and `renderNode` the
  same without re-validating a subtree that was already checked.
- A box is one element with `display: flex` and its tokens as CSS: direction,
  distribution, alignment, gap, `flex`, size, bounds, padding, margin, background,
  radius, border, shadow, opacity and transform.
- An element says what a box is: `main`, `nav`, `header`, `footer`, `aside`,
  `section`, `article`, `form`, `figure`, `figcaption`, `ul`, `ol` and `li`, with the
  space the user agent adds cancelled and a `role` written only when the tag does not
  already imply it.
- Typography becomes the inherited CSS font properties, and `renderJaspr` emits the
  model's default typography in a `:root` rule so an undeclared text is typeset the
  same way the Flutter renderer typesets it.
- A colour role is written as `var(--unibox-color-<name>)` and the theme as one
  `:root` block — every role, whether or not a node names it — so a host stylesheet,
  a `prefers-color-scheme: dark` block or an embed can outrank the tree without
  touching it. `renderJaspr` takes the theme; a host composing the components itself
  installs `JasprThemeScope`.
- Every look is written once, as a class rule in a single `<style>` element, and the
  element carries the class instead of an inline style: the CSS grows with the number
  of distinct looks on a page rather than with the number of elements, and a host can
  override any of it with a stylesheet or a custom property. A state-styled element
  used to carry its own `<style>`, so identical cards repeated their rules once each.
- An `ImageNode` becomes an `<img>` with everything a browser can use: `srcset`,
  `sizes`, `loading` and `fetchpriority`, and a finite `width`/`height` written both
  as CSS and as the element's attributes, so the browser reserves the right box
  before the picture arrives.
- A `BoxTransition` becomes one `transition` entry per property, with
  `transition-delay` where a part asks for one, so a state change is interpolated by
  the browser and a static export animates with no JavaScript.
- State styles become scoped rules: `:hover` inside `@media (hover: hover)`,
  `:focus-visible`, `:active` and `[aria-disabled="true"]`, each carrying only the
  tokens of its state.
- Semantics become attributes: `role`, `aria-label`, `aria-checked`, `aria-expanded`,
  `aria-selected`, `aria-hidden`, `aria-live`, `aria-current`, `tabindex` and the
  form field's `aria-required`, `aria-invalid` and `aria-description`.
- A `TextInputNode` is an `<input>` or a `<textarea>` with the browser's chrome
  removed, so it looks like the field the tree describes.
- `JasprStateful` drives a `StatefulNode` in a browser and only reads its store on the
  server, and `JasprComponentNode` embeds any component.
