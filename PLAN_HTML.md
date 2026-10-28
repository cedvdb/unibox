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
unibox_flutter  the widgets, and toWidget()
unibox_material the design system, unchanged
unibox_testing  the appearance both renderers owe, unchanged
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
9. **Nothing is released, so nothing is owed compatibility.** A rename, a deletion or a
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

**2. `unibox_html`, the emitter.** Escaping first, with adversarial tests (text,
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

**6. Cleanup.** Delete the cross-check tests and their temporary dependency on the
removed package.

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

- **Defer the download? No. Defer the execution.** The bundle is prefetched at parse time
  as a low-priority `rel=prefetch`, so its bytes arrive while the reader is reading. What
  waits is the boot, not the network. A deferred boot with a cold cache is the worst of
  both worlds: a good score and a two-second dead click.
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

### The gate

`tool/lighthouse.sh` runs Lighthouse against the exported pages in CI with a budget, not a
printout: performance ≥ 95 on a mobile profile, LCP ≤ 2.0 s, CLS ≤ 0.02, and no
blocking time before the application is asked for. A page that misses the budget fails the
build the way a test fails, because a performance claim that is not gated is a claim
nobody checks.

A second number is gated beside it, because Lighthouse measures the load and not the page:
**boot to first interactive frame**, taken by driving the exported page in a headless
browser — on a content page from the first pointer press, on an application entry from
`load`. That is the cost the reader pays, and it is the one a good document score is able
to hide. A page that scores 100 and takes two seconds to answer its first click has failed,
and the build should say so.

### The two tensions worth naming

- **A deferred boot costs the first interaction, and an eager one costs the first paint.**
  Both are real, so neither is the default everywhere: the page decides, and the two
  numbers in the gate — the document's and the boot's — keep either choice honest. A
  control that could be a link or a form should still be one, which is the advice the model
  already gives: a destination is a `LinkNode`, an action is the application.
- **Inline CSS trades caching for a round trip.** One document wins by inlining; a site of
  pages wins by a shared file. The document decides, and `tool/lighthouse.sh` measures the
  choice that was made.

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

### What lands now

**The hook, not a vocabulary.** A node may state an action, and the renderer writes it as
`data-unibox-action="list.reorder"`. The host implements it. The library defines the seam
and never the meaning of the name: the moment it ships `sortByPrice` as a concept, the
model has an interaction language and every member of it needs an implementation per
renderer.

### What stays out, and what would bring it back

A compiled **DOM renderer** — `unibox_dom`, the same tree patched into the DOM with a
store driving it — is possible precisely because `unibox_css` and `unibox_html` are pure
and carry no dependency; a renderer written against a framework's value types could never
have been compiled. It would reuse the CSS layer rather than duplicate it, at roughly 20 to
30 kB gzipped, against a Flutter engine of about two megabytes.

It is not built now for one reason: it makes **three** renderings that have to agree, and
the conformance table would hold all three, structural details included — the wrapper a
stack cell adds, the element a box chooses. That cost grows faster than the number of
renderers, and it should be paid for by a page that cannot be built otherwise.

It comes back the first time a real page needs an interaction that is neither a navigation
nor something the application should own — and the criterion is concrete: the interaction
cannot be expressed as a URL, cannot be a request, and is too frequent to boot an engine
for.

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

- A Dart client runtime, hydration, or re-rendering a tree in a browser — see "Interactions a document cannot carry" for the criterion that would bring one back.
- Translating Dart callbacks to JavaScript, at build time or at render time.
- A JSON node schema so a non-Dart host can author trees.
- Anything from the `Deferred` section of `TASK_PLAN.md` beyond the scroll handover
  already recorded there.
