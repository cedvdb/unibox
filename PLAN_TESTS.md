# Plan: make the gates match the claims

What this is: the coverage gaps found by auditing the suites and the workflows after the client
renderer landed. Each task states what is wrong now, what it will be, and how I will know it is
done. Ordered by how much a failure would cost: a broken *deploy* first, then a broken *promise*,
then thin coverage.

Out of scope: new features, new packages, and anything in `PLAN_HTML.md`'s Deferred section.

---

## Where the plan stands

Reassessed after T1a. Two things changed under it: adoption no longer renders at all, and the
example's page stopped being a Flutter takeover — it is a document that runs itself. Both were found
by *doing* the plan, and both change what the rest is worth.

| | task | state |
| --- | --- | --- |
| T1a | adoption binds instead of rendering | **done** for the bind half (TBT 840 → 591 ms); the Flutter frame still loads unprompted, and the numbers need re-measuring now that the left frame is a document |
| **T0** | **the client check covers every interactive page** | **new, next** — the `../main.client.js` 404 in the example document was invisible to every gate, because `tool/dom_check.sh` only pressed a control on `/` |
| T1 | Lighthouse budget in CI | waiting on the re-measure |
| T2 | the documents still crawl | not started |
| T3 | the client's untested bindings | not started |
| T4 | adoption keeps focus and scroll | *mostly free now*: the fast path does not touch the DOM, so both survive by construction — the test is worth having, the work is not |
| T5 | Flutter's thin behaviour coverage | not started |
| T6 | the rule in the docs | not started |

## T1. The Lighthouse budget runs in CI

**Now.** `tool/lighthouse.sh` measures both exported documents against a budget (median of three
runs, per-run Chrome profile) and nothing runs it. The numbers that justify the whole approach —
zero blocking time, no layout shift, a largest paint that is real text — are re-measured by hand,
if at all.

**Change.** A `performance` job in `.github/workflows/pages.yml`, after the build, running the
script against `build/site`. Budgets are stated in the workflow so a regression fails the deploy and
fails it by name: Performance ≥ 90, CLS ≤ 0.01, TBT ≤ 200 ms, LCP ≤ 2.5 s.

**Done when.** The job runs on a dispatch, passes, and fails if I tighten a budget by hand to prove
it can (checked locally, not committed).

**Cost.** ~3 minutes of CI on the deploy path; a Chrome install (`ubuntu-latest` has one).

## T1a. The front page stopped being fast, and this gate is what found it

**Found while doing T1.** Measuring the built site, instead of documents written into a temp
directory, gave these numbers on the front page (`/`), all under Lighthouse's mobile profile:

| what was served | performance | LCP | TBT |
| --- | ---: | ---: | ---: |
| the document alone, before the client and the frames existed | 100 | 0.9 s | 0 ms |
| today, everything | **56** | **4.3 s** | **840 ms** |
| with the client's `<script>` removed | 50 | 5.1 s | 816 ms |
| with the frames' `src` removed | 70 | 3.8 s | 550 ms |

The two costs are separable and both ours:

1. **The comparison frames load a whole second document, and one of them boots Flutter.** The hero
   puts two live frames above the fold; the right one is the application, so a visit to a marketing
   page pays two megabytes before reading a word. `loading="lazy"` does not help when the frame is
   already in view.
   *Fix:* the right frame loads on request — a placeholder that says «start the Flutter rendering»
   and swaps its `src` on a press. The comparison stays one gesture away and the front page stops
   being an application.
2. **The client re-plans and patches a page the server already wrote.** On adoption nothing differs,
   so the work is all comparison: a plan for every node, an attribute check for every element, and
   a stylesheet rewritten with identical text. Under throttling that is most of a second.
   *Fix:* an adoption binds behaviour and keeps the tree's plan; it does not patch, and it does not
   rewrite a stylesheet whose text it has just read. A later publish patches from the plan as it
   does now — and a stale page is still corrected by the first publish.

### What the second fix did: the fonts were the paint

After adoption stopped rendering, TBT fell to 12–18 ms and CLS stayed 0 — and first paint was still
5.4 seconds. The cause was not the client, the CSS or the stylesheet: it was **496 kB of `truetype`**
(4 × 124 kB) behind a 46 kB document. Under a phone's network that is seconds of download before text
settles, and every `@font-face` waited for the stylesheet to be parsed before it was even discovered.

| | performance | FCP | LCP | TBT |
| --- | ---: | ---: | ---: | ---: |
| before | 63 | 5.38 s | 6.56 s | 12 ms |
| `woff2`, subsetted to Latin, two preloaded | **88** | **1.35 s** | 3.91 s | 17 ms |

The four faces went from 496 kB to 80 kB (`pyftsubset --flavor=woff2`, Latin range), the documents
`preload` the two weights that paint above the fold — with `crossorigin`, or the file is fetched twice
— and Flutter keeps the `ttf` files it draws with. What is left of LCP is the listing photograph, a
third party's asset: that one is content, and bundling it is a decision about this example, not about
the renderer.

### What the third fix did: local thumbnails, and a server that compresses

Two more things were true of the measurements rather than of the page. The listing photos came from
`images.pexels.com`, so the largest paint was a third party's latency; and every check served the
build with `python3 -m http.server`, which sends **no `Content-Encoding` at all** — 238 kB of client
where GitHub Pages sends 76 kB.

Six thumbnails are now bundled (72 kB, 260 px wide at quality 55; Flutter bundles the same six and
reaches them by asset name, the document by `../../assets/photos/`, which is why the page takes a
`photoPrefix` and an application takes none). `tool/serve.py` serves a build the way a host does:
threaded, gzip when the client accepts it.

| | performance | FCP | LCP | TBT |
| --- | ---: | ---: | ---: | ---: |
| remote photos, uncompressed serving | 85 | 2.01 s | 4.02 s | 10 ms |
| bundled thumbnails, uncompressed serving | 85 | 2.01 s | 4.02 s | 10 ms |
| bundled thumbnails, **compressed serving** | **98** | **1.05 s** | **2.42 s** | 19 ms |

The compression was most of it, which is worth saying plainly: three of these fixes were the page and
one was the ruler. The budgets now name **FCP** as the number this repository owns — the first paint
of the markup, before any content image — with LCP held to a line that leaves room for one photograph
over a phone's network, because on a page whose largest element is a photo, LCP measures the photo.

**And wasm?** No. TBT is the number a compiler shows up in, and it is 12–18 ms; `dart2wasm` would add
a larger download and a streaming compile to a page whose problem was 400 kB of fonts. The lever was
the bytes, not the machine code.

### What the first fix did

Adoption no longer renders: the client pairs the tree's nodes with the page's labelled elements,
creates the stores a stateful node needs, and binds — no plan, no patch, no stylesheet write — when
the document says it came from the same build (`meta[name="unibox-build"]`, which `tool/site.sh`
passes to `dart compile js`). A page from another build takes the old path, which is also what
repairs it.

Measured on the built site, Lighthouse mobile, the same machine:

| | performance | LCP | TBT |
| --- | ---: | ---: | ---: |
| before (plan + patch + CSS on adoption) | 56 | 4.30 s | 840 ms |
| after (bind only) | **60** | 4.30 s | **591 ms** |

So it recovered ~250 ms of the 567 the adoption cost, and it left the LCP where it was — which says
the largest paint is not the client's doing at all: it is a frame. The rest of the 591 ms is the
bundle's own parse and the stores the walk has to create (every ink well, destination and chip demo
on the page is a `StatefulNode`), plus ~270 ms that the frames' contents spend on the same thread.

What is left, in order of size: the **Flutter frame** (LCP and ~270 ms of TBT), then the 204 kB
bundle (65 kB gzipped) and the 20 kB of CSS re-downloaded in every page.

**Done when** the front page is back inside the budget of T1 with the frames and the client in
place, and the two fixes are separately committed and measured.

## T1. Done: one command, four measurements, a baseline

`tool/performance.sh` builds the site, measures both kinds of page against their budgets, boots the
takeover in a real browser, and prints the bytes; `--update` accepts the numbers as the baseline in
`tool/performance_baseline.json`. It runs in the deploy and in `tool/maintenance.sh`, so the answer to
"did the Flutter upgrade make this slower" is one command and a diff, not a memory.

What it says today:

| | performance | FCP | LCP | TBT | CLS |
| --- | ---: | ---: | ---: | ---: | ---: |
| `/web/listings/` — a document | **98** | 1.05 s | 2.34 s | 17 ms | 0 |
| `/` — a page that becomes Flutter | **90** | 0.90 s | 2.25 s | 333 ms | 0 |

boot to first frame **278 ms** · bytes, gzipped: document 5.8 kB, client 75.9 kB, fonts 73.4 kB,
photos 60.7 kB.

The front page reaching 90 is the takeover frame doing what a takeover does: HTML first (FCP 0.9 s),
then the engine (TBT 333 ms). It is the honest number for "a page that loads an application".

## T2. A gate that the documents still crawl

**Now.** Nothing checks that an exported page is still *readable as a document*. A renderer change
that turned a heading into a `div`, dropped the `alt` of an image, or emptied a band would pass every
suite and every Lighthouse number.

**Change.** `tool/doc_check.dart`: loads each exported `index.html` from disk, and asserts a floor
per page — words, `h1`, `h2`, links, `input`s, `sitemap.xml` entries, `robots.txt` text, and that
no page contains a `<script>` whose source is missing from the build. Wired into `pages.yml` beside
the boot and client checks.

**Done when.** It runs in CI, and lowering a floor by hand fails it locally.

**Cost.** ~10 seconds, no browser.

## T2. Done: the documents still crawl

`tool/doc_check.py` reads each published document off disk and holds it to what a page owes: a word
floor, an `h1`, its links and fields, the sitemap and robots — and, the one that earns its keep, that
**every file a document names is in the build**. It runs in the deploy beside the boot and client
checks.

It found two things on its first run:

1. `web/takeover/`'s photos had no `../../` prefix, so all six 404'd. The page drew the same tree as
   the document beside it and forgot the one thing a bundled image needs from its host.
2. Nothing else — but it *would* have caught the `../main.client.js` that cost an afternoon: pointed at
   a build with that mistake, it says `<script points at web/main.client.js, which is not in the build`.

## T3. The client's remaining bindings have tests

**Now.** Bound but untested: `onLongPress`, `onSubmitted` (Enter in a field), and a link's refusal
to cancel a modified or middle click and a `newTab` link. All three are behaviour a reader can hit
and a bug would be silent.

**Change.** `test/events_test.dart` in `unibox_dom` — the event bindings move out of
`stateful_test.dart`, which keeps the store lifecycle. Long press fires after the threshold and
swallows its click; Enter submits without a newline; a meta-click and a `newTab` link keep the
browser's behaviour while a plain click is cancelled.

**Done when.** The three cases pass, and `stateful_test.dart` is about state only.

## T3. Done: the bindings that had no tests, and the two bugs hiding in them

`unibox_dom/test/events_test.dart` covers what `stateful_test.dart` only used: a long press, `Enter`
in a field, and a link's refusal to cancel a modified or new-tab click.

Two real bugs came out of writing them:

1. **A long press did not swallow its click.** The tap listener was registered before the long-press
   one, and listeners run in the order they were added — so holding a control fired the press as
   well, which is exactly what a context menu is not. The hold is bound first now, and it calls
   `stopImmediatePropagation` rather than `stopPropagation`: the sibling listeners on the same
   element are the ones that must not run.
2. **The hold was bound twice** — a second call left behind by an earlier edit, so one press started
   two timers and reported two long presses. The test caught it in the first run.

## T4. Adoption keeps what a reader was doing

**Now.** `adopt_test.dart` proves the elements are kept. It does not prove the reason that matters:
that a focused field stays focused and a scrolled region stays where it was when the client arrives.

**Change.** Two cases: focus a field in the server's markup, adopt, assert `document.activeElement`
is still it; set `scrollTop` on the scroll region of the served markup, adopt, assert it isunchanged.

**Done when.** Both pass without the renderer compensating for them (they should, because it patches
in place — if a case fails, that is a bug in the patch, not in the test).

## T4. Done: adoption keeps what a reader was doing

Two cases, and the writing of them said something about the design: both had to make the *browser*
provide the condition rather than the tree, because the tree's heights and widths are class rules and a
test that serves markup without its stylesheet has an element nothing can scroll. That is the correct
split — the stylesheet is pinned by the conformance suite — and what these two hold is the one thing
adoption must not do: reset a scroll position, or move the focus. On the fast path nothing is touched,
so both survive rather than being restored.

## T5. Flutter gets the behaviour tests it is missing

**Now.** 11 tests against the client's 67. Its suite leans on the conformance table, so it pins
*looks* well and *behaviour* thinly: no test that a box activates from the keyboard, that a press
during a publish still completes, or that a store is disposed when its node leaves the tree.

**Change.** Three widget tests in `unibox_flutter/test/box_widget_test.dart` and
`test/stateful_node_test.dart`, mirroring the three the client has, so the two renderers are held to
the same behaviour as well as the same appearance.

**Done when.** Each passes for the Flutter renderer, and a deliberately broken binding fails it
(checked by hand).

## T5. Reassessed: nothing missing, and my count was wrong

This task was written on a miscount — 11 tests against the client's 67. The Flutter suite has **217**:
`box_widget_test.dart` alone has 34, and the two behaviours I named as missing are already there:
`interaction_state_test.dart` has a *keyboard activation* group (`activates a focused box with enter`,
and Space on the way up), and `stateful_node_test.dart` has `mounts the store once and disposes it on
unmount`.

What is genuinely client-only stays client-only: a long press swallowing its click, a hover reported
from a share, adoption of markup a server wrote. None of those has a Flutter counterpart to hold to —
Flutter has no server markup to adopt, and its gestures are its own widgets' business, tested by Flutter.

So: **no tests added, and a wrong claim corrected.** A plan that lists a task because a number looked
small should say so when the number turns out to be the alphabet, not the count.

## T6. The rule that keeps this from drifting again

**Now.** Three of the bugs found while wiring the client were "a callback in the model that no
renderer bound". Nothing states the rule, so the next callback added to a node will repeat it.

**Change.** `AGENTS.md` gains the recipe: a callback on a node is not finished until every renderer
binds it and its suite covers it; `packages/unibox_dom/README.md` names `events.dart` as the file
that must hear about a new callback. `AI_INSTRUCTIONS.md` says the same in one line.

**Done when.** The docs say it, and `tool/check_docs.py` still passes.

## T6. Done: the rule, in the three places it has to be

Three of the bugs found while writing the client were one mistake: a callback the model declared, a
component that relied on it, and a renderer that bound nothing — silent, because nothing throws.

- **`AGENTS.md` recipe H** — a callback on a node is not finished until every renderer binds it and each
  target has a test that it runs, and one that it does not run when it should not;
- **`packages/unibox_dom/README.md`** names `lib/src/events.dart` as the whole list, and says what
  happens when a callback is missing from it;
- **`AI_INSTRUCTIONS.md`** rule 13, in one line, for whoever is writing application code.

---

## Order

T0 → T1a(rest) → T1 → T2 → T3 → T4 → T5 → T6. One commit each, `tool/verify.sh` before each, and a deploy dispatch
after T1 and T2 so the new gates are proven on the path that matters rather than only locally.
