# Working in this repository

Read this file before changing anything. Unibox declares UI regions once in pure
Dart and renders them as server HTML/CSS and Flutter widgets. Its value is keeping
content and design decisions in agreement without maintaining two descriptions.
The unit is a region: a band, card, footer or list. The application owns page
composition, routes, data, state and complex interaction.

## Read in this order

1. This file.
2. `design.md` section 5: API conventions and boundaries.
3. The affected node or token in `packages/unibox_core/lib/src/`.
4. `packages/unibox_testing/lib/src/`: the shared presentation contract.
5. The affected renderer and its output-reading test support.

`llms.txt` indexes documentation. `README.md` is the user guide.

## Current scope

- No DOM application runtime, client reconciliation or hydration package.
- No custom path/shape token, drawn ring, progress indicator or custom Material ink.
- Optional handover coordinates HTML-to-Flutter rendering. The host explicitly
  supplies readiness and its page controller or restoration callback. Read
  `docs/takeover.md` before changing capture, restore, replay, reveal or fallback.
- Material is palette, typography, card, button, chip, segmented control, codepoint
  icon and icon button, plus supporting values. Every Material component requires
  a native Flutter substitution. Do not silently reinstate custom widget fallbacks.
- Application-specific surfaces and indicators belong to the consumer.
- The optional stateful region adapter remains; it does not own application routing,
  networking or data. Material components consume supplied state and callbacks.

## Layout

| Path | Responsibility |
| --- | --- |
| `packages/unibox_core/lib/src/nodes/` | Immutable declarations and their parameters |
| `packages/unibox_core/lib/src/tokens/` | Shared presentation values, defaults and value semantics |
| `packages/unibox_core/lib/src/validation.dart` | Constructs the targets cannot honour |
| `packages/unibox_core/lib/src/state/` | Optional store lifecycle and handover record values |
| `packages/unibox_flutter/lib/src/` | Widget rendering, generic substitutions and optional handover |
| `packages/unibox_html/lib/src/` | Element planning, CSS, writing, documents and server handover helpers |
| `packages/unibox_testing/lib/src/` | Presentation and bounded behaviour expectations |
| `packages/unibox_material/lib/src/` | Small pure Dart Material vocabulary and design values |
| `packages/unibox_material_flutter/lib/src/` | Native Material mappings and Flutter theme conversion |
| `packages/*/test/support/` | Harnesses and readers of actual renderer output |
| `example/unibox_example_shared/` | Shared region trees and the small catalogue |
| `example/unibox_example_flutter/` | Flutter surface, link policy and readiness |
| `example/unibox_example_html/` | Documents and server metadata |
| `docs/nodes/` | Node parameter/default/target references |

Flutter box internals are split by responsibility: `box.dart` orchestrates,
`box_pinning.dart` handles sticky positioning, `box_layout.dart` handles stretching,
and `box_folding.dart` handles scroll-driven paint. They are private parts of one
library, not new public abstractions.

## Commands

Run from the repository root, a Dart workspace with shared resolution.

| Task | Command |
| --- | --- |
| Resolve | `flutter pub get` |
| Complete gate | `tool/verify.sh` |
| Format, then verify | `tool/verify.sh --fix` |
| Format/analysis fast loop | `tool/verify.sh --fast` |
| Include API docs | `tool/verify.sh --docs` |
| Document links | `python3 tool/check_docs.py` |
| Token/callback coverage | `python3 tool/surface_check.py` |
| Gate regression tests | `python3 tool/gate_tests.py` |
| Large-page baseline | `tool/scale.sh` |
| Build example documents and Flutter | `tool/site.sh` |
| Built document checks | `python3 tool/doc_check.py build/site` |
| Browser boot check | `tool/boot_check.sh build/site` |
| Performance reports and budgets | `tool/performance.sh` |
| Monthly maintenance | `tool/maintenance.sh` |

Suites, in dependency order:

```shell
(cd packages/unibox_core && dart test)
(cd packages/unibox_testing && dart test)
(cd packages/unibox_material && dart test)
(cd packages/unibox_html && dart test)
(cd packages/unibox_flutter && flutter test)
(cd packages/unibox_material_flutter && flutter test)
(cd example/unibox_example_shared && dart test)
(cd example/unibox_example_html && dart test)
(cd example/unibox_example_flutter && flutter test)
```

The gate checks Flutter against `.flutter-version`. If they disagree before the
first edit, report the environment failure and stop. Never change SDK constraints,
`.flutter-version`, workflows, budgets or checks to make an incompatible local run
appear green. Baselines may be updated only after reading and explaining measurements.

## Non-negotiable rules

1. Core stays pure Dart with no package dependencies or platform imports.
2. Defaults belong to the model. Neither renderer falls back to a different host
   default for a property the model decides.
3. Bags merge left to right; flat parameters win; state overlays resting values;
   disabled state wins over other states.
4. Core primitives do not retain accidental platform chrome. Native substitutions
   deliberately use platform interaction while preserving declared information.
5. Parity is tested. A presentational token needs an isolated contract case and a
   place in the all-token case, with readers of actual output on both targets.
6. Docs and changelogs move with code. Every public member has a doc comment; use
   backticks for type names in README prose to avoid unintended dartdoc references.
7. Dependencies flow from renderers to core. Neither generic renderer knows Material.
   The optional Material Flutter mapping is the boundary that knows both.
8. Design systems are values plus components built from existing nodes. Retained
   Material components must also have complete native Flutter mappings.
9. Application state stays with the host. A store used by a stateful region is created
   and disposed by its renderer, never stored on the declaration itself. Copied
   constructor parameters reconcile through `update`.
10. Const-compatible collection arguments must remain immutable after construction.
    Use const collections or unmodifiable snapshots. Value equality and hashing must
    agree by contents wherever values serve as map or stylesheet-cache keys.

## Recipes

### Layout, paint or typography tokens

Update the core field, constructor, merge/copy operations, equality, hash,
`isEmpty` where applicable and diagnostic output. Update flat node parameters and
their precedence. Add transition support when the token is paint that can ease.
Update both renderer mappings, state rules and stylesheet identity. Update the
shared appearance field, difference reader, isolated case and all-token case.
Update node docs, defaults, renderer mappings and affected Unreleased changelogs.
Do not add a token that only one public spelling can reach.

### Nodes and constructs

A node is immutable and documented, exported by core, supported by each renderer
or explicitly host-owned through an embed. Add tests on both targets and validation
for impossible combinations. A geometry decision that the appearance table cannot
read needs renderer-level layout tests. Update the node reference and package tables.
New packages require root workspace and CI membership together.

### Renderer differences

Start with a failing shared expectation when the fact belongs in the contract.
Fix the target that drifts; never relax one target's expectation independently.
When the fact cannot be compared through the table, test the renderer behaviour
and document the approximation. Valid finite descendants inside an unbounded outer
axis must remain accepted; do not widen validation to conceal a renderer bug.

### Callbacks and native substitutions

Flutter binds application callbacks. Server HTML writes real links and accessible
control meaning, without application event listeners. Handover is a separate opt-in
capture mechanism, not DOM interaction. Test both that an action runs when eligible
and that it does not run while disabled or after browser-handled navigation.

Substitutions are keyed by exact component type. Do not allow replacing structural
nodes wholesale. Preserve words, order, destinations, semantics, selection and
required actions. Verify native controls with the mapping installed, and verify a
missing required map is reported. Keep necessary component parameters as fields so
builders do not infer them from arbitrary descendants.

### Handover

Keep server helpers consumable without Flutter. The application chooses boot policy,
readiness and destination scroll ownership. Preserve normal browser links and modified
clicks. Record at most one latest intercepted keyed action and consume it once.
Restore before reveal and replay only after actual reveal. Missing, disabled,
ambiguous, stale and offscreen targets are discarded. Test loading, failure, focus,
continued scrolling and direct Flutter entry; do not use an arbitrary region's first
frame as the application's readiness signal.

### Examples and consumers

Shared declarations belong in the pure Dart shared package. Hosts own their surface,
link policy, native substitutions and readiness. Consumer migrations must preserve
existing worktree edits. Use coherent dependency overrides for local verification;
do not publish a branch or change release pins without the appropriate review.

## Definition of done

- `tool/verify.sh` passes; include `--docs` for a public API or README change.
- Presentation changes have the shared cases and output readers they require;
  constructs and callbacks have meaningful renderer tests.
- Public members are documented; current guides agree with the actual supported
  vocabulary; each affected changelog has user-facing Unreleased entries.
- Relevant site, handover, scale and consumer checks pass, or external/baseline
  limitations are identified with evidence. Never describe unrun checks as passed.

## Style and commits

Use `dart format` at default width, single quotes, final locals and the strict
analyser configuration. Prefer `tool/verify.sh --fix`. Tests read as sentences
about behaviour. Comments explain why. Prose is British English; identifiers keep
the API's American spelling. Avoid unrelated cleanups and abstractions without a
concrete responsibility.

Use Conventional Commits, one verified, coherent decision per commit. Package
scopes name the owner (`core`, `html`, `flutter`, `conformance`, `example`). Do not
release, bump versions, close changelogs, add unnecessary dependencies or edit
`RELEASE.md`; release remains a human procedure.
