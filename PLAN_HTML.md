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

- The bootstrap never runs at parse time. It starts on intent — `pointerover`,
  `touchstart`, `keydown`, or a focus inside the first viewport — and otherwise on idle,
  so a reader who only reads never pays for the application.
- The ink plays on the press that starts the boot, so the first interaction of a reader
  who did want the app is acknowledged rather than dead.
- The document preloads the faces the application draws with, and the fallback carries a
  `size-adjust`, because a font swap at boot is a layout shift.
- `tool/` measures the handover: the exported page is served, driven, and timed from the
  first byte to the first Flutter frame, with the number recorded beside the export.

### The gate

`tool/lighthouse.sh` runs Lighthouse against the exported pages in CI with a budget, not a
printout: performance ≥ 95 on a mobile profile, LCP ≤ 2.0 s, CLS ≤ 0.02, and total
blocking time of zero before the application boots. A page that misses the budget fails
the build the way a test fails, because a performance claim that is not gated is a claim
nobody checks.

### The two tensions worth naming

- **Deferring the boot costs the first interaction.** A reader who presses a control that
  needs the application waits for it. Pre-warming on hover and focus hides most of that,
  and a control that could be a link or a form should be one — which is the same advice
  the model already gives: a destination is a `LinkNode`, an action is the application.
- **Inline CSS trades caching for a round trip.** One document wins by inlining; a site of
  pages wins by a shared file. The document decides, and `tool/lighthouse.sh` measures the
  choice that was made.

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

- A Dart client runtime, hydration, or re-rendering a tree in a browser.
- Translating Dart callbacks to JavaScript, at build time or at render time.
- A JSON node schema so a non-Dart host can author trees.
- Anything from the `Deferred` section of `TASK_PLAN.md` beyond the scroll handover
  already recorded there.
