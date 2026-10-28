# Working in this repository

Instructions for AI coding agents, and for the humans who review their work. Read
this file before changing anything.

Unibox describes a screen once, as an immutable Dart tree, and draws it twice: as
Flutter widgets in an application and as HTML/CSS in a browser. The value of the
project is that the two renderings agree, so most of what follows is about keeping
them in step.

## Read in this order

1. This file.
2. [`design.md`](design.md) §5 — the API conventions: naming, precedence,
   dimensions, parity, interaction, non-goals.
3. The node or token you are about to change, in `packages/unibox_core/lib/src/`.
4. `packages/unibox_testing/lib/src/` — the appearance both renderers owe.
5. The renderer you are changing, and `test/support/appearance.dart` beside it.

[`llms.txt`](llms.txt) indexes every document in the repository; the user-facing
guide is [`README.md`](README.md).

## The layout

| Path | What it holds | Touch it when |
| --- | --- | --- |
| `packages/unibox_core/lib/src/nodes/` | `UINode` and the eleven nodes: `Box`, `TextNode`, `ImageNode`, `LinkNode`, `StackNode`, `PositionedNode`, `TextInputNode`, `StatefulNode`, `OverlayNode`, `GridNode`, `EmbedNode` | a node gains or loses a parameter |
| `packages/unibox_core/lib/src/tokens/` | `BoxStyle`, `BoxTextStyle`, `BoxColor`, `BoxColors`, `BoxSpacing`, `BoxBorder`, `BoxShadow`, `BoxTransform`, `BoxTransition`, `BoxSemantics` | a design token is added or its meaning changes |
| `packages/unibox_core/lib/src/enums.dart` | layout, alignment, overflow and typography enums | a value both targets can express is missing |
| `packages/unibox_core/lib/src/validation.dart` | `validateTree` and `TreeIssue` | a construct becomes impossible to render faithfully |
| `packages/unibox_flutter/lib/src/` | one file per node (`FlutterBox`, `FlutterText`, ...), `values.dart` (token → Flutter), `render.dart` (dispatch and the validation assert) | the Flutter target has to change |
| `packages/unibox_jaspr/lib/src/` | the same for the web, plus `default_typography.dart` (the `:root` rule) | the web target has to change |
| `packages/unibox_testing/lib/src/` | `BoxAppearance` + `boxCases`, `TextAppearance` + `textCases`, `OverlayAppearance` + `overlayCases` | a presentational token is added or changed |
| `packages/unibox_material/lib/src/` | the Material 3 type scale: `MaterialTypography` (the fifteen roles as `const BoxTextStyle` values), `MaterialTypeRole`, the colour roles as `MaterialPalette` (`light`/`dark`), and the components built on the drawn nodes — `MaterialCard`, `MaterialListTile`, `MaterialInkWell`, `MaterialTextField`, `MaterialIcon` (`Box`) and `MaterialDialog`, `MaterialBottomSheet` (`OverlayNode`) | a design-system role is added, a scale or a palette changes, or a component is added |
| `packages/unibox_core/lib/src/state/` | `Store` and `StateStore`: the state a `StatefulNode` draws and the lifecycle a renderer calls | a store member, the publish rule or a lifecycle rule changes |
| `packages/*/test/support/` | the harnesses (`pumpNode`, `inNode`, `stylesOf`, ...) and `appearance.dart`, which reads the presentation back out of the output | a test needs a new fact |
| `example/unibox_example_shared/` | the page as one `StatefulNode` (`ExamplePageNode`, `ExampleState`, `ExampleStore`) and the trees it is built from, plus the palette | the example content changes |
| `example/unibox_example_flutter/`, `example/unibox_example_jaspr/` | hosts: the surface and the link policy, never layout or state | the surface or a link changes |
| `README.md`, `design.md`, package READMEs | the user guide, the reasoning, the per-target mapping tables | public API or behaviour changes |
| `AI_INSTRUCTIONS.md` | the consumer-facing counterpart: rules and a translation table for an assistant writing application code | a parameter is renamed or a default changes |
| `TASK_PLAN.md` | what was built, why, and what was deliberately deferred | rarely: record a decision, not a task |
| `RELEASE.md` | the release checklist | never automatically; it is a human procedure |

## Commands

Everything runs from the repository root: it is a [Dart workspace](https://dart.dev/tools/pub/workspaces),
so the packages share one resolution.

| What | Command |
| --- | --- |
| Resolve the workspace | `flutter pub get` |
| Format check, analysis and every suite | `tool/verify.sh` |
| Format check and analysis only | `tool/verify.sh --fast` |
| Rewrite formatting, then verify | `tool/verify.sh --fix` |
| Also build the API docs | `tool/verify.sh --docs` |
| One suite, the fast loop | `(cd packages/unibox_jaspr && dart test)` |

The eight suites, exactly as CI runs them:

```shell
(cd packages/unibox_core && dart test)
(cd packages/unibox_testing && dart test)
(cd packages/unibox_material && dart test)
(cd packages/unibox_jaspr && dart test)
(cd packages/unibox_flutter && flutter test)
(cd example/unibox_example_shared && dart test)
(cd example/unibox_example_jaspr && dart test)
(cd example/unibox_example_flutter && flutter test)
```

`dart test` for the pure Dart packages, `flutter test` for the two that build
widgets. A single suite is the loop while you work; `tool/verify.sh` is the gate
before a commit, and `dart analyze` is strict here (`strict-casts`,
`strict-inference`, `strict-raw-types`), so an untyped `dynamic` will not pass.

## The rules that are not negotiable

1. **`unibox_core` stays pure Dart.** No `dart:ui`, no Flutter, no Jaspr, and no
   package dependencies at all. `packages/unibox_core/test/purity_test.dart`
   enforces it, and it is the reason a third renderer stays possible.
2. **Defaults belong to the model.** When a token is unset, the answer is written
   in core (`BoxStyle.resolvedDirection`, `BoxTextStyle.defaults`,
   `ImageNode.resolvedFit`) and both renderers use it. Never fall back to a host
   default: Flutter's 14px text and the browser's 16px are exactly the drift the
   model exists to prevent.
3. **Flat parameters win over style bags.** `Box.computedStyle` merges `style`
   (deprecated) → `styles` left to right → the flat parameters. A state style
   overlays the resting one, and `disabled` overlays every state.
4. **No platform chrome.** Neither renderer keeps the decoration its host adds to
   a control: not Material's field underline, not the browser's input border,
   focus ring, link underline or heading margin. A control looks the way the tree
   says it looks.
5. **Parity is tested, not promised.** A presentational token is in
   `unibox_testing`, with one case that isolates it and a place in the
   "every token at once" case, or the token is not finished.
6. **Docs and changelogs move with the code.** A public change updates the README
   tables, the package README and the `## Unreleased` section of every
   `CHANGELOG.md` it touches. `dart doc` warnings fail CI, which means every
   public member keeps a doc comment.
7. **One direction of dependency.** Renderers depend on core; core never imports a
   renderer. A renderer knows nothing of the other renderer, and neither knows
   `unibox_material`.
8. **A design system is a package of values, plus nodes built from nodes.**
   `unibox_material` holds the Material 3 type scale as `const` `BoxTextStyle`
   values and the components built from `Box` (`MaterialCard`,
   `MaterialListTile`). It depends on `unibox_core` alone and adds no renderer code:
   a look is a value, and a component is a node that extends the node already drawn
   for it, never a new node type.
9. **State lives in a store, not in a node.** `StatefulNode` carries a factory
   and a view; the renderer creates the store, calls `onMount`, rebuilds and
   disposes it. The tree stays immutable, the view returns one tree, and an overlay
   is a node inside that tree rather than a second slot on the view.

## How a change lands

The recipes below are the touch points the tests hold you to. Read a whole recipe
before editing: half the work is on the other side of the repository, and a change
that lands on one target only fails the suites.

### A. A layout or paint token on `Box`

1. `packages/unibox_core/lib/src/tokens/box_style.dart` — the field, the
   constructor, `merge`, `==`, `hashCode` and `toString`. Miss one and a bag
   silently stops merging the token.
2. `packages/unibox_core/lib/src/nodes/box.dart` — the flat constructor parameter
   and the entry in `_flatStyle`. The flat spelling is the one most callers use,
   and it has to beat a bag.
3. If the token is painted, `packages/unibox_core/lib/src/tokens/box_transition.dart`
   — a `BoxProperty` member and a place in `BoxProperty.paint`; otherwise the token cannot
   be eased and `validateTree` cannot see it.
4. Flutter: `packages/unibox_flutter/lib/src/values.dart` (the mapping, when the
   token is a new value type), `lib/src/box.dart` (where the decoration, the
   transform or the sizing is built) and `test/support/appearance.dart` (how the
   appearance is read back for the contract).
5. Jaspr: `packages/unibox_jaspr/lib/src/values.dart` and `lib/src/box.dart` — the
   inline style, the four state rules (`:hover`, `:focus-visible`, `:active`,
   `[aria-disabled="true"]`) and the `transition` property list — plus
   `test/support/appearance.dart`.
6. The contract: `packages/unibox_testing/lib/src/appearance.dart` (the field
   in `BoxAppearance` and in `differencesFrom`) and `lib/src/cases.dart` (one case
   that isolates the token, plus the token in the "every token at once" case).
   `test/cases_test.dart` asserts that no two cases expect the same presentation
   and that the last case carries every token, so this step fails loudly when it
   is skipped.
7. Core tests for the merge and the precedence: `test/tokens_test.dart` and
   `test/box_test.dart`.
8. Docs: the `Box` tables in `README.md`, the defaults table and the motion
   section of `packages/unibox_core/README.md`, `design.md` §5.2/§5.4 when a rule
   changes, and the changelogs.

### B. A typography token

1. `packages/unibox_core/lib/src/tokens/box_text_style.dart` — the field, the
   constructor, `copyWith`, `merge`, `==`, `hashCode`, `isEmpty` and `toString`.
   `isEmpty` decides whether a renderer writes anything at all, so a new token
   has to be in it.
2. `packages/unibox_core/lib/src/nodes/text_node.dart` — the flat parameter and
   the `computedStyle` overlay. A token that only exists in `BoxTextStyle` is a
   token the common spelling cannot reach.
3. If the default changes, `BoxTextStyle.defaults` and the "Default typography"
   section of `packages/unibox_core/README.md` move together.
4. Flutter: `lib/src/values.dart` (`toTextStyle`) and the widget that consumes it
   (`text_node.dart`, plus `text_input_node.dart` when a field adopts it).
5. Jaspr: `lib/src/values.dart` (`toTypographyStyles`) and the emitter
   (`text_node.dart`, `text_input_node.dart`, and `default_typography.dart` for
   the `:root` rule).
6. The contract: `packages/unibox_testing/lib/src/text_appearance.dart` and
   `lib/src/text_cases.dart`, including `defaultTextAppearance` when the default
   is what changed. `textAppearanceOf` in both `test/support/appearance.dart`
   files has to read the new fact back out of the output.
7. Docs: [typography](README.md#typography), the core README, the changelogs.

### C. A node type

1. `packages/unibox_core/lib/src/nodes/<name>_node.dart`: a `const` immutable
   class extending `UINode`, a doc comment on the class and on every member, and
   an export in `lib/unibox_core.dart`. Add the `Node` suffix only when the bare
   name collides with a Flutter, Jaspr or HTML name — `Text`, `Image`, `Stack`,
   `Positioned` and `Link` do, `Box` does not. Both `test/naming_test.dart` files
   enforce the import half of that rule.
2. `packages/unibox_core/lib/src/validation.dart` when the node only makes sense
   in one place (`PositionedNode` in a stack, an item in a list, an embed with
   something to draw), with a case in `test/validation_test.dart`.
3. Flutter: `lib/src/<name>_node.dart` with an `Unibox<Name>` widget, the export
   in `lib/unibox_flutter.dart`, the case in the `renderNode` switch of
   `lib/src/render.dart`, a `<name>_widget_test.dart`, and the new export listed
   in `test/naming_test.dart`.
4. Jaspr: the same four files on the web side, ending in
   `<name>_component_test.dart`. The `renderNode` switch has a `_ =>` fallback
   that throws `UnsupportedError`, so a forgotten case is a runtime failure rather
   than a compile error.
5. The contract, only when the node carries presentational tokens the tables cover
   (boxes and texts). A node with no token — a link, an embed — is pinned by the
   renderer suites instead, which is honest: there is no appearance to compare.
6. Docs: the node sections of `README.md`, the node table of
   `packages/unibox_core/README.md`, the mapping tables of both renderer READMEs,
   and the changelogs. The example changes only if it demonstrates the node.

### D. A difference between the two renderers

Parity is a contract case, not a hunch, so a bug is fixed from the table
outwards:

1. Write the failing case in `packages/unibox_testing` first: the expected
   appearance for the token, in a case that isolates it. Run both renderer suites
   and read which one disagrees.
2. Fix the renderer that drifts — often both, because the table holds both to one
   answer. Never relax the expected value for one target, and never edit one
   suite's expectation: both suites import the same table.
3. When the fact cannot be read back out of one target's output, the table is the
   wrong place for it. Use a renderer-level test and record the asymmetry in the
   "what stays approximate" section of the relevant README, next to the others —
   a documented difference is a decision, an undocumented one is a bug.
4. If the drift is a construct rather than a token, it belongs in `validateTree`:
   a tree no renderer can honour faithfully is reported, not painted differently.

### E. The example

`example/unibox_example_shared` holds the trees, the state and the palette; the two
hosts hold only what a tree cannot know. Change the shared tree first, keep the
hosts to the surface and the link policy, and never lay anything out in a host — a
host that measures or spaces is the drift the conformance tables cannot catch.

### F. A stateful node

1. `packages/unibox_core/lib/src/nodes/stateful_node.dart` decides what the node
   receives; an application extends it (`class X extends StatefulNode<S, C>`) and
   never changes it.
2. The store implements `Store<S>`, or extends `StateStore` from `unibox_core`;
   its publish rule is tested in `packages/unibox_core/test/state_store_test.dart`.
3. Flutter: `lib/src/stateful_node.dart` renders it once for every node; the suite
   needs a test in `test/stateful_node_test.dart` (a publish, a dispose) rather
   than a renderer per component.
4. Jaspr: `lib/src/stateful_component.dart` holds the runtime, split on `kIsWeb`;
   the server path draws the state the store starts with and never calls `onMount`,
   and `test/stateful_node_test.dart` pins both. Reacting in a browser waits for the
   client build.
5. Docs: the state section of `README.md` and the core README, plus the changelogs.

### G. An overlay

1. `packages/unibox_core/lib/src/nodes/overlay_node.dart` — the node and its
   policy, and `validation.dart` when a new combination can do nothing.
2. Flutter: `lib/src/overlay_node.dart` presents it through an `OverlayPortal` on
   the root overlay; the suite needs a test in `test/overlay_widget_test.dart`.
3. Jaspr: `lib/src/overlay_node.dart` draws a fixed layer; it is never drawn in
   the flow of its parent.
4. The contract: `OverlayAppearance` and `overlayCases` in `unibox_testing`, read
   back from each renderer's output.
5. Docs: the node section of `README.md`, the core and renderer READMEs, and the
   changelogs.

## Definition of done

- `tool/verify.sh` passes. Add `--docs` when a public API changed, because CI
  fails on a `dart doc` warning.
- A new or changed token has a contract case and is in the "every token at once"
  case; a new construct has a validation rule; a new node has a test on both
  targets.
- Every public member has a doc comment, and the docs that describe the changed
  behaviour are updated in the same commit.
- Each `CHANGELOG.md` touched has a bullet under `## Unreleased`, written as what
  changed for the user, not which file changed.

## Code and prose style

- `dart format` at the default width, single quotes, `prefer_final_locals`,
  `sort_constructors_first`, `unawaited_futures` — see `analysis_options.yaml`.
  Run `tool/verify.sh --fix` rather than formatting by hand.
- Comments and doc comments explain *why*, in prose sentences, and the public ones
  are part of the API: `dart doc` has no patience for an undocumented public
  member.
- Prose in this repository is British English (`colour`, `centre`, `behaviour`)
  while identifiers are American (`BoxColor`, `backgroundColor`, `center`), because
  the identifiers are the API and the prose is the explanation.
- Tests read as sentences about behaviour — `'keeps a gap between two children'` —
  never `'test gap'`. A test that only restates the implementation is not worth
  adding; one that pins a decision is.
- A new abstraction earns its file. The repo has no `utils.dart`, no service
  layer, no generated code, and `BoxStyle` is deliberately hand written.

## Commits

Conventional Commits, one verified change per commit:

```text
feat(core): let a box wear several style bags
fix(flutter): clip a rounded box to its radius
test(conformance): hold both renderers to the transform and the opacity
docs: describe the style bags and the parts of a transition
```

The scope is the package that owns the change (`core`, `flutter`, `jaspr`,
`conformance`, `example`), or none for docs and the plan. The subject is a
lowercase phrase about what changed for the user, without a full stop. A change
that touches both renderers is one commit when both sides are the same decision,
and two when each side is independently reviewable.

## Out of scope

- **The `Deferred` section of [`TASK_PLAN.md`](TASK_PLAN.md).** Those items were
  left out on purpose, with the reason written next to them. Implement one only
  when a human asks for it by name.
- **Releasing.** Do not bump a version, close a changelog or remove
  `publish_to: none`. [`RELEASE.md`](RELEASE.md) is a human checklist; CI never
  publishes.
- **New dependencies.** `unibox_core` has none and keeps none. A renderer takes a
  dependency only when its host cannot do the job otherwise, and never on the
  other renderer.
- **A new workspace package** without listing it in the root `pubspec.yaml`
  workspace and in CI.
- **Breaking a public spelling.** Additions are minor; a rename or a removal keeps
  the old spelling as a deprecated forwarding member for at least one minor
  release (`design.md` §5.7).
- **Unrelated cleanups.** A commit that reformats, renames or refactors something
  the change did not need makes the review harder and hides the real diff.

## Where the detail is

| Question | Read |
| --- | --- |
| How do I use a node? | [`README.md`](README.md) — one section per node, with parameter tables |
| Why is the model shaped this way? | [`design.md`](design.md) — defaults, precedence, parity, non-goals |
| What does a token do on Flutter? | [`packages/unibox_flutter/README.md`](packages/unibox_flutter/README.md) |
| What does a token do on the web? | [`packages/unibox_jaspr/README.md`](packages/unibox_jaspr/README.md) |
| What is the model's default? | [`packages/unibox_core/README.md`](packages/unibox_core/README.md) |
| How does a node own state? | [`packages/unibox_core/README.md#state`](packages/unibox_core/README.md#state) |
| Which Material type role should I use? | [`packages/unibox_material/README.md`](packages/unibox_material/README.md) |
| What has to look the same on both? | [`packages/unibox_testing/README.md`](packages/unibox_testing/README.md) |
| What is built, and what was deferred? | [`TASK_PLAN.md`](TASK_PLAN.md) |
| How is a release cut? | [`RELEASE.md`](RELEASE.md) |
| How do the examples fit together? | [`example/README.md`](example/README.md) |
