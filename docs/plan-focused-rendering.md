# Plan: focus Unibox on declarations, rendering and Flutter handover

Status: implemented on `codex/focused-rendering`, 23 November 2026.
The companion Comover migration is on `codex/focused-unibox-integration`.
Unchecked acceptance items below still require integration validation or landing.

## 1. Product boundary and agreed decisions

Unibox is a platform-independent UI declaration rendered as HTML on the server
and as widgets in Flutter. Its primary unit is a shared region: a card, heading,
footer, filter band or list. The application owns routing, data, state and page
composition. Unibox is not an application framework.

Agreed direction:

- Remove `unibox_dom` and its browser application runtime.
- Keep optional HTML-to-Flutter handover support in Unibox. Comover should use
  that mechanism rather than maintain a competing implementation.
- Keep intercepted keyed press replay and scroll restoration as handover features.
- Record document scrolling automatically; restore to a Flutter scrollable the
  host explicitly supplies, after the host signals that layout is ready.
- Keep a small optional Material vocabulary. Every retained Material component
  must have a native Flutter substitution. Palette and typography are values,
  so this component requirement does not apply to them.
- Remove the custom shape/path API, circular progress indicators, progress rings,
  spinners and their supporting rendering machinery.
- Preserve generic substitutions and the shared renderer conformance contract.
- Make targeted changes rather than rewrite the declaration model or renderers.

Handover packaging is resolved: optional `handover.dart` entry points in
`unibox_html` and `unibox_flutter`. Server consumers import the former without
requiring the Flutter SDK. No companion package is needed.

## 2. Baseline, inventory and implementation order

- [x] Read `AGENTS.md`, `design.md` section 5, the affected model and conformance
  cases before each implementation slice.
- [x] Record the current commit and worktree changes. Preserve unrelated files,
  including the existing untracked `overscroll.png`.
- [x] Run `tool/verify.sh` using `.flutter-version`. If Flutter versions disagree,
  stop as the repository instructions require; do not change SDK constraints.
- [x] Recheck the existing formatting and lint findings from the audit. Resolve
  genuine baseline failures in an independently reviewable change before using
  the gate as evidence for subsequent changes.
- [x] Inventory imports and public API use across Unibox, both examples, Comover's
  app and server, and `explore_v2`. Inspect the parked `explore` separately so an
  obsolete reference does not dictate the active API.
- [x] Record the Comover dependency pins and overrides needed to test a coherent
  candidate revision across the model, renderers and Material packages.

Land in this order: correctness fixes; handover contract and extraction;
declarative Material replacements and consumer migration; shape and DOM removal;
remaining internal refactoring; final documentation and verification.
Prepare migrations before removing APIs that active consumers still use. These
phases may be developed together, but every landed revision must be coherent.

## 3. Correctness fixes identified by the audit

These are independently useful fixes, not reasons to enlarge the project.

- [x] Fix URL scheme handling in `unibox_html/lib/src/element/url.dart`.
  Include embedded tab, newline and carriage-return cases, ordinary relative
  links, supported schemes and both HTML and DOM-setting paths while DOM exists.
- [x] Fix CSS string escaping and HTML style-element raw-text safety. A font
  family containing quotes, backslashes, line breaks or `</style>` must not
  corrupt a declaration or introduce markup through `toHtml` or `toDocument`.
- [x] Repair `BoxStyle` equality/hash consistency for shadow collections and
  check all equality fields. Test equal values constructed independently,
  including use as map keys and stylesheet cache keys.
- [x] Decide and document collection ownership for nodes and tokens. Account for
  `const` constructors: do not promise defensive copying that their constructors
  cannot perform. Test the chosen rule for children, shadows, paths while they
  exist, and image candidates; audit cache assumptions about mutation.
- [x] If DOM remains usable during migration, fix `DomView.adopt(...).dispose()`
  deleting sibling elements. Otherwise remove the affected runtime with DOM and
  record that the finding was eliminated by removal rather than repaired.

Acceptance: adversarial output and value-semantics tests pass; no unsafe URL or
style output is accepted merely because application inputs are usually constants.

## 4. Define and consolidate handover

### 4.1 Placement and dependency boundaries

- [x] Compare Unibox's boot, recording, replay and readiness code with Comover's
  `server/lib/ui/documents/takeover.dart`, document host and Flutter bootstrap.
  List the behaviour each already provides before choosing the shared version.
- [x] Choose placement. Prefer keeping the integration in `unibox_flutter` if a
  pure Dart server entry point can be consumed without requiring the Flutter SDK
  or leaking widget imports. Otherwise use a companion package with separate
  server and Flutter libraries and prove the same server dependency boundary.
- [x] Keep core free of browser globals, boot policy, mutable handover state and
  renderer dependencies. Neither HTML rendering nor Flutter rendering should
  activate handover simply because a package was imported.
- [x] If adding a workspace package, update root workspace membership, CI,
  verification, docs jobs and dependency resolution together. Add no package
  merely to satisfy a naming preference.
- [x] Use one canonical implementation and public vocabulary. Remove duplicate
  host orchestration after migration; make breaking renames outright rather
  than keeping deprecated aliases.

### 4.2 Host contract and transition lifecycle

- [x] Specify explicit lifecycle states: document visible, Flutter loading,
  restoring, Flutter visible and failed/fallback. Define idempotence and cleanup.
- [x] The host supplies bootstrap location, start policy, destination scroll
  controller and readiness. The host owns route selection, data fetching and
  application state.
- [x] Distinguish engine startup/first frame from host readiness. Do not reveal
  the wrong route or an intermediate loading layout just because Flutter painted.
- [x] Keep HTML visible and usable while Flutter loads. Hide the Flutter surface
  from interaction and accessibility until reveal.
- [x] Freeze the final captured position/intent at a defined restoration boundary,
  then restore scroll, reveal, transfer focus as appropriate and replay the intent.
  Define what happens to input arriving during this short boundary.
- [x] Preserve timeout and failure fallback, status announcements, focus handling,
  reduced-motion behaviour and existing CSP/nonce support where applicable.
- [x] Cancel stale transitions and release listeners after success, failure or
  navigation. Ensure direct Flutter entry works without handover globals.

### 4.3 Keyed press recording and replay

- [x] Define a stable handover key encoding shared by HTML and Flutter. Keep
  ordinary sibling-local widget keys separate from the page-wide uniqueness
  required for handover; support stable string/int identities explicitly.
- [x] Record only an eligible press on a keyed Unibox target that handover
  actually intercepts. Do not record browser-handled actions for later replay.
- [x] Preserve modified clicks, new-tab intent, downloads and other native link
  behaviour. Specify eligibility for ordinary links versus application actions.
- [x] Deliver the action once to the same keyed Flutter target after readiness.
  Discard missing, ambiguous, disabled, stale or cancelled targets safely.
- [x] Define the pending-intent policy explicitly: start with one pending press,
  rather than an unbounded queue of actions against a page that is changing.
- [x] Verify replay with retained native Material substitutions. A substituted
  component must expose its actual action target without also firing a wrapper.
- [x] Cover nested targets, duplicate keys, repeated readiness, boot failure,
  target removal, navigation and exactly-once delivery in regression tests.

### 4.4 Scroll capture and restoration

- [x] Capture the latest document scroll position throughout loading, rather than
  only its position at bootstrap. Define both axes and coordinate units.
- [x] Let the Flutter host provide the destination controller or an explicit
  restoration callback. Do not guess the main scrollable from the widget tree.
- [x] Restore once after the host says data and layout are ready and scroll
  dimensions exist. Clamp offsets to the available extent; avoid an animated
  jump while the hidden surface is being positioned.
- [x] Expose the captured position for manual restoration in unusual hosts.
  Specify precedence with browser/history restoration and Flutter restoration.
- [x] Preserve keyed nested-scroll restoration where both sides explicitly opt
  into the same identity; do not mistake a region's internal offset for its
  document position.
- [x] Treat absolute offset as the initial supported strategy. Reserve a future
  keyed-anchor plus viewport-distance strategy for measured layout drift; do not
  make it a prerequisite for the initial consolidation.
- [x] Test continued scrolling during boot, zero/short content, unattached
  controllers, layout changes, nested scrollables and direct Flutter entry.

### 4.5 Comover migration and end-to-end acceptance

- [x] Wire the existing mixed HTML document to the shared handover mechanism.
- [x] Supply the actual Flutter page controller and signal readiness only once
  the intended route, data and layout are ready.
- [x] Replace Comover's duplicate boot/reveal/recording code. Retain only host
  configuration and application-specific readiness/restoration decisions.
- [ ] Verify real catalogue and zone pages at narrow and wide widths: scroll
  while loading, press a card before readiness, navigate normally through links,
  and simulate a failed or slow Flutter load.
- [ ] Confirm no blank interval, duplicate action, hidden focused control or lost
  fallback document. Include accessible focus and announcement checks.

## 5. Reduce Material to components with native substitutions

### 5.1 Retained surface and admission rule

Initial retained surface:

| Kind | Retain | Flutter implementation |
| --- | --- | --- |
| Values | Palette, scheme variants and typography/type roles | Theme conversion helpers |
| Component | Button | Native Material button variants |
| Component | Card | Native `Card` |
| Component | Chip | Appropriate native chip variants |
| Component | Segmented control | Native `SegmentedButton` |

Every retained component needs a working native mapping, a useful server HTML
declaration, and tests preserving content, order, semantics and actions. Native
substitution availability is necessary, not sufficient: it does not justify
keeping the rest of the catalogue. Values remain useful without substitution.

- [x] Confirm the exact public allowlist before deletion. Treat `MaterialIcon`
  and `MaterialIconButton` as explicit candidates because `explore_v2` uses
  them and native mappings exist; retain only if their concrete use warrants it.
  Otherwise migrate their uses to host-owned declarations/substitutions.
- [x] Keep elevation and density helpers only where retained components need
  them. Decide whether each needs to remain public.
- [x] Remove the remaining catalogue by default: scaffold, app bars, navigation
  bar, list tile, tabs/tab bar, text field, dialog, bottom sheet, custom ink well,
  drawn check mark, spinner and progress ring. Identify nested dependencies before
  deleting files or exports.
- [x] Keep primitive layout, border and shadow facilities needed by declarations;
  removing paths does not imply removing ordinary rectangular decoration.

### 5.2 Declarative controls and native Flutter rendering

- [x] Make retained controls depend on supplied values and callbacks. The host
  supplies selected/enabled state and rebuilds the declaration when it changes.
- [x] Remove retained components' dependence on custom `MaterialInkWell` stores,
  ripple timers and drawn check marks. Use native Flutter behaviour in substitutions
  and declarative HTML appearance/semantics for the server representation.
- [x] Interpret “native substitution only” as the supported Material Flutter
  rendering path: require installation of the Material mapping and report a
  missing mapping clearly. Do not silently ship a second custom Flutter control
  implementation. Decide the smallest registration mechanism without making
  `unibox_flutter` import Material or special-case Material types.
- [x] Keep generic substitution support available for consumer-owned components.
- [x] Audit native builders against declared labels, selection, enabled state,
  callbacks, links, theme values, sizing and content. Fix mismatches rather than
  assuming the existence of a builder establishes correctness.
- [x] Preserve server navigation: a segment or chip with a destination must render
  a real link. Document HTML that requires handover for an application action.
- [x] Verify native variants can faithfully represent retained declarations;
  simplify unsupported parameters instead of promising arbitrary node content
  that native controls cannot honour.
- [x] Keep `unibox_material_flutter` as the optional mapping boundary unless a
  concrete dependency review establishes a simpler arrangement. Neither core nor
  generic renderers should depend on the Material declaration package.

### 5.3 Migrate consumers and test the reduced set

- [x] Migrate `explore_v2` card, banners and waitlist uses of `MaterialInkWell` to
  declarative links/actions plus native Flutter surfaces where required.
- [x] Resolve the action bar's icon-button and glyph dependencies explicitly.
- [x] Update Comover's `appSubstitutions`, theme conversion, imports and tests.
- [x] Test each retained component through server HTML and its native Flutter
  substitution, including content, links, enabled state and selection callbacks.
- [x] Add a check that the retained component allowlist and mapping stay complete.
- [x] Replace the example's broad catalogue with the small supported vocabulary.

## 6. Remove shapes, rings and their support

- [x] Remove `BoxShape`, path commands and shape-specific public exports,
  `Box.shape`, `BoxStyle.shape`, transition properties and validation rules.
- [x] Remove Flutter path conversion, custom shape painting and clip handling that
  exists exclusively for paths; retain border-radius clipping and normal paint.
- [x] Remove HTML SVG/path planning, shape CSS, hashes and helper exports.
- [x] Remove progress rings, circular progress indicators, spinners and shape-based
  check marks; migrate any remaining example or consumer use to native host UI.
- [x] Remove shape-specific contract fields and cases, and update the all-token
  case and surface classifications. Preserve checks for every surviving token.
- [x] Remove obsolete shape tests and assets; keep unrelated raster/image embeds
  and the generic host embed mechanism.
- [x] Recheck dependencies after removal; remove only those now unused.

## 7. Remove DOM and reassess stateful scope

- [x] Remove `packages/unibox_dom`, exports, tests, workspace membership, CI suite,
  documentation job and example dependencies.
- [x] Remove the example browser client entry point and DOM hydration build path.
  Keep server HTML generation and Flutter handover examples runnable.
- [x] Remove DOM-specific performance measurements, adoption APIs and browser
  runtime claims. Preserve handover script tests and browser integration checks.
- [x] Keep shared HTML planning/CSS code still used by server rendering. Delete
  public internals only after checking actual server consumers.
- [x] Inventory `StatefulNode`, `Store`, `StateStore`, overlay and behaviour-table
  uses after Material pruning. Decide explicitly whether to remove them or retain
  a narrowly justified Flutter-facing capability. Their removal was discussed,
  but was not agreed as an automatic consequence of removing DOM.
- [x] Prefer application-owned state producing a fresh tree. If removing stateful
  APIs, migrate examples and consumers first, then remove dispatch, validation,
  lifecycle and tests together. Handover's internal transition state does not
  require a public application-store API.
- [x] Separately review remaining interactive primitives against the product
  boundary. Do not remove unrelated nodes merely because the Material wrapper
  that used them was removed; record a use case or a reason for removal.

## 8. Internal simplification, documentation and final gate

- [x] Refactor `FlutterBox` along actual responsibilities after removals: layout,
  interaction/semantics, sticky positioning and scroll effects. Extract cohesive
  mechanisms while preserving behaviour; avoid unrelated renames and abstractions.
- [x] Add rendered integration coverage for representative Comover bands at
  narrow/wide widths, long translations and enlarged text. Keep declaration-level
  conformance tests; supplement them with geometry and behaviour where necessary.
- [x] Update `README.md`, package READMEs, `design.md`, `AI_INSTRUCTIONS.md`,
  `AGENTS.md`, `llms.txt`, node docs, example docs and `docs/takeover.md` to state
  one consistent boundary. Resolve contradictory naming and stale catalogue claims.
- [x] Update each affected package's `## Unreleased` changelog with user-visible
  removals and changes. Record deleted packages' removal in surviving project docs.
  Do not bump versions or perform release procedures.
- [x] Update workspace/CI/build tools and document indexes without weakening gates
  or performance budgets. Review historical plans rather than rewriting history.
- [x] Run targeted suites per slice, then `tool/verify.sh --docs` for the final
  public API/README changes. Run docs, surface and gate checker tests too.
- [x] Run relevant site, handover and performance checks. Compare measurements
  before accepting any baseline update; do not expand a budget to hide regressions.
- [ ] Verify the Comover app/server integrations against one coherent Unibox
  revision or local override, including production builds and handover smoke tests.
- [x] Land reviewable Conventional Commit slices. No release, dependency addition,
  new workspace package or unrelated cleanup should occur without its documented
  justification and required repository wiring.

Completion means a smaller library that still renders shared regions on both
targets, uses native Flutter Material controls for its retained Material vocabulary,
and supplies optional, host-directed handover without a browser application runtime.

## Implementation decisions and verification

- Baseline Unibox revision: `0f61ccf62b96fc1cfce513815ce198c078781d41`. The existing
  `overscroll.png` remains untouched and outside this change.
- Handover uses separate optional entry points in the existing HTML and Flutter
  packages. No package or dependency was added. The server stays pure Dart.
- Icons and icon buttons remain: Comover uses them, and they have native mappings.
  Codepoint icons require explicit const Flutter glyph registration so release
  builds can tree-shake fonts. Ligature icons and custom ink were removed.
- Stateful nodes/stores and generic overlays remain bounded region adapters.
  They do not own application routes, data fetching or application composition.
- Const-compatible declarations retain collections. Callers provide const values
  or immutable snapshots; defensive copying is not claimed.
- The DOM adoption/disposal defect was eliminated by removing the DOM runtime.
- The full `tool/verify.sh --fix --docs` gate passes, including all retained
  suites, analysis, contract checks and zero-warning API documentation.
- Comover shared tests: 116 pass. Card layout tests: 16 pass, including French
  content, enlarged text and narrow/wide widths. Document tests: 27 pass.
  Targeted native widget tests: 24 pass. The app release web build and native
  server compilation have both succeeded against the local migration.
- Five Comover rendering expectations also fail in a clean snapshot of its
  unchanged revision. They concern photo markup/CORS/loading and struck pricing.
  Their expectations were not weakened. Emulator-dependent backend suites and
  live catalogue/zone acceptance remain separate integration work.
- Comover currently uses local `pubspec_overrides.yaml` files in app, server and
  explore_v2 to test one coherent candidate. Before merging that repository,
  replace those local resolutions with a single committed Unibox revision and
  regenerate its lockfiles. No remote dependency pins, release or deployment
  have been performed. Its pre-existing app substitution edit is preserved.

The release-browser smoke test passes for both automatically discovered Flutter
hosts and pre-existing embedded hosts. It verifies a real keyed press, reveal and
accessible host exposure. Static crawlability checks and the scale baseline pass.
Live Comover catalogue/zone walkthroughs remain unchecked above: these local
release smoke tests do not establish production data or backend behaviour.
