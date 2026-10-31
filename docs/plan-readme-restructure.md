# Plan: a summary README, and a page per node

## The problem

`README.md` is the front door of the repository and the user guide, and it carries
the whole reference for every node: about six hundred lines of parameter tables,
examples and per-target notes between `## The nodes` and `## Colours`. A reader who
wants to know how the library is served, or what a token defaults to, scrolls past
them; a reader who wants one node's table finds it in a guide that is otherwise about
the model.

The Material components have the opposite problem: they are fully documented in
`packages/unibox_material/README.md`, and the root README mentions them in a single
paragraph, so nothing on the front page says which components exist.

## The shape after the change

- `README.md` keeps the guide — how it works, serving a tree, the quick start — and
  replaces the node reference with a **summary table**: one row per node, one sentence,
  a link to that node's page. The Material section is the same shape: one row per
  component, one sentence, a link into the package README's own section.
- `docs/nodes/` holds the reference, one page per node, and an index page. The text is
  **moved**, not rewritten, so nothing a reader relied on is lost.
- The cross-node subjects stay in the root README, because they are not about one node:
  colours, roles and theming, typography, motion, semantics, what the host owns, and how
  the two renderers stay in step.

## Decisions

1. **Per-node pages live in `docs/nodes/`.** `docs/` already holds the repository's
   images, the pages are for a reader of the repository rather than of one package, and
   `dart doc` renders package READMEs, not these. Ten pages plus an index.
2. **Material is not duplicated.** `packages/unibox_material/README.md` already documents
   every component in full, section by section. The root README summarises and links to
   those sections instead of creating a second copy that would drift from the first.
3. **The material section named "The segmented button" covers the tabs as well** — its
   first half documents `MaterialTabBar` and `MaterialTabs` — so its heading becomes
   "The tabs and the segmented button", which is the anchor the summary links to.
4. **`tool/check_docs.py` learns about `docs/nodes/`.** The pages are reference
   documents, so their own relative links are checked like a root document's, and each
   one is listed in `llms.txt`. A page that links to a file renamed under it is the same
   bug the script exists to catch.
5. **The node count is eleven**, which the README already says after the grid change;
   the summary table lists all eleven (the old prose list had once missed `GridNode`).

## Subtasks

- [x] 1. Write this plan (`docs/plan-readme-restructure.md`).
- [x] 2. Create `docs/nodes/` and move each node's section of `README.md` into its own
      page: `box.md`, `text.md`, `image.md`, `link.md`, `stack.md`, `text-input.md`,
      `stateful.md`, `grid.md`, `overlay.md`, `embed.md`.
- [x] 3. Retarget the links inside those pages: `#links` → `link.md`, `#box` →
      `box.md`, `#overlaynode` → `overlay.md`, `#motion` and `#typography` →
      `../../README.md#…`, and the core README link → `../../packages/…`.
- [x] 4. Write `docs/nodes/README.md`, the index: the eleven nodes, one table, and where
      the cross-node subjects live.
- [x] 5. Replace `## The nodes` in `README.md` with the summary table and its links, and
      add `## Material` with a summary table that links into the package README.
- [x] 6. Update the `## Contents` list, the two remaining in-README links into the moved
      sections, and the Material heading the summary points at.
- [x] 7. Update the documents that point at the old sections: `AI_INSTRUCTIONS.md`,
      `AGENTS.md`, `CONTRIBUTING.md`, `MAINTENANCE.md`, `llms.txt`.
- [x] 8. Extend `tool/check_docs.py` with the node pages and index them in `llms.txt`.
- [x] 9. Verify: `python3 tool/check_docs.py`, the README link sweep, and
      `tool/verify.sh --docs` (a README was edited).
- [x] 10. Commit the verified change and push to `main`.

## Status

- [x] 1. Plan written
- [x] 2. Node pages created
- [x] 3. Links retargeted
- [x] 4. Node index written
- [x] 5. README summaries written
- [x] 6. Contents and remaining links updated
- [x] 7. Pointers updated
- [x] 8. Docs check extended
- [x] 9. Verified — `tool/verify.sh --docs` passes, every file and anchor resolves
- [x] 10. Pushed to `main`

## What was found on the way

- The old prose list of nodes in `README.md` said "eleven" but omitted `GridNode`; the
  summary table lists all eleven.
- `README.md` linked to `example/README.md#the-static-site`, a heading that no longer
  exists; it now points at `#the-site-is-one-page`.
- `tool/check_docs.py` resolved every relative link against the repository root, which
  was only correct while every document lived there. It now resolves against each
  document's own directory, so a page under `docs/` is checked like one at the root.
- The Material README had drifted the same way a summary exposes: it said the package
  "exports three names" (it exports the scale, the palette and the components), "ten
  components" (there are twenty), that chips and navigation were "not built" (both are),
  and that the bottom sheet "rounds all four corners" (it rounds the two it rises from,
  as `MaterialBottomSheet` says in its own doc comment). The root README's "fifteen
  components", `llms.txt`, `AGENTS.md` and `AI_INSTRUCTIONS.md` now point at the
  summary or name the whole set instead of a count that goes stale.

