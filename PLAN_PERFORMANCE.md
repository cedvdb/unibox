# Performance, and the pages that have a lot of nodes

This is the plan the scale work was done from, and the record of what it found. It is
kept the way [`PLAN_HTML.md`](PLAN_HTML.md) is: where it disagrees with the code, the
code wins.

## Why

`tool/performance.sh` measures the *site*: Lighthouse scores, boot to first frame, and
the gzipped bytes of the document, the client and the assets. Every one of those is a
question about a page we ship, and none of them is a question about the pipeline a tree
goes through: resolve a style → hash a class → plan an element → write text. A page with
twelve nodes and a page with twelve thousand are the same size to Lighthouse and could not
be further apart in the pipeline.

So there was no answer to "does a big page cost what it should", and no guard against a
change that made it cost more. The review that produced this file found six places where the
answer was no, and what each of them cost is measured below.

## What is measured

`tool/scale.sh` runs `packages/unibox_html/tool/bench.dart`, which builds three synthetic
trees at doubling sizes and times each stage separately:

| Shape | What it is | What it exists to catch |
| --- | --- | --- |
| `shared-look` | N rows of three labels, every row dressed alike | the cost of a page with a handful of looks, which is the common case |
| `distinct-look` | the same rows, one background colour per row | a look that varies with the data, which is what a list from a store does |
| `deep-chain` | N boxes nested one inside the next, a label at the bottom | depth, where an emitter that copies a subtree per ancestor shows up |

`plan` is `planNode` with a fresh `Stylesheet`; `write` is `writeElement`; `css` is
`documentCss`. The numbers are printed as a table for a human and as JSON for the guard.

### The guard

`tool/scale_check.py` compares a report with `tool/scale_baseline.json` and fails on the
three things a runner can be trusted to answer:

1. **Exact facts.** Class count and byte count per shape, equal to the baseline. These are
   deterministic — same tree, same bytes — so a change in either is a change in what the
   renderer produces, and it has to be looked at.
2. **Shape.** `time(2N) ≤ 2.6 × time(N)` per shape and per stage. A ratio measured on one
   machine in one run is worth more than an absolute time across machines, and it is
   exactly the question: linear work doubles when the input doubles, quadratic work
   quadruples.
3. **Absolute cost, loosely.** `time ≤ 4 × baseline`, so a regression that is uniformly
   slow is still caught, without failing on a busy runner.

Write a new baseline with `tool/scale.sh --update`, and only after reading the table.

## What the review found

Measured on a 2026 MacBook, before any of the fixes below. `nodes` counts every node;
`classes` is how many distinct looks the rendering needed.

| Shape | nodes | classes | plan | write | total |
| --- | --- | --- | --- | --- | --- |
| shared look | 4,001 | 5 | 4.6 ms | 7.6 ms | 12.3 ms |
| shared look | 8,001 | 5 | 9.4 ms | 15.3 ms | 26.4 ms |
| distinct looks | 4,001 | 1,004 | 8.9 ms | 7.9 ms | 22.5 ms |
| distinct looks | 8,001 | 2,004 | **26.2 ms** | 15.4 ms | **49.6 ms** |
| deep chain | 801 | 2 | 2.3 ms | 1.9 ms | 4.1 ms |
| deep chain | 1,601 | 2 | 4.5 ms | **17.0 ms** | 22.3 ms |

Doubling the tree doubles a linear stage and nothing more. Both of the bold numbers break
that, and both are structural rather than incidental.

### F1 -- a publish re-serialises and re-parses the whole stylesheet

`packages/unibox_dom/lib/src/mount.dart`, `_paint` and `_repaintBoundary` assign
`style.textContent = documentCss(...)` on **every** pass, and a store that publishes every
frame -- an ink ripple, a spinner -- publishes sixty times a second. The text cannot have
changed (same tree, same classes), and a stylesheet of 2,000 looks is 320 KiB, so this is
the most expensive thing a page does per publish, for nothing.

### F2 -- adoption walks the DOM quadratically

`DomView._adopt` calls `root.querySelectorAll('[data-unibox-node]')` **twice per
iteration** -- once in the loop condition and once in the body -- so pairing a server's
page with the client's tree is O(n²) subtree queries in the reader's first frame.

### F3 -- class registration is a linear scan, and the key is rebuilt every time

`Stylesheet.classFor` finds a class with `_rules.any(...)`, and the key it scans for is
`CssDeclarations.text`, which sorts the declarations and joins them **on every call**. So
each node pays O(d log d) to build its key and O(k) to look it up, for k registered looks.
That is the distinct-look column above.

### F4 -- the emitter copies every subtree once per ancestor

`writeElement` returns a `String` per node, which its parent then writes into its own
buffer: the text of a leaf is copied once for every level above it, so a deep tree costs
O(output x depth). The deep-chain column, at 1,601 boxes of a single text node.

### F5 -- keyed diffing is O(k²) across the language boundary

`patchChildren` matches keys by scanning the pool per plan (`_matchKeys`), calling
`element.getAttribute` on every candidate, and then looks the previous plan up again per
child in `_planOf`. A keyed list of 200 rows is 40,000 cross-language attribute reads per
publish.

### F6 -- `computedStyle` is resolved twice per box

`_planBox` resolves its own style, and then resolves every child's style again to ask
whether that child holds a visibility threshold. `computedStyle` merges every bag and the
flat parameters into a fresh `BoxStyle`, so half of that work is allocated and dropped.
`_planBox` also builds three maps per box where one would do.

### Recorded, not fixed

- **A hover in Flutter rebuilds the subtree.** `FlutterBox.build` builds its children in
  the same method that `setState` on hover, press or focus rebuilds. It is bounded (hover
  fires on enter and exit, not per pixel) and Flutter reuses elements, so it is a stretch
  target rather than a defect. Fixing it means moving the interaction layer outside the
  content, which changes widget structure and needs a Flutter-side measurement to justify.
- **A long-lived view never prunes its stylesheet.** `DomView._sheet` lives as long as the
  view, so a page re-rendered with changing looks accumulates rules. Correct-ish (a class
  is a look, and a look that may come back is worth keeping) and only wrong for a host that
  re-renders constantly with new looks.
- **The planner recurses per level** and overflows the stack at about 2,600 levels of
  nesting. No page is that deep; a limit would be a validation rule nobody needs yet.

## The tasks

Each is one commit. `P1` first, because it is the guard the rest are measured against.

| # | Task | Where | Done |
| --- | --- | --- | --- |
| P1 | The benchmark, its baseline, its gate and its CI job | `packages/unibox_html/tool/bench.dart`, `tool/scale.sh`, `tool/scale_check.py`, `tool/gate_tests.py`, `.github/workflows/ci.yml` | yes |
| P2 | A publish that changes no class leaves the stylesheet alone (F1) | `packages/unibox_dom/lib/src/mount.dart` | yes |
| P3 | Adoption queries the DOM once (F2) | `packages/unibox_dom/lib/src/mount.dart` | yes |
| P4 | `CssDeclarations.text` is computed once; `Stylesheet` indexes by class (F3) | `packages/unibox_css`, `packages/unibox_element` | yes |
| P5 | The emitter writes into one buffer (F4) | `packages/unibox_html/lib/src/write.dart` | yes |
| P6 | Keyed matching indexes both sides (F5) | `packages/unibox_dom/lib/src/patch.dart` | yes |
| P7 | A box resolves its style once, and a child's threshold is read without one (F6) | `packages/unibox_element/lib/src/plan_node.dart` | yes |

Acceptance for every one of them: the suite of the package it touches passes, `tool/verify.sh`
passes, and `tool/scale.sh` reports the same bytes and class counts as before — a
performance change that changes the output is a bug, not a faster renderer.

## What it costs now

Measured after the fixes, on the same machine, with the same benchmark:

| Shape | nodes | classes | plan | css | write |
| --- | --- | --- | --- | --- | --- |
| shared look | 6,001 | 4 | 9.8 ms | 0.1 ms | 10.1 ms |
| shared look | 12,001 | 4 | 14.5 ms | 0.0 ms | 20.6 ms |
| distinct looks | 6,001 | 1,503 | 9.4 ms | 0.4 ms | 10.6 ms |
| distinct looks | 12,001 | 3,003 | 19.5 ms | 0.7 ms | 22.2 ms |
| deep chain | 801 | 2 | 3.1 ms | 0.0 ms | 1.0 ms |
| deep chain | 1,601 | 2 | 4.2 ms | 0.0 ms | 2.0 ms |

Doubling the tree now doubles every stage: the two shapes that broke the rule are at 2.1x
and 2.0x, where they were at 2.5x and 9.6x.

- **F3**: 41 ms → 19.5 ms to plan 12,001 nodes with 3,003 distinct looks, and 13.8 ms → 0.7 ms
  to serialise their stylesheet, because a class's declarations are sorted and joined once
  rather than twice and the sheet is indexed by class instead of scanned.
- **F4**: 20 ms → 2.0 ms to write a chain of 1,601 boxes, at the same bytes.
- **F1**, **F2**, **F5**, **F6** are on the DOM side or are smaller, and the benchmark cannot
  see them: a browser is what pays. F1 and F2 are pinned by the tests in
  `packages/unibox_dom/test/stateful_test.dart` and `adopt_test.dart`, and the two the tests
  cannot observe — a query per element, a key list squared — are one lookup each now.

The bytes and the class counts are identical before and after, which is the point: none of
this changed what a renderer produces.
