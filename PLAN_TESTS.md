# Plan: make the gates match the claims

What this is: the coverage gaps found by auditing the suites and the workflows after the client
renderer landed. Each task states what is wrong now, what it will be, and how I will know it is
done. Ordered by how much a failure would cost: a broken *deploy* first, then a broken *promise*,
then thin coverage.

Out of scope: new features, new packages, and anything in `PLAN_HTML.md`'s Deferred section.

---

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

## T3. The client's remaining bindings have tests

**Now.** Bound but untested: `onLongPress`, `onSubmitted` (Enter in a field), and a link's refusal
to cancel a modified or middle click and a `newTab` link. All three are behaviour a reader can hit
and a bug would be silent.

**Change.** `test/events_test.dart` in `unibox_dom` — the event bindings move out of
`stateful_test.dart`, which keeps the store lifecycle. Long press fires after the threshold and
swallows its click; Enter submits without a newline; a meta-click and a `newTab` link keep the
browser's behaviour while a plain click is cancelled.

**Done when.** The three cases pass, and `stateful_test.dart` is about state only.

## T4. Adoption keeps what a reader was doing

**Now.** `adopt_test.dart` proves the elements are kept. It does not prove the reason that matters:
that a focused field stays focused and a scrolled region stays where it was when the client arrives.

**Change.** Two cases: focus a field in the server's markup, adopt, assert `document.activeElement`
is still it; set `scrollTop` on the scroll region of the served markup, adopt, assert it isunchanged.

**Done when.** Both pass without the renderer compensating for them (they should, because it patches
in place — if a case fails, that is a bug in the patch, not in the test).

## T5. Flutter gets the behaviour tests it is missing

**Now.** 11 tests against the client's 67. Its suite leans on the conformance table, so it pins
*looks* well and *behaviour* thinly: no test that a box activates from the keyboard, that a press
during a publish still completes, or that a store is disposed when its node leaves the tree.

**Change.** Three widget tests in `unibox_flutter/test/box_widget_test.dart` and
`test/stateful_node_test.dart`, mirroring the three the client has, so the two renderers are held to
the same behaviour as well as the same appearance.

**Done when.** Each passes for the Flutter renderer, and a deliberately broken binding fails it
(checked by hand).

## T6. The rule that keeps this from drifting again

**Now.** Three of the bugs found while wiring the client were "a callback in the model that no
renderer bound". Nothing states the rule, so the next callback added to a node will repeat it.

**Change.** `AGENTS.md` gains the recipe: a callback on a node is not finished until every renderer
binds it and its suite covers it; `packages/unibox_dom/README.md` names `events.dart` as the file
that must hear about a new callback. `AI_INSTRUCTIONS.md` says the same in one line.

**Done when.** The docs say it, and `tool/check_docs.py` still passes.

---

## Order

T1 → T2 → T3 → T4 → T5 → T6. One commit each, `tool/verify.sh` before each, and a deploy dispatch
after T1 and T2 so the new gates are proven on the path that matters rather than only locally.
