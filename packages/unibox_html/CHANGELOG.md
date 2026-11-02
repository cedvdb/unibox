# Changelog

## Unreleased

- A pin may now sit at any depth below the box that scrolls it, and a document draws it with no
  change: `position: sticky` already measures the edge against the nearest scrollport and bounds the
  travel to the element's containing block. The README records the one thing a host must avoid — an
  ancestor between the pin and the scrollport that creates a stacking context (`opacity` below 1, a
  `transform`, a `filter`) scopes the pin's `z-index` to itself, so a nested panel can lose to the
  page's own bars.

- A stack paints its layers in the order the tree lists them, which on the web it did not always
  do. A child a `PositionedNode` places is absolutely positioned, and a browser paints those after
  the boxes that sit in the flow, so a positioned child covered the plain siblings written *after*
  it — the reverse of what Flutter's `Stack` draws. Every cell of a stack is now positioned and
  takes no stacking level of its own, so one list decides the paint order on both targets.

- **A takeover has three states instead of one, and it does not show a half-drawn page.** The boot
  writes `data-unibox-state` on the document element — `document`, `booting`, `ready`, `app`,
  `failed` — keeps the engine's host invisible and unreachable while it loads, and swaps the two
  views at a reveal instead of at the moment the script is appended. The engine's element is found
  by what appeared in the body, not by a name that moves with a Flutter version.
- **The reveal is an accessibility event.** Focus moves into the application, a `role="status"`
  sentence (`Takeover.readyLabel`) is announced in the page's language, and only then does the
  document become `inert` and leave the page — never while a reader is focused on it, on any
  policy. The way-in control stays put while the engine loads, `aria-disabled` rather than
  `disabled`, so a reader who pressed it keeps their focus.
- **`RevealPolicy` decides when the application is worth showing.** `onFrame` (the default) shows
  the engine's first frame; `onReady` waits for the application to say it has drawn the state it
  was given — `unibox_flutter` says so without being asked — and `readyTimeout` bounds either
  answer, so a page with no frame goes back to being a document rather than staying blank.
- **The address may narrow, and a debug build may inspect.** `?unibox=document` keeps the page a
  document and needs no build flag, because it can only remove an application. `?unibox=debug`,
  `?unibox=profile` and `?unibox=compare` need `Takeover(debug: true)`: a visitor can never turn on
  a report, a timeline or an overlay the host did not publish. `compare` keeps the document and
  draws the application at 50% over it, which is the cheapest way to see whether the two
  renderings agree.
- **The recorders stop when the application owns the page**, so a press or a scroll after the
  reveal is not replayed to it as intent the reader never had.

- **Breaking: a rendering takes a scope, not a theme.** `toHtml`, `renderFragment`, `toDocument`,
  `Document` and `documentCss` take `scope:`, and `Document`'s own `lang`, `writingDirection` and
  `theme` fields are the scope's: one value says how the page is drawn, written and read, and
  `toDocument(scope: UniboxScope(lang: 'de'))` is the spelling a build writes per language.

- The package holds the whole web target: the element plan and the CSS a token becomes are
  `lib/src/element/` and `lib/src/css/` here, rather than the `unibox_element` and `unibox_css`
  packages. Nothing was withdrawn — `ElementPlan`, `planNode`, `Stylesheet`, `CssDeclarations`,
  `documentCss` and the rest are exported by `package:unibox_html/unibox_html.dart`, and
  `unibox_dom` builds the same plan from it — but what was three versions to keep in step is one.
  The split bought nothing: the third renderer it was for was deleted, and the two layers are
  still decisions of their own, with their own files and their own tests. What those two
  packages had recorded for the next release is at the end of this section, under the layer it
  describes.

- `BootPolicy.onIntent` is the policy for a page that is *shown* rather than arrived at: a
  comparison's frame, a preview inside someone else's page. It waits for a signal the reader gives
  by *looking* — a pointer that moves, a scroll, a touch — and never boots on the browser's idle,
  and it reads those signals from the top document when that is the same origin, because a pointer
  in the middle of the host page never reaches a frame's own window. A framed takeover that booted
  on idle spent two megabytes of engine and 1.9 seconds of blocking on a phone, on behalf of a
  reader who may never have scrolled to it. A key, a focus move and a press are deliberately not
  signals: the document is the accessible rendering and the application is a canvas, so booting on
  a keystroke would take the page from a keyboard reader mid-read. Those readers are not left
  without the application either: a frame with this policy carries a real `<button>` first in its
  body — `Takeover.openLabel` names it — that boots the application when they choose it. It also
  waits while the frame holds the focus, because the boot replaces every element in the document
  and would take away the element a reader is on.
- A share of the viewport reaches the page as `max(0px, calc(100dvh - 216px))` in the box's
  class rule, so a panel that fills what the window leaves after a header needs no host CSS
  and no statement of the header's height in a media query.

- `toDocument(writingDirection: …)` and `Document(writingDirection: …)` write `dir` on the root
  element, beside `lang` and never derived from it: everything on the page that states no
  direction inherits it, and a page that states none writes no attribute at all.

- `Document.at(url)`: the same page with an address, which is the one thing a build knows and a
  page does not. The address becomes the page's `canonical` url and every other field is kept, so
  a build can take the pages it was handed and give each one the address it is served at — and a
  sitemap built from the same list cannot list an address a page denies.

- `Document`: a page as a value — the tree, `lang`, `head` and the host's choices for how it is
  written — with `write()` for the HTML. `toDocument` stays the one-page call; a build that
  writes several holds a list of `Document` beside the paths they are served at and writes them
  the same way, and the same list is what a sitemap or a router can read instead of restating
  the addresses. The example now builds from that list: the three pages it writes are stated
  once, and the takeover page is one entry among them rather than a third hand-written call.

- `DocumentLink`: a `<link>` in the head as a value — `rel`, `href`, `as`, `type` and
  `crossorigin` — with `DocumentLink.preload` and `DocumentLink.prefetch` for the two a host
  usually wants. It replaces `DocumentHead.prefetch`, which could only say one thing
  (`rel="prefetch" as="script"`), and it is what a font preload should be written with: a
  preload with no `crossorigin` is fetched twice, once for the preload and once for the
  `@font-face` that names it, and no string of markup says so. `Takeover.prefetch` is now the
  `DocumentLink` it always wrote out by hand. The example's own `fontPreloadLinks` returns
  links instead of markup, so the site's two documents state their fonts through the same value
  a host would.

- `DocumentHead`: the page's own metadata as one value, so `toDocument` takes `head:` where it
  took seven arguments that had to agree with each other — `title`, `description`, `canonical`,
  `alternates`, `meta`, `prefetch` and the list of raw markup. `DocumentHead.raw([…])` is a head
  that is only markup, which is the old list in its new spelling. Two things are new with it:
  `image` writes `og:image`, so the tag a link preview is drawn around is no longer hand-written
  markup, and the image url goes through `safeUrl` like the canonical and the alternates do.
  `lang` stays beside the value, because a language is an attribute of the root element and not a
  head element — which is what makes the name truthful. The order is still the renderer's, and
  two of its positions are now pinned: a prefetch is written before the stylesheet, so the fetch
  starts with the document, and the host's own markup after it, so a host rule of equal
  specificity can restate a colour role.

- A page carries the `@keyframes` a folded box runs, in the same `<style>` element as the rest, so
  a document that no script touches folds as the reader scrolls it.

- A `LinkNode` is written as an `<a href>` with the box's own class, children and declarations,
  instead of a `<div role="button">`: a page a crawler can follow, a reader without the
  runtime can use, and anyone can copy or open in a new tab. Nothing else about the element
  changes, and the document still carries no listener — the press belongs to the host's
  runtime. A plain box that names `BoxElement.a` and no destination writes HTML's placeholder
  anchor, which nothing follows and nothing can tab to.

- A card's shadow sits at the same height on the page as in the app: the stylesheet writes a
  shadow's blur in the unit a browser reads, so the level one shadow under a card has the width
  and the weight of the one in the application instead of a darker, tighter bar on the web.
  The conversion is `unibox_css`'s, so every shadow in a tree gains it.

- A document switches off the tap highlight a touch browser paints over a control it thinks was
  pressed: the `:root` block carries `-webkit-tap-highlight-color: transparent`, so a press is the
  ink and the state layer the tree states, and not a blue flash on top of them.

- `node.toHtml(...)`: the shorthand the Flutter target already had, so one tree is rendered by two
  calls of the same shape — `tree.toWidget()` for the widgets and `tree.toHtml()` for the fragment a
  page is made of. `toDocument(node, …)` stays a function, because a page carries facts no tree
  does: its title, its canonical url, the languages it is translated into.

- A tree is written into one buffer instead of one per element, so its text is written once rather
  than copied once per ancestor: a deeply nested page no longer costs its own depth squared.
- `toDocument(alternates: …)`: the `hreflang` links that pair a page with its translations.
  A localised site is the same builder called with another value, and a translated copy of a
  page is not a competitor — it is the same page in another language — but a search engine can
  only know that if every page of the set names the whole set, itself included. `lang` states
  the language the page is written in, `alternates` names the rest, and a url still goes
  through `safeUrl`: a locale is assembled from an address, never typed by hand.

- `HtmlEmbed`, the door for markup the model does not describe: a web component, a
  `<video>`, a chart from another package. It is written verbatim rather than escaped,
  which is the point of the node and the whole risk of it — a `String` this target trusts,
  never one assembled from data a reader supplied. An embed carrying a payload for another
  target is reported, not skipped.

- `bootScript(src, policy: …)`: the handover, as one script and one rule — the application
  starts as early as it can and never earlier than the first paint. `BootPolicy` names the two
  kinds of page rather than an event: `immediately` for a page that *is* the application, and
  `onPointer` — the default — for its front door, where a pointer moving is intent and an idle
  browser is the fallback. An intent that arrives before the load is remembered and honoured
  at the load.

- `Takeover(boot: …)` and `toDocument(takeover: …)`: a page that becomes an application in one
  argument. It prefetches the loader, carries the two recorders before the boot so the
  application can ask what the reader did, and starts the boot on a signal. Written by hand it
  was three arguments in two spellings, and a host that swapped `prefetch` and `scripts` shipped
  a page that booted on a cold cache. The policy is the one choice left, and `record: false`
  drops the recorders for a page that only has to boot.

- `toDocument(head: …)`: markup the host owns and the model does not describe — the
  `@font-face` rules of the asset it ships, a dark-mode block, a structured-data script. It is
  written verbatim and placed before the tree, so a font face arrives before the text that
  uses it, and it is the host's own text rather than anything assembled from data.

- `toDocument(prefetch: …)`: the bundle is fetched at a low priority while the reader reads,
  so a boot that waits for intent is never a boot on a cold cache. Deferring the execution
  is the point; deferring the download as well is how a page gets a good score and a
  two-second dead click.

- The client code is a folder: `client/press.dart` holds the record and the script that
  keeps it, and `client/all.dart` is the name a host includes. The scroll recorder joins
  the recorder, so every line of client code lives in one place.

- ~~An ink script, its marker and its declarations~~ were withdrawn: ink is the ink well's,
  and a renderer painting one for every box that listens draws a look Flutter cannot.
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

- A `Box` that wears a shape is drawn: the layer, the outline and the clip come from
  `unibox_element`, so a shaped box is the same silhouette on the web as in Flutter. The
  appearance table cannot read an outline back — it compares tokens a value can describe — so the
  markup is pinned by a renderer test instead.

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

### The CSS layer, from `unibox_css`


- A pinned bar keeps no stated height on the web either: it is `position: sticky` in the flow,
  so its room is its own. The suites now pin a bar that states none.

- A share of the viewport is written as a `dvh`/`dvw` length with its inset taken off in a
  `calc`, floored with `max(0px, …)`: `BoxFraction.viewport(1, minus: 216)` is
  `max(0px, calc(100dvh - 216px))`. A share of the parent is still a percentage, so a tree that
  already states one draws as it did. `cssFraction` is now `cssFractionOf(fraction, axis)`.

- A pager is written from the node rather than from a token: `boxDeclarations(style, pager: true)`
  emits `scroll-snap-type` for the box's own axis, and `pagerRules(className, pager: true)` makes
  its children the stops. `cssScrollSnap` is now `cssScrollSnapType(axis)` and `snapRules` is
  `pagerRules`, because a box no longer states that it settles.

- A grid that states its columns writes one explicit `minmax(0, Nfr)` track per child — the
  `1fr 2fr 1fr` of the specification, with a floor of zero so a column shrinks into a parent too
  narrow for it — and both forms now state `align-items` from the model's own default rather than
  leaving it to the browser's `normal`, which would stretch every column.
- `writingDirection` is written as the `direction` declaration, which CSS inherits: a box states
  it once and the row it holds reverses, along with every logical edge inside it. A box that
  states none writes nothing, so the boxes inside a page written right to left do not overrule it.

- A box that scrolls keeps its overscroll to itself: `overscroll-behavior: contain` is written
  beside `overflow`, so a panel that reaches its end does not hand the rest of the scroll to the
  page. Flutter's viewport keeps that overscroll already, and the browser chaining it is what made
  an inner list scroll the page out from under the reader. The pull the box keeps reveals the
  box's own `backgroundColor`, so a panel that states the surface of the bar at its edge reads as
  that bar gaining room rather than as a gap in the list.

- A box that scrolls keeps its children at the size the tree states: `scrollRules` writes
  `flex-shrink: 0` for the children of any `overflow: auto` box, not only for a pager's pages.
  A flex item shrinks to fit by default, so a hero, a bar and five rows inside a box shorter than
  all three were squashed until the box had nothing to scroll — Flutter scrolls them, and the page
  did not, which is how a sticky bar came out as a row that never moved. A row of chips that
  overflows now scrolls instead of narrowing its chips for the same reason.

- A box that states `fold` is written as an animation the reader drives: `animation-timeline:
  view()` so the subject is the box's own exit from whatever scrolls it, `animation-range: exit`
  (or `exit 0% exit <over>%` when the fold finishes early), and `animation-duration: auto`, which
  a browser without scroll-driven animations drops — the resting look it then paints is the one
  the tree shows before anything moves. `CssKeyframes` is the new at-rule value, named by a hash
  of its frames so one fold is one block, and `foldDeclarations` calls it from the box's rule.

- A box that states `pin` is written as `position: sticky`, at `top: 0` for `BoxPin.start`
  and `bottom: 0` for `BoxPin.end`, with `pinOffset` as that inset — and with `z-index: 1`,
  because a sticky box is painted in the flow order it was written in and the content that
  scrolls under it would otherwise paint over it. `cssPinEdge` names the property. The three
  declarations belong to the resting rule: a state rule never restates them, and a shaped box
  is `sticky` where it used to be `relative`.

- An overlay's layer bounds its content and scrolls what does not fit. `overlayDeclarations()`
  writes `overflow: auto` on the fixed layer, and the content is placed by a margin —
  `overlayContentDeclarations(alignment)`: `margin-inline: auto` and one block margin at
  `auto` — where the layer used to write `align-items` and `justify-content`. A flex item is
  allowed to be taller than the box it is centred in, so a dialog holding more than the
  window was as tall as its content on the page while Flutter drew it no taller than the
  window: one node, two heights, which the example's sign-up card showed. A margin rather
  than a keyword because a keyword puts the start edge of an oversize item outside the
  scrollport, where no scroll reaches, while an auto margin centres what fits and falls back
  to zero when it does not. `overlayBarrierDeclarations` scrims with `position: fixed` for
  the same reason — an absolutely positioned scrim belongs to the scroll and would be
  carried off the screen at the end of a long dialog — and `overlayDeclarations` no longer
  takes the alignment, which is the content's placement now.

- `boxDeclarations` takes `anchor:`, which adds the two declarations a browser gives every
  link — `color: inherit`, `text-decoration: none` — to the box's own rule. A box that
  navigates is painted by its look and not by the user agent, and the two declarations are
  in the anchor's class rather than in a global rule, so a look still costs one rule.

- A box that states `wrap: true` is a `flex-wrap: wrap` container whose lines are packed
  from the start (`align-content: flex-start`), which is what a Flutter `Wrap` does with
  its runs and not what a browser does by default.

- A shadow's blur is written in the unit a browser reads, so a shadow is as wide on the page
  as it is in the app. Flutter reads a `BoxShadow.blurRadius` of `r` as a gaussian of
  `0.57735 * r + 0.5`, where CSS reads a `blur-radius` of `b` as a gaussian of `b / 2`;
  written through untouched, the shadow under a card's edge read 60, 34, 19, 10, 4, 1 —
  darkness out of 255 — on the page where the app read 55, 39, 25, 14, 7, 3: darker at the
  edge and gone sooner, which reads as a card raised higher. The renderer now writes the
  inverse, `2 * (0.57735 * r + 0.5)`, and the same card reads 54, 40, 23, 12, 5, 2 against the
  app's 55, 39, 25, 14, 7, 3. A shadow with no blur stays a hard edge, because a hairline is
  drawn as one.

- `rootDeclarations()`: what a page starts from — the typography of the model, and
  `-webkit-tap-highlight-color: transparent`. A touch browser paints a highlight of its own
  over whatever it thinks was pressed, which is a blue flash over a control whose tree already
  answers a press with ink and a state layer; the property is inherited, so one declaration on
  the root is enough.

- `BoxStyle.aspectRatio` is written `aspect-ratio`, so a box keeps its shape at any
  width. It is written as the number a browser divides (`1.5`, not `3 / 2`), which is
  how the Flutter renderer states it too.

- `CrossAlign.baseline` is written `align-items: baseline`, so a row whose children
  are typeset at different sizes shares a line instead of an edge. It is the
  alphabetic baseline, the only one CSS can name.

- A box's shadows are written as one comma separated `box-shadow` list, in the order the model
  states them, so the three layers of an elevation are three declarations CSS paints at once. A
  shadow whose colour is a role keeps its custom property, which the old single-shadow path could
  only do when the whole shadow was a role.

- `Box.gridSpan` is written `grid-column: span n` on the card, so a banner can take
  several of the tracks the grid laid out. It is a declaration on the child and not
  on the grid, and a browser clamps it to the count the width gives.

- `decoration`, `decorationColor` and `decorationThickness` are written as
  `text-decoration`, `text-decoration-color` and `text-decoration-thickness`, in that
  order: the shorthand resets the two longhands, so they have to come after it.

- `FontWeight.light` is written `font-weight: 300`, so a light label is no longer
  written as a normal one.
- A look's declarations are sorted and joined once, and kept: a class name and the rule it becomes
  read the same text, and a page with thousands of nodes read it thousands of times.

- A pager as `scroll-snap-type` on the box and `scroll-snap-align: start` on the children
  it lays out, which is the one place a parent can describe its own children.

- A new package, and the one place the web's CSS is written down. A token becomes a
  declaration here rather than in a renderer, so `unibox_html` and any renderer built
  on a web framework produce the same text for the same tree — which is what keeps a
  class name stable, since a class name is a hash of its declarations. It answers a
  colour (`#112233`, `rgba(17, 34, 51, 0.502)`, or `var(--unibox-color-primary)` for a
  role), a dimension (`8px`, `100%` for `double.infinity`), a padding or a margin in
  CSS's four-value order, and an image fit.

- A text input draws no frame of its own: `font: inherit` and `color: inherit` make it
  adopt the typography and the colour of the box around it, and the border, padding,
  background and focus ring are stripped, because the box around a field draws the frame
  on both targets. The cost is stated in the code: a focused field shows its caret and
  nothing else, on both targets, which is worth more than a browser frame on one.

- A state is a rule with a selector: `:hover` under `@media (hover: hover)` so a touch
  screen cannot get stuck in a hovered look, `:focus-visible` so a pointer press paints no
  ring, `:active`, and `[aria-disabled="true"]` so the visual state and the announced one
  cannot disagree. Each declares only what its state states.

- A theme is written as custom properties in one `:root` block, and `CssRule` carries a
  selector, its declarations and an optional media condition, so a string renderer and a
  DOM renderer write the same rules two ways from one value.

- A box can wear an outline instead of its rectangle: `cssShapePath`, `cssShapeClipPath` and
  `cssShapeClipId` write a `BoxShape` as SVG path data, in the units it was authored in and, for
  a clip, in bounding box units so one definition fits whatever element it is applied to. A
  shaped box's declarations send its fill and stroke to the layer as custom properties — which
  a state rule can paint — and replace its background, border, radius and shadow.

- A stack is a relative grid whose single row is the height of the stack rather than of
  its content, so a list inside it scrolls instead of growing the document; each child
  gets a cell it cannot escape; a child placed by offsets or by an alignment takes no
  pointer of its own, because a wrapper is a placement and not a control. Four equal
  offsets collapse into one `inset`, and an aligned child fills the stack with
  `inset: 0`.

- A grid counts its tracks from the width it is given. A text writes only the typography
  it states, clamps with the prefixed box layout when it is given a line count, and
  cancels what a user agent brings to a heading. An image is a block with an `object-fit`
  always stated, because an unset one lets a browser stretch the picture over its box.

- A box, as the web draws it: `boxDeclarations` states the flex container the
  model resolves to, the paint it names, the two floors a flex item needs, and the
  typography it installs for its subtree. `declaredOnly` emits only what the style
  states, which is what a state rule needs — a `:hover` rule that restated the layout
  would turn a row into a column. A transition belongs to the resting rule alone.

- `CssDeclarations` holds a list of declarations rather than a map: CSS allows a
  property to be written twice as a fallback, and `text` is the canonical spelling —
  sorted by property, insertion order within one property — that a class name is
  hashed from.

### The element layer, from `unibox_element`


- `BoxRole.progressBar` is planned as `role="progressbar"`, which is the role a name is allowed
  on: a labelled ring used to write `aria-label` on a `div`, and every audit of a page that drew
  one reported the attribute as prohibited. It states no tab stop, so a bar stays out of the tab
  order.
- `PagerNode` is planned as its own thing: the element carries `scroll-snap-type` and its
  children carry `scroll-snap-align`, and the class a pager wears is kept apart from the class of
  an ordinary scroller, because the child rule is part of what the class stands for.

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
