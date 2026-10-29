# Plan: the web target is a document

The working plan for `feat/unibox-html`. It is scratch: fold what survives into
`TASK_PLAN.md` and delete this file when the branch lands.

## The goal

A screen described once, as a tree, and drawn twice: as widgets in the application,
and as HTML a search engine can read. Nothing else. The library is not a web
framework, and it does not compete with one.

The shape the work serves:

```dart
final class ListingsPage extends Box {
  ListingsPage(List<Listing> listings)
      : super(children: <UINode>[for (final Listing l in listings) ListingCard(l)]);
}

// on the server, in plain Dart — no dart:io, no Flutter, no framework
final String page = ListingsPage(listings).toDocument(title: 'Apartments');

// in the application, once Flutter has taken the page over
Widget build(BuildContext context) => ListingsPage(listings).toWidget();
```

## What goes, and why

| | Lines |
| --- | --- |
| `unibox_jaspr` library | 3,161 |
| `unibox_jaspr` tests | 3,972 (22 files, 249 tests) |
| a beta dependency on the web path | `jaspr: ^0.24.0-beta.0` |

That package buys three things: a string emitter, a `Document` shell, and a client
runtime that re-renders the tree in a browser. The first two are 400 lines of
plumbing that a pure renderer owns more honestly; the third is a capability the
project has decided not to have, because the application is already the runtime.

## The target

```text
unibox_core     pure — the nodes, the tokens, the defaults
unibox_css      pure — tokens to CSS declarations, the class hash, the state rules
unibox_html     pure — toHtml(), toDocument(), and a small optional script
unibox_dom      the browser — the same tree into DOM nodes (phase 6)
unibox_flutter  the widgets, and toWidget()
unibox_material the design system, unchanged
unibox_testing  the appearance every renderer owes, unchanged
```

Both web-facing packages are pure Dart with no dependencies, so a document can be
rendered on a server, in a CLI, in a build step, and — for a host whose backend is
not Dart — compiled to JavaScript.

## Decisions

1. **The output is HTML.** No Dart runtime on the client: no hydration, no re-render,
   no store in a browser. A click that changes state is a page load or the
   application's job.
2. **`toHtml()` is a fragment, `toDocument()` is a page.** A fragment is what an island
   inside someone else's page needs; a page carries `title`, `lang`, `description`,
   `canonical`, Open Graph, a JSON-LD slot and a scripts slot.
3. **Page metadata is a parameter, not a node.** A tree describes a region of a
   document; a title describes the document. That rule is already written down and it
   does not move.
4. **A state is a snapshot.** `StatefulNode` draws its initial state, an `OverlayNode`
   draws open. Nothing is emitted that needs a runtime: no listeners from callbacks.
5. **Class names keep their shape**: `unibox-$kind-${fnv1a(declarations)}`. The class
   hash, the four state rules and the `:root` defaults move to `unibox_css` unchanged,
   so a host override written against today's output keeps working.
6. **`data-unibox-node` and `data-unibox-key` carry over.** They are how an inspector,
   a replay and a scroll handover find an element, and they are already renderer
   agnostic.
7. **Client JavaScript is optional and presentational.** Ink, overlay dismissal, and
   recording a press before the application arrives — as a `const String` a host
   serves or inlines. No application logic, no state beyond open/closed.
8. **An embed carries a payload per target.** `HtmlEmbed(String)` is the mirror of
   `JasprComponentNode`, and a tree with no implementation for this target is reported
   rather than silently skipped.
9. **One element plan, shared by every renderer that writes HTML.** Which element a node
   becomes, which attributes it carries, in what order, and which wrappers a renderer
   invents — decided once, in phase 2, before either renderer exists. A string renderer and
   a DOM renderer that disagreed about structure could never adopt each other's output, and
   a client renderer that has to repaint is one that flickers.
10. **A node's behaviour is a Dart callback, never a string.** `Box(onTap: store.reorder)` is
   the only spelling. An `action: 'list.reorder'` attribute would be a second, untyped way
   to say it, and it exists only when nothing can run a closure on the client — which
   `unibox_dom` changes.
11. **Jaspr is not kept.** `unibox_dom` is what `unibox_jaspr` was standing in for: a Dart
   renderer that runs in a browser. Keeping both would mean four renderings to hold to one
   appearance and a "which client renderer" question in every page of documentation, for a
   second implementation of a job that has one answer. Between phase 5 and phase 6 the
   example has no client runtime and relies on the takeover — which is the path the whole
   change exists to prove — and `jaspr` may remain only as a *host* dependency drawing
   ordinary Jaspr components of its own.
12. **Nothing is released, so nothing is owed compatibility.** A rename, a deletion or a
   spelling change is one commit with a changelog line, not a deprecation period:
   `design.md` §5.7 describes a promise that has not started. `unibox_jaspr` therefore
   goes outright rather than through a forwarding member, `toComponent()` goes with it,
   and the deprecated `style` bag on `Box` can go too — separately, so the removal of a
   renderer and the removal of a parameter are two reviewable changes.

## Phases

Each phase is one or more commits, and every commit ends with `tool/verify.sh --docs`
green.

**0. Room for the package.** Root `pubspec.yaml` workspace, the CI suite list,
`tool/verify.sh`, `llms.txt`. *`chore(workspace): make room for the html renderer`*

**1. `unibox_css`, the mapping.** Port `values.dart` family by family — colour,
spacing, sizing, border, shadow, typography, transform, transition, flex — into
`Map<String, String>` declarations, with `fnv1a`, the state selectors and the `:root`
defaults. While `unibox_jaspr` still exists, a temporary cross-check asserts that both
produce the same declaration text for a corpus of nodes, so drift cannot hide. One
commit per family.

**2. `unibox_html`, the emitter.** *(escaping done)* Escaping first, with adversarial tests (text,
attributes, `src`, `alt`), because that is where the only security bug in this package
can live. Then one node at a time: box, text, image, link, grid, stack, positioned,
text input. The conformance suite from `unibox_testing` is wired before the second
node, so each one lands against the table rather than after it. Then `<style>`,
`toHtml()`, and `toDocument()` with a typed head.

**3. The script, and the gate.** `uniboxClientScript` — ink from a press position,
overlay dismissal, press recording — plus a `node --test` suite that runs it against a
small fake DOM, since no Dart suite can exercise it. `tool/lighthouse.sh` and its budget
land here too, so the performance claim is measured from the first exported page rather
than added at the end.

**4. The example.** `example/unibox_example_jaspr` becomes an HTML host: `tool/`
exports one document per route with `sitemap.xml` and `robots.txt`, the takeover page
defers `flutter_bootstrap.js` to the first intent so a reader who never interacts pays
nothing, and the Flutter side replays the scroll offset and the press the document
recorded.

**5. Removal.** Delete `unibox_jaspr` outright — no deprecation, no forwarding member — and
settle the spellings listed below in the same commit that removes the parity test, so the
CSS changes once and visibly. Move the tests that still mean something
(appearance, structure, semantics, CSS) and delete the ones that describe a runtime
that no longer exists (interaction, stateful, overlay, hydration). Update
`unibox_testing`'s README, the root README, both renderer READMEs, `design.md` — one
new section: a document has no behaviour on the web — `AI_INSTRUCTIONS.md`, the
CHANGELOGs and `TASK_PLAN.md`.

**6. `unibox_dom`, the client renderer that replaces Jaspr.** The same tree into DOM nodes,
with the same declarations from `unibox_css` and the same element plan as the string
renderer, so it adopts the page the server wrote instead of repainting it. Client only —
`package:web` and `dart:js_interop` — compiled by the host with `dart compile js`. Born
with a conformance suite, because a renderer that is not held to the table is a third
design.

**7. Cleanup.** Delete the cross-check tests and their temporary dependency on the removed
package.

## Spellings to settle when Jaspr is gone

While `unibox_jaspr` exists the parity test demands byte-identical text, so the first
mapping reproduces Jaspr's serialiser exactly — including the places where that was an
accident. Those become a choice once nothing is left to be compatible with, and all three
want changing:

- `border: solid #112233 2px` → `2px solid #112233`. Both are valid CSS; the conventional
  order is what a reader of the output, and a golden file, expects to see.
- `margin: 0` for a user-agent reset but `padding: 0px` for a declared zero → one rule:
  a zero length is written `0`. The difference came from two constructors in one library,
  not from a decision.
- Every class containing a settled spelling gets a new name, because a class name is a hash
  of the text. That is why the spellings change in one commit, after the renderer is gone,
  rather than as a side effect of anything else.

## Handover and Lighthouse

The handover is part of the framework, not glue a host writes for itself. That means the
library ships four things, and each is specified rather than suggested:

1. the recorder, which captures where the reader was scrolled and what they pressed;
2. a boot contract — one global, one entry point — so the script that preloads and the
   application that arrives agree without the page knowing which implementation it got;
3. the Flutter side: `BoxScrollOffset`, `UniboxScrollScope`, and `initialScrollOffset` on
   a scrolling box, so the app starts where the reader left rather than at the top;
4. a documented deferral, since when to boot is the whole performance story.

### What each metric asks of the renderer

| Metric | What the renderer must do | How it is pinned |
| --- | --- | --- |
| CLS | write `width` and `height` on every image the node sizes, and `aspect-ratio` when it states both | a test per image case, and `validateTree` reports an image with no size at all |
| CLS | never restate a look in a state rule that would move something (the `declaredOnly` rule already in `unibox_css`) | the conformance table |
| LCP | no render-blocking request of its own: one stylesheet, no `@import`, nothing third party | the emitted document |
| LCP | the image the tree marks `fetchPriority: high` is written as such, and a `loading: lazy` one never is | a test per attribute |
| INP, TBT | no JavaScript in the document until the host asks for the bootstrap | the document has no `<script>` when `recordScroll: false` |
| unused CSS | only the classes the tree wears are emitted, one rule per distinct look | `classCount` against the tree |
| SEO | real text, `<h1>`–`<h6>`, `<a href>`, `<img alt>`, `lang`, title, description | the existing conformance cases |

The CSS is emitted as a string and the document chooses: inline it for a single page,
serve it as one cached file for a set of pages. Both are a `toDocument` parameter rather
than an assumption.

### What the example must prove (phase 4)

- **The download starts at once; the boot starts at the first sign of a reader.** The bundle
  is prefetched at parse time as a low-priority `rel=prefetch`, so its bytes arrive while the
  reader reads. The boot then starts when the pointer *moves* — before the press it leads
  to, so the engine's start-up is not spent inside the first interaction — and on a press, a
  touch, a key or a focus. An intent that arrives before the load is remembered and honoured
  at the load, so the engine never competes with the largest paint.
- **Two kinds of page, one choice.** `BootPolicy.immediately` for a page that *is* the
  application, `onPointer` for its front door. There is deliberately no "only on a press": a
  page that must never boot unbidden ships no boot script, and an interaction that must work
  without the application is a link or a form.
- **When to boot is a property of the page, not a global rule.** A content page and an
  application entry have opposite answers, and choosing one for both is how a project
  ends up optimising a number instead of a page:

  | The page is | Boots | Why |
  | --- | --- | --- |
  | content — an article, a listing, a landing page | on intent (`pointerover`, `touchstart`, `keydown`, focus), else on `load` + idle | the reader came to read; the application is a bonus, and its bytes are already warm |
  | an application entry — sign in, a dashboard, a booking | after first paint, on `load` + idle, never on first intent alone | the reader came for the application; making them wait for a click to start a boot they will always need is slower, not faster |

  `JasprScrollRecorder` and the boot contract are indifferent to which one a page chooses,
  which is why the choice is a parameter of the exported document rather than a rule in
  the renderer.
- The ink plays on the press that starts the boot, so the first interaction of a reader
  who did want the app is acknowledged rather than dead.
- The document preloads the faces the application draws with, and the fallback carries a
  `size-adjust`, because a font swap at boot is a layout shift.
- `tool/` measures the handover: the exported page is served, driven, and timed from the
  first byte to the first Flutter frame, with the number recorded beside the export.

## Remaining tasks: client execution, the API and the docs

What the takeover still lacks, what is clumsy to wire, and what the documents do not yet say.

- [x] **1. Key the example's scroll regions.** The recorder reads `data-unibox-key`, and no
  scrolling box in the example has one: the record is empty, so scroll replay cannot work end to
  end. `apartments.dart` and the two in `gallery.dart`.
- [x] **2. A takeover in one argument.** `toDocument` takes `prefetch`, `scripts` and a policy, and
  a host has to know that the recorders belong in `scripts` and the bundle in `prefetch`. One
  `Takeover(boot: …)` should carry all of it, with the recorders and the policy defaulted.
- [x] **3. Click replay.** The page records a press and nothing reads it. A `BoxPress` value in
  core, a pure `replayPresses(tree, presses)` that walks the tree to the node that carried the key
  and calls its callback, a browser reader in `unibox_flutter`, and the tests for both.
- [x] **4. Scroll replay, proved.** A Flutter test on a tree whose scrolling box is keyed the way
  the example keys it, so the two halves meet in one place.
- [x] **5. A boot time, measured.** The check asks whether the document boots; it cannot say how
  long it took, because `--virtual-time-budget` makes `performance.now()` virtual. A real number
  needs a browser driven over the DevTools protocol in real time, which `dart:io`'s WebSocket can
  do.
- [x] **6. The documents.** `README.md` gains the shape token, the client side (document, takeover,
  scroll and click replay) and the new packages in its tables; `packages/unibox_html/README.md` the
  same from its own side; `AI_INSTRUCTIONS.md` the takeover recipe; the changelogs the four bullets.

**Not in this pass: `unibox_dom`.** A client renderer is the largest piece in the repository, and
its criterion is unchanged — it comes back when an interaction cannot be a URL, cannot be a
request, and is too frequent to boot an engine for. Scroll and click replay cover the handover
before it exists; they do not make a document interactive.

## Remaining tasks: the merge with main

`main` moved 20 commits while this branch was open. The merge is resolved on `merge-main-wip`
(`83d1ad6`) except for one thing it cannot resolve: main added a **shape token**, and a web
renderer that does not draw one fails the example, which shows a box wearing each outline.

What main already proved on the web, and what this ports: an `<svg>` layer over the box, one
`<path>` inside, and the fill and stroke as custom properties so a state rule can reach them.
`clip-path` (not `clip-path: path()`, whose numbers are pixels) when the box clips its content.

- [x] **1. `unibox_css`**: `cssShapePath`, `cssShapeClipPath`, `cssShapeClipId`; a shaped box's
declarations replace its background, border, radius and shadow with the layer's four
  properties and, when it clips, the `clip-path`.
- [x] **2. `unibox_element`**: a shaped box's plan carries the `<svg>` layer as its first child,
  and the throw goes away.
- [x] **3. `unibox_html`**: the writer needs nothing — the plan holds the layer — but the
  conformance suite gains a shaped case of its own, since the appearance table cannot read an
  outline back.
- [x] **4. Verify the merge**: seven suites, `dart doc`, and the shape on the example's page.
- [x] **5. Land it**: fast-forward `feat/unibox-html` onto `merge-main-wip` and delete the
  working branch.

### The boot's base path, and how it was proved's base path, and how it was proved

A takeover page loads the application, and Flutter resolves its own entrypoint against
`document.baseURI` — `new URL(path, document.baseURI)`. Our documents sit at `web/listings/`,
so the generated bootstrap asked for `web/listings/main.dart.js` and the page booted into
nothing.

The fix is the build's, not a document's: the last line of `flutter_bootstrap.js` is an
unconfigured `_flutter.loader.load()`, and the loader takes the base as an argument, so
`tool/site.sh` writes `flutter/app.js` — the same bootstrap with that one call configured:

```js
_flutter.loader.load({config: {
  entrypointBaseUrl: '/flutter/',
  canvasKitBaseUrl: '/flutter/canvaskit/',
  assetBase: '/flutter/'
}});
```

Replacing the bootstrap is not an option: `_flutter.buildConfig`, which the loader reads before
anything else, is defined inside it. `assetBase` is the directory and not the `assets/` path,
because Flutter appends `assets/` itself — the first attempt asked for
`/flutter/assets/assets/FontManifest.json`.

**In the deploy.** `tool/boot_check.sh` writes a probe document beside the takeover pages, boots
it in headless Chrome and fails the workflow unless Flutter painted into it. It is the only
check here that asks a browser what happened, and the only one that would have caught the fault
above: a document that serves and never boots passes every other check in the repository.

**Checked, not assumed.** Serve the built site and dump the DOM after the scripts have run:

```shell
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new   --virtual-time-budget=40000 --dump-dom http://127.0.0.1:8000/web/listings/
```

The document boots `app.js`, which fetches `main.dart.js`, `canvaskit` and
`assets/FontManifest.json` from `/flutter/`, and `flt-glass-pane` is in the dump — the page has
become the application. Headless never moves a pointer, so the check passes only with a policy
that boots unbidden: `BootPolicy.immediately` for the run, `onPointer` in the page.

### The gate: measured, not predicted

`tool/lighthouse.sh` runs Lighthouse against the exported pages in CI with a budget, not a
printout: performance ≥ 95 on a mobile profile, LCP ≤ 2.0 s, CLS ≤ 0.02, TBT ≤ 50 ms. A
page that misses the budget fails the build the way a test fails.

Measured on the example's export, median of three runs:

| Page | Performance | LCP | CLS | TBT |
| --- | --- | --- | --- | --- |
| `listings/` | 100 | 0.90 s | 0.00 | 0 ms |
| `signup/` | 100 | 1.05 s | 0.00 | 0 ms |

Three runs and a median, because the first version of this gate failed a build at random: one
run of the *same* page spread from 72 to 100 with LCP at 5 s, entirely from Chrome instances
contending. And each run gets its own browser profile, because Chrome on macOS attaches to a
running instance and the next measurement then waits for a browser that is already busy.

The second number — boot to first interactive frame — still needs a built application beside
the export and is the next thing to wire; the export does not ship the Flutter bundle, so a
run today measures the document and stops, which is exactly the trap this section warns
about.

A second question is gated beside it, because Lighthouse measures the load and not the page:
**does the document become the application at all?** `tool/boot_check.sh` answers it in the
deploy, in a real browser, and fails when it does not.

The number is measured separately, because it cannot come from the dump: a one-shot `--dump-dom`
runs under `--virtual-time-budget`, which advances the page's clock faster than the wall clock, so
a `performance.now()` delta from it is virtual and means nothing. `tool/boot_time.dart` drives
Chrome over the DevTools protocol instead — a real browser in real time — and reads the mark the
probe writes on `flutter-first-frame`.

Measured on the assembled site, localhost, release build: **239 / 242 / 255 ms** from navigation to
the first frame. That is the handover's shape on a warm local connection, not what a reader on a
phone pays — that number is real-user monitoring's job — but it is real, and it is a floor a
regression would move.

### The two tensions worth naming

- **A deferred boot costs the first interaction, and an eager one costs the first paint.**
  Both are real, so neither is the default everywhere: the page decides, and the two
  numbers in the gate — the document's and the boot's — keep either choice honest. A
  control that could be a link or a form should still be one, which is the advice the model
  already gives: a destination is a `LinkNode`, an action is the application.
- **Inline CSS trades caching for a round trip.** One document wins by inlining; a site of
  pages wins by a shared file. The document decides, and `tool/lighthouse.sh` measures the
  choice that was made.

## The platform's own state, instead of custom elements

A custom element per node type is refused, and the reason is the product: `<unibox-text>`
is not a heading, `<unibox-link>` is not a link a crawler follows, and `<unibox-image>` has
no `alt` anyone reads. Customised built-ins (`<h1 is="unibox-text">`) would keep the tag and
the semantics, and Safari has never implemented them — so that door is closed by the
platform, not by taste.

Two things follow.

**One custom element, where a boundary is the point.** `<unibox-app>` — the element whose
`connectedCallback` boots the takeover. One definition is a design; eleven are a second
markup language.

**Native state beats both.** The node types that need behaviour should adopt what the
browser already has rather than reimplement it in a script:

| node | the element | what comes free |
| --- | --- | --- |
| `OverlayNode` | `<dialog>` + `showModal()` | Escape closes, focus is trapped, the page behind is inert |
| a menu, a popover, a tooltip | the `popover` attribute | light-dismiss, top-layer stacking |
| a disclosure | `<details>` | open and closed with no script |
| `TextInputNode` | `<input>` with `type`, `required`, `pattern` | keyboards and validation |

That is why the client script is small and stays small: closing a dialog is `close()`, not
a state machine.

**The cost, and when to pay it.** `<dialog>` brings `margin: auto`, a border, padding and a
background from the user agent, so adopting it means another reset in `unibox_css` — and
`showModal()`, the call that actually traps focus and answers Escape, only exists once
something runs JavaScript. So the overlay stays a `<div role="dialog">` in a document, and
becomes a `<dialog>` in phase 6, when the reset pays for something.

### A script in the tree: refused for the right reason

An earlier answer refused a node that carries JavaScript because it would be an injection
vector. That reasoning does not survive contact with the code: `HtmlEmbed` writes markup
verbatim and `DocumentScript.inline` writes a script body, so a host can already put any
code it likes in a page. A node is not a new class of risk — it is the same door in a
different place.

The real objections are mechanical:

- **a document is emitted once, a node once per instance.** Ten ink wells would ship ten
  copies of the same script unless the renderer collects and dedupes them — at which point
  the node is not carrying a script, it is carrying a *request*;
- **one file can be cached and hashed for a policy.** Per-instance inline scripts cannot be
  hashed by content, and force `unsafe-inline` or a nonce on every one of them;
- **a script means nothing on Flutter**, so a tree carrying one stops rendering on both
  targets without a no-op payload — which weakens the one claim the library makes.

So the seam is **request and collection**, not script in tree: a node asks for a behaviour,
and the document writes it once. That is what `data-unibox-ink` plus the host's single file
already does, with the request *derived* from the tree (a box that listens) rather than
declared. Declaring it becomes worth the field when a design system needs a behaviour the
renderer cannot derive — and then the vocabulary is the library's own closed set, unlike
`action:`, which would have carried application code.

`HtmlEmbed` and `DocumentScript` stay as the trusted, page-level door for code that is the
host's own.

## Interactions a document cannot carry

A list a reader can filter, sort and reorder is the case that keeps asking for client-side
execution. It decomposes, and only the last part needs any:

| Interaction | What it is | Needs |
| --- | --- | --- |
| filter, sort | a view of a list: a URL parameter the server renders | nothing: a `LinkNode` or a form |
| the panel holding the filters | a dialog the shipped script opens and closes | the script already planned |
| drag to reorder | instant feedback, then a request to persist | a host script, and the request |

For a page that exists to be found, a filter belongs in the URL anyway: a filtered list is a
link the reader can send and a crawler can read. And an order that is never sent anywhere
did not happen, so reordering is a request whichever way it is written.

### A callback is the API; a string would be a second, worse one

An earlier draft of this plan shipped `data-unibox-action="list.reorder"` on a node, with
the host implementing the name in JavaScript. That is refused: the string exists only
because a string renderer cannot carry a closure, it is untyped where the tree is typed,
and it puts the behaviour of a node somewhere the node cannot see.

So a node states what it does the way it always has — `Box(onTap: store.reorder)` — and the
question becomes whether anything can run that closure in a browser.

### The client is compiled, not stringly

`unibox_dom` renders the same tree into DOM nodes on the client and is compiled to
JavaScript with `dart compile js`, the way the Jaspr example ships `main.client.js` today.
It is not a fourth renderer: it is the third one, and the one `unibox_jaspr` was standing
in for. Deleting that package and adding this one leaves the count where it started. Callbacks work because they are Dart closures in the same program
as the store; no attribute protocol exists and none is needed.

What it is:

- the third renderer, client only: `package:web` and `dart:js_interop` are its dependencies,
  and nothing else;
- the same declarations from `unibox_css`, so a class name is the same string on the server
  and in the browser — which is what lets it adopt the server's DOM instead of repainting;
- a re-render at the boundary of each `StatefulNode`, with keyed children reconciled by
  `key`, which is the same contract the other two renderers already keep;
- ~20 to 30 kB gzipped, against a Flutter engine of about two megabytes.

What it costs, honestly:

- **DOM patching is the hardest bug surface in this project.** Jaspr spent years on
  hydration and its retake/finalize logic; a second implementation means owning that
  class of bug again — focus, selection, scroll inside a patched subtree, an element
  reused for a different node.
- **A conformance suite of its own**, though not a fourth one: the table goes on holding
  three renderings to one appearance, as it does today with Jaspr. The suite replaces a
  suite rather than adding one.
- **A build entry per application**, since a client renderer only runs compiled.
- **Three ways for a page to be interactive** — nothing, the document runtime, or
  Flutter — which is one choice more than a reader of the docs can hold without help.

### The constraint that makes it cheap: one structure, decided once

The string renderer and the DOM renderer must produce the *same elements* — same tag, same
attributes, same class, same order, same renderer-invented wrappers. That is what makes
adoption possible (the client takes the server's nodes; it does not repaint them) and what
keeps the two mappings from becoming two designs.

So the decision of which element a node renders to, and in what order a node's attributes
are written, belongs in one place shared by both renderers, and it is taken in phase 2 —
before either renderer exists — rather than discovered twice.

### Order of work

`unibox_dom` is not built in this change. The HTML document and the handover prove the
reason the library exists first; a client renderer is then an addition to a working story
rather than a bet placed before it. It is phase 6, and the phases before it are its
design: the CSS layer it will share, the element plan it will follow, and the conformance
table it will join.

## Acceptance

- `tool/verify.sh --docs` green at every commit, with nine suites: core, testing,
  material, css, html, flutter, example shared, example html, example flutter.
- `unibox_testing` still holds two renderers to one appearance: Flutter and HTML.
- One URL proves the whole thing: a crawler reads the text and the metadata, a reader
  without JavaScript reads and scrolls it, and the application takes over on first
  intent at the position the reader left.
- No package on the web path has a dependency, and `dart compile js` of a document
  renderer produces something callable from Node.

## Risks

- **Escaping.** The only place this package can be unsafe. Adversarial tests before
  any node is emitted.
- **CSS drift while both renderers exist.** Bounded by the cross-check in phase 1,
  which fails loudly until it is deleted in phase 6.
- **Lost coverage.** ~65 of the 249 Jaspr tests describe behaviour that is deliberately
  not in the library any more. They cannot be ported; they are replaced by tests that
  pin what a document does instead ("draws the initial state", "draws the overlay open").
- **The example's interactivity.** The form, the dialog and the ink are the showcase.
  Each is decided in phase 4: the script, a page load, or the application.
- **Two mappings during the migration.** `unibox_jaspr` keeps its Jaspr-typed one until
  phase 5; the pure one is the only one that survives.

## Out of scope

- A client runtime in this change. `unibox_dom` is phase 6 and is specified above; nothing
  before it may depend on it.
- Translating Dart callbacks to JavaScript, at build time or at render time.
- A JSON node schema so a non-Dart host can author trees.
- Anything from the `Deferred` section of `TASK_PLAN.md` beyond the scroll handover
  already recorded there.
