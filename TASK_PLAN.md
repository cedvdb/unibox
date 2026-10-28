# Unibox Execution Plan

### Phase 1: Workspace & Core Models (`unibox_core`)
- [x] Task 1: Initialize root Dart 3.13 workspace and scaffold `unibox_core`, `unibox_flutter`, and `unibox_jaspr` (using `jaspr: ^0.24.0`).
- [x] Task 2: Implement styling tokens and enums in `unibox_core` (`BoxColor`, `BoxSpacing`, `BoxStyle`, alignments, overflow).
- [x] Task 3: Implement all 7 AST nodes in `unibox_core` (`Box`, `TextNode`, `ImageNode`, `LinkNode`, `StackNode`, `PositionedNode`, `TextInputNode`) with unit tests verifying `computedStyle` merging logic (`dart test`).

### Phase 2: Flutter Renderer (`unibox_flutter`)
- [x] Task 4: Flutter `Box` — Implement layout (Flex row/col, gap, padding, margin, sizing, background, border, tap/hover callbacks) with widget tests (`flutter test`).
- [x] Task 5: Flutter `TextNode` — Implement typography (font size, weight, color, text align, maxLines, ellipsis) with widget tests.
- [x] Task 6: Flutter `ImageNode` — Implement media rendering (`Image.network` vs `Image.asset`, dimensions, `BoxFit`, border radius) with widget tests.
- [x] Task 7: Flutter `LinkNode` — Implement link interaction (navigation/tap callback delegation) with widget tests.
- [x] Task 8: Flutter `StackNode` & `PositionedNode` — Implement layering (`Stack`) and absolute layout (`Positioned`) with widget tests.
- [x] Task 9: Flutter `TextInputNode` — Implement controlled `TextField` (state controller synchronization, obscureText, multiline, `onChanged`, `onSubmitted`) with widget tests.

### Phase 3: Jaspr Renderer (`unibox_jaspr`)
- [x] Task 10: Jaspr `Box` — Implement `<div>` (Flexbox CSS, `box-sizing: border-box`, dimensions, gap, background, border, click/hover listeners) with component tests (`dart test`).
- [x] Task 11: Jaspr `TextNode` — Implement `<span>` (typography styles, text alignment, webkit line clamp) with component tests.
- [x] Task 12: Jaspr `ImageNode` — Implement `<img>` (src, alt, dimensions, `object-fit`, border radius) with component tests.
- [x] Task 13: Jaspr `LinkNode` — Implement semantic `<a>` tag (`href`, `target: _blank`, click event override) with component tests.
- [x] Task 14: Jaspr `StackNode` & `PositionedNode` — Implement `position: relative` container and `position: absolute` children with component tests.
- [x] Task 15: Jaspr `TextInputNode` — Implement `<input>` / `<textarea>` (controlled value, input/submit DOM events) with component tests.

### Phase 4: Integration & Verification
- [x] Task 16: Build an `example` package with a shared interactive form/card rendered across both Flutter and Jaspr targets.
- [x] Task 17: Run workspace-wide `dart analyze` and execute all test suites across all packages to verify zero errors and clean builds.

### Phase 5: Public API conventions
- [x] Task 18: Document the naming rule, the typography-only inheritance rule, the flat-over-style precedence and the non-goals (no CSS selectors/cascade, no drag & drop) in `design.md`, the root `README.md` and the `UINode` docstring.

### Phase 6: Tree correctness (no API break)
- [x] Task 19: Add `Object? key` to `UINode` and every node constructor; map it to a `ValueKey` in Flutter and to the component key in Jaspr, with tests proving two reordered `TextInputNode`s keep their own text.
- [x] Task 20: Add pure Dart `validateTree(UINode)` (`PositionedNode` outside `StackNode`, nested `LinkNode`, `overflow: scroll` with `mainAlign`, empty `TextNode`) exported from core and asserted by both renderers in debug builds.
- [x] Task 21: Assert in the Flutter link renderer that a link without an `FlutterLinkScope` and without `onTap` is a host configuration error, and update the existing link tests.

### Phase 7: Inherited typography
- [x] Task 22: Implement the `BoxTextStyle` token (`fontSize`, `fontWeight`, `color`, `lineHeight`, `fontFamily`, `letterSpacing`) with `merge`, `copyWith`, equality and token tests.
- [x] Task 23: Wire `textStyle` into `BoxStyle` and as a flat `Box` parameter, and give `TextNode` an optional `style: BoxTextStyle` with a `computedStyle` getter.
- [x] Task 24: Flutter renderer — wrap box children in `DefaultTextStyle` when typography is set, map the new text tokens and let `TextField` adopt the inherited style.
- [x] Task 25: Jaspr renderer — emit inherited typography on the `<div>` (`font-size`, `color`, `line-height`, ...) so CSS inheritance matches `DefaultTextStyle`.
- [x] Task 26: Refactor the example's shared card to rely on inherited typography and document the cascade precedence in all three READMEs.

### Phase 8: Interaction states & accessibility
- [x] Task 27: Add `BoxState` (`hover`, `focus`, `pressed`, `disabled`), `Box.stateStyles`, `Box.enabled` and `computedStyleFor(BoxState)`; `isInteractive` respects `enabled`.
- [x] Task 28: Add `BoxRole` and `BoxSemantics` tokens (`role`, `label`, `checked`) to core with equality and tests.
- [x] Task 29: Flutter renderer — `Focus` and keyboard activation (Enter/Space), pressed tracking, `Semantics` role/label/enabled, and no hover or pointer cursor when disabled.
- [x] Task 30: Jaspr renderer — one scoped class with `:hover` (inside `@media (hover: hover)`), `:focus-visible`, `:active` and `[aria-disabled="true"]` rules plus `role`, `aria-label`, `tabindex` and `keydown`.
- [x] Task 31: Express the example's disabled submit button with `enabled`, `stateStyles` and `semantics`, replacing the hand rolled tint and the nulled `hoverStyle`, and update the README mapping tables.

### Phase 9: Text input parity
- [x] Task 32: Core — `InputType` enum and `TextInputNode.inputType`, `enabled`, `readOnly`, `autofocus`, `onFocusChanged` and `semanticsLabel`.
- [x] Task 33: Flutter renderer — `keyboardType`, `autofillHints`, `enabled`, `readOnly`, `autofocus`, focus listener and `Semantics` label.
- [x] Task 34: Jaspr renderer — `type`, `disabled`, `readonly`, `autofocus`, `aria-label` and `focus`/`blur` listeners.

### Phase 10: Host embeds
- [x] Task 35: Core — `abstract class EmbedNode extends UINode` with an `Object get payload`, documented as the escape hatch for host specific content.
- [x] Task 36: Flutter — `FlutterWidgetNode(Widget)` accepted by `renderFlutter`, with an `UnsupportedError` for foreign payloads.
- [x] Task 37: Jaspr — `JasprComponentNode(Component)` accepted by `renderJaspr` with the same contract.

### Phase 11: Public readiness
- [x] Task 38: Add the MIT `LICENSE`, per package `CHANGELOG.md` files and the `repository`, `homepage`, `issue_tracker` and `topics` pubspec metadata while keeping `publish_to: none`.
- [x] Task 39: Audit `dart doc` for all three packages, fix unresolved references and undocumented public members.
- [x] Task 40: Add a cross target parity fixture, later superseded by the library level contract of Phase 13: the example no longer carries presentation fixtures of its own.
- [x] Task 41: Add a GitHub Actions CI workflow (format check, `dart analyze` and all three test suites).
- [x] Task 42: Final workspace verification (format check, `dart analyze`, all six suites, `dart doc`), README refresh and `TASK_PLAN.md` completion.
- [x] Task 43: Give an unset `direction` one meaning: `BoxStyle.resolvedDirection` resolves it to `Axis.vertical` and both renderers derive the flex layout from it, so `gap`, `mainAlign`, `crossAlign` and a child's `flex` apply to every box instead of silently doing nothing, and a direction-less box stops stacking in Flutter while flowing inline on the web.

### Phase 12: The two renderings look the same
- [x] Task 44: Flutter renderer — render a text input without Material's chrome (`InputDecoration.collapsed`), so the field is as tall as its line box and the surrounding box decides how it looks, and export the widget each node renders to.
- [x] Task 45: Jaspr renderer — strip the browser form chrome from `<input>`/`<textarea>` (`border: none`, no padding, no background, no focus ring, inherited colour) and the UA underline from `<a>`, so a field and a link look like their Flutter counterparts.
- [x] Task 46: Example shared — one line height on the card typography and the two fields wrapped in a shared `Box`, so both targets draw the same bordered field; the font family stays a host decision, because a CSS font stack is not a Flutter font family.
- [x] Task 47: Jaspr host — render the example through a `Document` that gives the page's `100%` box a height to resolve against (`html, body { height: 100%; margin: 0 }`), and regenerate `build/index.html`.

### Phase 13: One contract for every token
- [x] Task 48: `unibox_testing` — a dev-only package holding the contract: `BoxAppearance` (direction, alignment, gap, padding, margin, width, height, background, radius, border), `differencesFrom` (absent equals zero, a border colour only counts when a border is drawn) and `boxCases`, one case per token plus one with all of them, with a suite that checks the table itself.
- [x] Task 49: Both renderer suites — render every case and read the appearance back out of the rendered output (`test/support/appearance.dart` walking the widget tree in `unibox_flutter`, parsing the emitted CSS in `unibox_jaspr`), never out of the node tree, so a renderer that drops a token fails its own suite and neither target can be relaxed alone.
- [x] Task 50: Jaspr renderer — strip the browser's native focus ring from a field (`outline: none`), because the ring is drawn around the field inside the padding and border of the box that wraps it ("a box inside a box" on focus) and Flutter has no counterpart to it; a focused field is a state style, not platform chrome.
- [x] Task 51: Remove the example level parity fixtures (`CardParity`, both `visual_facts.dart` extractors, both `parity_test.dart`) now that the contract lives in the library, keeping the app level tests and moving the "fills the host surface" check into the Flutter app suite.
- [x] Task 52: Docs and CI — record the contract in the package, renderer and example READMEs, the CHANGELOGs, `design.md` and the workflow, alongside `dart test` for every package.


### Phase 14: A second page behind a navigation bar
- [x] Task 53: Example shared — split the palette and the typography out of the card into `theme.dart`, and add the tokens the second page needs (nav item, listing, price, map panel).
- [x] Task 54: Example shared — `ExamplePage` (`signup`, `apartments`), `ExampleLayout.wideBreakpoint` and `buildExamplePage({current, onNavigate, page})`: one frame with a navigation bar of boxes, one item per page, highlighted while its page is open and wired through `onTap` exactly like the form's opt-in.
- [x] Task 55: Example shared — `buildApartmentsPage({UINode? map})`: the listings in a three-part column, the map in a two-part column beside it, the page itself scrolling under the bar (`Overflow.scroll`, padding one level in so both renderers scroll the same content) and `buildExampleMap()` as a coloured panel.
- [x] Task 56: Example hosts — both keep the open `ExamplePage` next to the form state. Flutter answers the breakpoint with `MediaQuery.sizeOf` and passes the map or `null`; the Jaspr host always passes it inside a `WideOnly` component whose base rule is `display: none` and whose `@media screen and (min-width: 900px)` rule is `display: contents`, because a static render runs before a viewport exists and a hidden panel has to take the whole column with it. Neither rule is inline, or it would beat the media query.
- [x] Task 57: Example Jaspr — `buildExampleDocument({page})` and `bin/build.dart` write one static file per page (`index.html`, `apartments.html`), since a static export cannot keep the navigation state; resizing `apartments.html` is what exercises the breakpoint without a client bundle.
- [x] Task 58: Tests — shared (`page_test`, `apartments_test`, the signup page in `signup_card_test`, a shared `test/support/tree.dart` with the recording host), Flutter (navigate, come back with the form intact, map beside the list, no map on a narrow surface, scroll under the bar) and Jaspr (listings, one scroll region, media query, no map on the card page, `role="link"` items, the export's second file).
- [x] Task 59: Docs — `example/README.md`, the root `README.md` (which still described a fixture the example no longer carries), `design.md` §5.4 and §5.6: the size of the surface is host business, so a breakpoint is not a token.

### Phase 15: Structure and semantics (headings, landmarks, accessibility state)
- [x] Task 60: Core — `TextNode.headingLevel` (`int?`, 1 to 6, asserted in the constructor) with the doc rule that a heading is a *text*: it renders `<h1>`–`<h6>` on the web and a `Semantics(header: true, headingLevel: n)` in Flutter, so both targets state the same level. `BoxRole.heading` stays for a heading that cannot be written as one text node.
- [x] Task 61: Core — `BoxElement` (`div`, `main`, `nav`, `header`, `footer`, `aside`, `section`, `article`, `form`, `figure`, `ul`, `ol`, `li`) as `BoxSemantics.element`, so a box can say what it *is* and not only what it looks like. `validateTree` reports a `li` whose parent is not a `ul` or an `ol`, which is the one combination HTML forbids.
- [x] Task 62: Core — `BoxSemantics` gains the accessibility state both platforms expose: `expanded`, `selected`, `hidden` and `liveRegion`, wired through `copyWith`, equality and `toString`, with node tests.
- [x] Task 63: Flutter renderer — a heading becomes `Semantics(header: true, headingLevel: n)` around the `Text`; the elements Flutter has a role for become `SemanticsRole.list` (`ul`, `ol`), `SemanticsRole.listItem` (`li`) and `SemanticsRole.form` (`form`); the four state tokens become the `Semantics` flags of the same name, and `hidden` also excludes the subtree from the tree.
- [x] Task 64: Jaspr renderer — a heading renders `<h1>`–`<h6>` with the user agent styles cancelled (`margin: 0` and inherited size and weight) so the tree's typography still governs; an element renders its own tag rather than a `<div>` (`<main>`, `<nav>`, `<ul>`, `<li>`, `<figure>` with its margin reset, ...), `role` is only emitted for the roles an element does not already imply, and the four state tokens become `aria-expanded`, `aria-selected`, `aria-hidden` and `aria-live`.
- [x] Task 65: Tests — core (level range, element defaults, `li` validation, state equality), Flutter (heading semantics, roles, flags, hidden subtree) and Jaspr (heading tag and reset, element tags, implied-role suppression, `aria-*`), plus the conformance suite kept green.
- [x] Task 66: Example — the pages become a real document: `main`, `nav`, `header`, `footer`, `h1` for the page title and `h2` for a section, `figure` for the map, and a live region for the form status, so the export can be read as an outline by a crawler and a screen reader.
- [x] Task 67: Docs — `design.md` (a new §5.8: what the model says about semantics, what each target can express, and what stays host work), the package READMEs (mapping tables for elements, headings and state), the changelogs, and the SEO notes that still say a heading is only ARIA.

### Phase 16: What a real page still needs
- [x] Task 68: A field can state what a form needs from it: `TextInputNode.required`, `.invalid` and `.description`, rendered as `aria-required`, `aria-invalid` and `aria-describedby` (plus `Semantics.isRequired` in Flutter), so a validation message can be attached to the field it belongs to instead of sitting in a status box.
- [x] Task 69: A box can be the current page of a navigation: `BoxSemantics.current` (`page`, `step`, `location`), rendered as `aria-current` and announced as the selected item of a set in Flutter.
- [x] Task 71: Core — `BoxElement.figcaption`, the caption of a `figure`, with `validateTree` reporting a caption outside one, and the example naming its map with it.

Tasks 70, 72 and 73 were **discarded**; `Deferred` records why.

### Phase 17: A component of the user's own, on both targets
- [x] Task 74: Core — `EmbedNode` becomes plural and platform-agnostic: it carries `List<Object> implementations` (one per renderer that can draw it) and an optional `child` the implementations wrap, `children` exposes that child so validation reaches it, `payload` stays as a deprecated first-implementation getter, and `validateTree` reports an embed that carries no implementation at all.
- [x] Task 75: Flutter renderer — dispatch an embed by payload type instead of by node class: a `Widget` is drawn as it is, a `FlutterWidgetEmbedBuilder` receives the rendered child, two drawable implementations and none are both reported with the types this target accepts, so a node class the library has never seen renders here.
- [x] Task 76: Jaspr renderer — the same for a `Component` and a `JasprComponentEmbedBuilder`, so one node with one implementation per renderer is the whole extension point.
- [x] Task 77: Tests — core (implementations, wrapped child, the deprecation, the empty-embed error), Flutter and Jaspr (a user defined embed node renders, a builder receives the child, both failure modes).
- [x] Task 78: Docs — the three package READMEs state that the model names no platform and how a renderer picks its implementation, `design.md` §5.8 records that this escape hatch is outside the contract by construction, and the changelogs carry the breaking change.

### Phase 18: The portable route to effects (the ink question)
- [x] Task 79: Core — `BoxStyle.transition` (duration and curve) as a token, animating the visual tokens a state can change (background, border, radius, shadow, opacity, transform) and never the layout ones: CSS writes the `transition` on the element, Flutter swaps in the implicit animation widgets, and the conformance package grows the case shape an animation needs.
- [x] Task 80: Core — `BoxStyle.opacity` and a static `transform` (scale, translate, rotate) so a press can shrink a control and a row can fade in; both are native on both targets, and together with Task 79 they are the whole of "an effect that is not an embed".
- [ ] Task 81: Core — token keyframes with a semantic trigger (`press`, `hover`, `autoplay`): stops of the visual tokens, rendered as `@keyframes` plus `animation` and as a `TweenAnimationBuilder` keyed on the trigger. This is what lets a user build a ripple out of a clipped circle in a `Stack`; pointer-position-driven effects stay out of scope on purpose.

### Phase 19: Production ready — effects, composition and a release pass
- [x] Task 82: Core — `BoxProperty` (`backgroundColor`, `borderColor`, `borderRadius`, `shadow`, `opacity`, `transform`) and `BoxTransitionPart` (properties, duration, curve, delay), so a transition can ease one part of a look before another. `BoxTransition` keeps its single duration and curve as the base and takes `parts` that override it per look; `validateTree` reports the one combination the renderers cannot honour (paint properties with different timings, which would need layered decorations) and points at nesting a box instead.
- [x] Task 83: Flutter renderer — clip a rounded box to its radius. `Overflow.hidden` and the scroll viewport clip with `ClipRect` today while the web clips to `border-radius`, so a rounded card that hides its overflow is rounded in the browser and square in Flutter. The conformance table gains a case that reads the clip back.
- [x] Task 84: Both renderers — honour the parts. Jaspr writes one `transition` entry per look, with `transition-delay`; Flutter groups the looks by timing and animates each group with its own `Interval` on a shared total, so a delay costs no controller and the paint stays one tween.
- [x] Task 85: Core — `styles: List<BoxStyle>` on `Box`: the bags merge left to right, flat parameters win over all of them, and `style:` becomes sugar for a one-element list (deprecated). This is the composition half of the "class" idea without a name registry: no lookups, no specificity, `const` and checked.
- [x] Task 86: Both renderers — apply the list in one place (they read `computedStyle`), with tests for the merge order and a conformance case.
- [x] Task 89: Production pass — every package's pubspec metadata and description, `dart doc` clean for all four, the README node reference updated with the new tokens, CHANGELOG entries for everything unreleased, and a `RELEASE.md` checklist that states the one deliberate step (`publish_to: none` off, version bumped) as a decision for the maintainer rather than something CI does.

Tasks 87 and 88 — a triggered keyframe timeline and the ripple built out of it — were **discarded**; `Deferred` says why.

### Phase 20: A design system you can opt into (Material typography)
- [x] Task 90: New package `unibox_material` — pure Dart, depending on `unibox_core` alone: `MaterialTypeRole` names the fifteen roles of the Material 3 type scale, and `MaterialTypography` states each one as a `const BoxTextStyle` with the specification's size, weight, letter spacing and line height (the line height as the division its pixel height implies, `64 / 57` for display large), plus a `styles` table and an `of(role)` lookup. Each role is a complete style so it resets the tokens it does not share; `color` and `fontFamily` stay unset because a colour scheme and a font file are the application's.
- [x] Task 91: Tests and docs — the suite holds every role to the specification (size, tracking, weight and the `fontSize * lineHeight` line box), the table to every role in order, the package to `unibox_core` plus the SDK, and the exports to names a core import leaves alone; the package README and changelog, `design.md` §5.9, the root README, `RELEASE.md` and the CI workflow all take the new package in.
- [x] Task 92: Decision record — a design system is values, not node types: the package README gains the "presets: values, not classes" recipe (a `const` catalogue in the app, the four line subclass it replaces, and why the package exports none), and `design.md` §5.9 states the three rules behind it (no wrapper nodes, one `style` per text, presets are values) plus the cost asymmetry that keeps the token vocabulary the stable layer.

### Phase 21: Material components
- [x] Task 93: `unibox_material` — `MaterialPalette`: the Material 3 colour roles as `const BoxColor` values (`primary`, `onPrimary`, `surface`, `onSurface`, `onSurfaceVariant`, `outline`, `error`, ...), with a light and a dark instance, next to `MaterialTypography` and following its shape. The palette lives here and not in `unibox_core` because the roles are Material's vocabulary: a core theme would put one design system's words into the model every renderer carries. A test pins the roles and the pairs that have to contrast.
- [x] Task 94: `unibox_material` — `MaterialFieldStyle` (text, hint, fill, border and error colour, derived from a palette in pure Dart) and the field component, `MaterialTextField` (filled, static label). The Flutter renderer passes those colours to a Material `TextField` explicitly instead of letting it inherit the host's `MaterialApp` theme, and the Jaspr renderer writes the same values as CSS, so the field is the same on both targets by construction. The caret, the selection and the focus ring stay Material's on one side and are documented as approximate on the other: the first entry in a "what stays approximate" section of the material README. Built as colours derived from the palette inside the node rather than as a separate `MaterialFieldStyle` value, and as an outline with the label above the field rather than a filled field with a floating label: the float is a timeline the model does not have. The approximate part is written on the class and in the material README.
- [ ] Task 95: Logical directions — `TextAlign.start`/`end` and start/end insets, mapped to `TextAlign.start`/`end` and `EdgeInsetsDirectional` in Flutter and to `text-align: start`/`end` and `padding-inline-start`/`end` in CSS, so a host that sets `Directionality` or `dir` gets a mirrored tree without the model ever knowing the direction.
- [ ] Task 96: Host duties — the material README states the two wirings a Material application owns: one palette value feeding both the tree builders and `MaterialApp(theme:)`, and one direction feeding both the tree and the host's ambient direction. There is no `PageNode` and no core theme behind this, and the README says why.
- [x] Task 97: `MaterialCard` — the first component node, and the line it draws: a card owns children and a surface, so it is a `Box` with the card's defaults (16 of padding, a white surface, a 12 pixel radius, elevation level one as the one `BoxShadow` the model has, `bodyMedium` for the text inside) rather than a `TitleText`-style node. Every token is a parameter, the layout and interaction of a box come through, and neither renderer knows the class; the renderer suites gain the test the card rests on (a node that extends `Box` renders as that box), and §5.9, both agent rule files and the package README state where a design system stops being a value. It takes its colours from parameters until the palette of Task 93 exists, which then becomes its default.
- [x] Task 98: `unibox_material` — `MaterialListTile`: the Material 3 list tile as a node that extends `Box` — a row filling its width, 16 between its parts and 16 of side padding, the one and two line heights and their dense pair, `bodyLarge` for the title and `bodyMedium` in `onSurfaceVariant` for the subtitle, black at 8% and 12% for the state layers, and the button role when the tile can be tapped. It needed no palette because the three values a scheme would carry are documented constants, which is why it could land before Task 93.

### Phase 22: A node that owns its state
- [x] Task 98: Core — `Store<S>` (`state`, `addListener`/`removeListener`, `onMount`/`onUnmount`, `dispose`) and `StatefulNode<S, C extends Store<S>>`: the node carries a factory for its store and a view that returns one `UINode` for a state, never the store instance, so the tree stays a description; `createStore()` and `viewFor(state, store)` are the untyped boundary a renderer uses. A subclass with a narrower store type has to be reachable as `StatefulNode<Object, Store<Object>>`, which a test pins.
- [x] Task 99: Core — `StateStore<S>`, the ready made `Store`: one immutable state value, a guarded `state` setter (an equal state notifies nothing, and a disposed store ignores a late publish), its own listener list, and the `onMount`/`onUnmount` hooks a renderer calls. It stays in the model rather than in a package of its own: core keeps its no-dependency rule, and one store still runs in Flutter, on the server and in the browser. Tests cover the notification rule, self-removal during a notification and the lifecycle defaults.
- [x] Task 100: Flutter renderer — `FlutterStateful`: create the store on mount, subscribe, call `onMount`, rebuild on a notification, `onUnmount` and dispose on unmount, and render the view's tree through `renderNode`. Tests: a tap publishes a state and the tree changes; a tap starts a request and the pending tree is replaced by the result; the store is mounted once, kept across an equal rebuild, and disposed and unsubscribed on unmount.
- [ ] Task 103: Example — the listings page becomes a `StatefulNode` (a request and the pending spinner that replaces it), hosted by the Flutter app; the Jaspr host keeps the static page until Task 104.
- [x] Task 104: Jaspr renderer — the client build: `JasprStateful` splits the server path that only reads the first state from the browser path that subscribes, calls `onMount`, rebuilds and disposes. The build is a hand-written entrypoint (`web/main.client.dart`, three lines of host code) compiled by `dart compile js` in `tool/site.sh`, not `jaspr_builder` and not codegen: the page is one component, so no `@client` marker has to be matched against a server tree and nothing is generated into the repository. Both sides build the same root (`buildExampleRoot`) and class names are content hashes, so the markup the client draws is the markup the server wrote — a static page that survives its own runtime. Checked in Chromium against the built site: the runtime boots, the tree renders, and a press on the barrier closes the dialog.
- [x] Task 105: Docs and workspace — `design.md` §5.10 (a stateful node and what a store is), the package READMEs, `AGENTS.md`/`.clinerules` vocabulary (no bloc words: the library has stores and states, not cubits and events), `tool/verify.sh` and CI stay in step.

### Phase 23: Overlays as nodes
- [x] Task 106: Core — `OverlayNode` and `OverlayAlignment`: content drawn above the page, with `onDismiss`, `barrierDismissible`, `barrierColor` and `alignment`. The node says policy; being in the tree is being shown, so no view gains an overlay slot and no `open` flag exists. `validateTree` reports the one combination that does nothing: a dismissible barrier with no `onDismiss`.
- [x] Task 107: Flutter renderer — `FlutterOverlay` presented through an `OverlayPortal` on the root overlay: barrier in the node's colour, `Escape` and a barrier press calling `onDismiss`, a closed-loop `FocusScope` with the previous focus restored on exit, and the layer announced as a route. It takes no room in its parent and needs an `Overlay` ancestor. Tests cover the barrier, both dismissals, an inert barrier, content presses, all three alignments, focus in and back.
- [x] Task 108: Jaspr renderer — an overlay is drawn as a fixed layer with the barrier and the alignment, with `role="dialog"` and `aria-modal="true"`; it is never drawn in the flow of its parent. A press on a dismissible barrier closes it once a client runtime listens; `Escape` and focus wait for Task 112.
- [x] Task 109: `unibox_testing` — `OverlayAppearance` (barrier colour, alignment) and `overlayCases`, with a conformance test in each renderer suite: Flutter reads the barrier and the `Align` out of its widget tree, the web reads the fixed layer and the barrier out of its CSS.
- [x] Task 110: Docs and example — `design.md` §5.11, the `OverlayNode` section of the root README, the core and both renderer READMEs, the rules in `AGENTS.md` and `.clinerules`, and the four changelogs. The example's sign-up form becomes `buildSignupDialog`: a dialog over the listings instead of a page, built by each host while it is open, so the two documents export one state each.
- [x] Task 111: `unibox_material` — `MaterialDialog` and `MaterialBottomSheet` as `OverlayNode` subclasses (surface, radius, padding, max width, body type), plus the `MaterialInkWell` and `MaterialTextField` that came with the overlays PR.
- [ ] Task 112: Web interaction — a press on the barrier and `Escape` dismiss the layer. The key is heard on the *document* while the overlay is up, because nothing inside a freshly opened overlay holds focus and a listener on the layer only sees a keystroke that starts inside it; two overlays open at once therefore both hear it. Focus containment — moving focus in, trapping it, restoring it on exit — remains open.
- [x] Task 113: Example — the page is one `ExamplePageNode`, a `StatefulNode<ExampleState, ExampleStore>`: the form, the open destination and the dialog are store state, the view is the frame with the dialog layered in, and each host is one `main.dart` that supplies only the surface, the link policy and the panel. The dialog is a node in the store's tree, so nothing outside the page decides whether it is open.
- [x] Task 114: Example — the rest of the host is gone: the listings page lost its map panel, so no host measures the window, `WideOnly` and `ExampleLayout` are deleted, and the Flutter host is a surface, a link scope and one `FlutterStateful`. The Jaspr host keeps the component in `lib/main.dart` and the page it is served in (`lib/document.dart`), so the file a reader copies holds the host and nothing else.
- [x] Task 115: `ImageNode` — the four fields only a browser reads: `srcSet` (a width to URL map, resolved to the `srcset` attribute narrowest first so the order is the model's), `sizes`, `loading` and `fetchPriority`, with `validateTree` reporting a candidate of no positive width and a `sizes` that names nothing. The web renderer writes all four as attributes and adds a finite `width`/`height` as element attributes so the browser reserves the box before the fetch; the Flutter renderer loads `src` and the gap is recorded in its README, because a `ResizeImage` would need the laid-out width a rendering does not have.
- [x] Task 116: `unibox_jaspr` — the stylesheet pass: `UniboxStylesheet` collects one class per distinct set of declarations, `renderJaspr` writes them as a single `<style>` after the tree, and boxes, texts, images, fields, stacks, links and overlays carry a class instead of an inline style. A component rendered on its own still writes inline, which is what a single node can do correctly. The test harness reads a class's declarations back, so every existing expectation kept its meaning; three tests that pinned the old inline/scoped split now pin the new contract, and five new ones cover the deduplication itself. On the site build this took 224 of 224 elements from inline to classed and left 73 rules, and it ended a duplication the class names had hidden: a state-styled box emitted its own `<style>` element, so the listings page came to twelve `<style>` elements for three classes, one of them restated twelve times, and now has one sheet. Two tests pin both halves — six identical state-styled boxes share one class and one rule each, and six rendered without a sheet still repeat theirs.
- [x] Task 117: Colour roles — `BoxColor.role(Enum)` with an `UniboxTheme` of values, `resolve` on every token that carries a colour, and a `validateTree` that reports a role no theme answers. The web renderer writes `var(--unibox-color-<name>)` in the class rule and the theme once in a `:root` block — every role, used or not — so a host stylesheet or a dark-mode block outranks the tree; the Flutter renderer resolves each role while building, through `UniboxThemeScope`. The example's palette became an `ExampleColor` enum and one theme value, three boxes name roles, both hosts install the theme, and the exported document overrides five roles under `prefers-color-scheme: dark` without touching a node. Found and fixed on the way: an overlay's content sits on the root overlay, outside the tree, so it has to be handed the theme explicitly.
- [x] Task 118: `unibox_material` — `MaterialColorRole`, the twenty roles of the specification, and `MaterialPalette.lightTheme`/`darkTheme`, so every component names a role instead of holding a colour: `MaterialCard`, `MaterialListTile`, `MaterialInkWell`, `MaterialTextField`, `MaterialDialog`, `MaterialBottomSheet` and `MaterialIcon` lost their `palette:` argument (a role is the indirection it provided) and are restyled by whichever theme the host renders with. The palette test now checks that both schemes answer every role, and the example's site documents pass `MaterialPalette.lightTheme`.

### Phase 25: Reflow
- [x] Task 118: Core — `GridNode`: equal columns whose count follows the width of the box, with `minItemWidth`, an optional `maxColumns` cap and a `gap`, and `columnsFor`/`cellWidthFor` as the arithmetic. `validateTree` reports a grid child with a `flex`, a finite `width` or an infinite `height`, an image whose height would wait for the file unless it has a finite height or a definite ancestor, and parameters that leave no column.
- [x] Task 119: Flutter renderer — `FlutterGrid` reads the constraints of the grid, asks the node for the count and the cell width, and lays out rows of fixed-width slots with empty slots for a short last line; no `Expanded`, no `MediaQuery`, one column at `minItemWidth` when the width is unbounded. Tests sweep 250, 375, 600, 900 and 1280, the empty tracks of a short last row, a zero gutter and the unbounded case.
- [x] Task 120: Jaspr renderer — one `div` with `display: grid`, `align-items: start`, the gap and `repeat(auto-fill, minmax(min(100%, max(minItemWidth, (100% - (maxColumns - 1) * gap) / maxColumns)), 1fr))`; no media query and no script, so the server render and the hydrated page cannot differ. Tests pin the declaration, the uncapped form, a fractional minimum and the reading order.
- [x] Task 121: Material field — `TextInputNode.padding` (core, both renderers) and `MaterialTextField` as the filled Material 3 variant: fill, 4 pixel radius, a bottom line as a shadow (1 → 2 pixels on focus, error when invalid), the label inside the fill, the padding on the input so the whole field takes focus, 38% opacity when disabled. The outlined variant is refused: its label floats into a notch cut in the border, and a uniform `BoxBorder` cannot be cut.
- [x] Task 122: Docs — `design.md` §5.6 (a grid is the second layout engine, and why it is admissible where tables were refused) and §5.13 (the rule, the clamp, the cap, the last-row rule and the measurements), the root and core READMEs, both renderer READMEs, `AGENTS.md`/`AI_INSTRUCTIONS.md`, and the three changelogs. The declaration was measured in Chromium and WebKit 18.2 at 250, 375, 600, 899, 900, 901, 1280 and 1440: counts and gutters match the model exactly, cards to the 1/64 pixel a browser lays out with.

- [ ] Task 123: Example — hold at 360 logical pixels without a breakpoint: the card's fixed `width: 380`, the gallery's `width: 720`, `320` and `360` rows and the showcase's two frames become fluid (`width: double.infinity`, `maxWidth`, and a `GridNode` whose `minItemWidth` stacks the frames below two columns). Measured at 360 the navigation clips, the sign-up dialog is wider than the viewport, the showcase puts both frames in one row and the gallery's specimens overflow — every one of them a fixed width, so every one is a sizing fix, not a query. `design.md` §5.15 records why no breakpoint is needed.

### Phase 26: A width that dresses a node differently

The listings page: cards in a grid with a map beside them on a wide surface, and a
column of cards with a floating button that opens the map as an overlay below 900
logical pixels. `design.md` §5.15 holds the reasoning; these are the pieces.

- [ ] Task 124: Core — `Box.visibleFrom` and `Box.visibleUntil` as layout tokens of `BoxStyle` (a half-open width range, both optional), with `merge`, equality, `toString`, the flat parameters, and `validateTree` reporting a range that can never show (`visibleFrom >= visibleUntil`, a negative threshold). The child is never removed: the token is a *style*, so the node stays in the tree, in the DOM and in the crawl. A boolean `visible` is deliberately not added — hiding a subtree because of **state** is the view's job, and the view already omits it.
- [ ] Task 125: Jaspr renderer — the box declares `container-type: inline-size` and the threshold becomes one `@container` block: mobile-first, so the base rule is the narrow layout and the query adds the wide one, and a browser without container queries still renders the base. Measured in Chromium for its `@container` support. Tests pin the declarations, the base rule, both directions, and that removing the threshold removes exactly its rule.
- [ ] Task 126: Flutter renderer — `LayoutBuilder` over the box's own constraints (the place `FlutterGrid` already measures, and never `MediaQuery`), `Visibility` with the subtree kept in the element tree, so a hidden box takes no room and keeps its state.
- [ ] Task 127: `unibox_testing` — `BoxAppearance.visibleFrom`/`visibleUntil`, read back from the CSS of the web renderer and from the widget tree of the Flutter one, in the "every token at once" case.
- [ ] Task 128: Example — the map returns to the listings page as the wide-only column, the grid takes `maxColumns: 2` beside it, and below 900 a floating button opens the map as an `OverlayNode` (state, not width). Four widths are checked in both renderings, and the DOM is compared between the widths to prove it is identical.
- [x] Task 129: `unibox_material` — `MaterialInkWell` returns as a state layer, now that the palette names the three layers: hover, focus and press as roles, a 100ms fade, the button role when it can be tapped, and no surface of its own, so the filled box goes around it. The gallery uses it for its buttons and its Dialog section is a `DialogDemo` `StatefulNode` whose button opens a real `MaterialDialog` — which needed two browser fixes: `JasprStylesheet` keeps the sheet in `<style id="unibox-styles">` in the head and appends a look a redrawn subtree registers (before, a dialog opened by a store arrived with no `position: fixed` layer), and the overlay hears `Escape` on the document. `sitePageForPath` also answers a page whose document is linked as `index.html`, which the runtime used to render as the home page.

### Phase 24: Material fidelity
- [x] Task 116: Audit the Material components against the Material 3 specification and fix the gaps: card variants on the palette, list tile padding and palette colours, text field minimum height, focused outline, hover and disabled states, dialog content and action colours, a full-width bottom sheet with a drag handle and an upward shadow.
- [x] Task 117: `unibox_material` — `MaterialIcon`: a glyph of an icon font in a square `Box`, by codepoint or by ligature name. A codepoint that comes from a const `IconData` is what the Flutter tree shaker can subset (10.7 MB became 3.6 kB in the check), a ligature name ships the whole font, and a web export serves whatever subset the host puts next to its `@font-face`; the README states the recipe and the Symbols codepoints.

## Decisions

- **License:** MIT, at the root and in every package.
- **Font family:** a `BoxTextStyle.fontFamily` names one family, the way Flutter
  and CSS both read it; a comma separated *stack* is a CSS construct with no
  Flutter counterpart, so it belongs to the host (`MaterialApp` theme on one
  side, a document rule on the other) and not to the tree.
- **Platform chrome:** neither renderer keeps the decoration its platform adds to
  a control (Material's field underline, the browser's input border, focus ring
  and link underline). A control looks the way the tree says it looks, which is
  what makes the same node render the same on both targets.
- **Where conformance is pinned:** in `packages/unibox_testing`, not in
  `example/`. The contract is a property of the renderers, so it is checked by the
  renderer suites against boxes they render themselves; an example can only show
  that one card happens to look alike, and it changes whenever the card does. The
  example keeps app level tests and drops the fixture it used to carry.
- **Publishing:** publish ready but unpublished. Every package carries a
  `CHANGELOG.md`, a `LICENSE` and the repository metadata, while `publish_to:
  none` keeps `dart pub publish` from leaving the workspace by accident. Cutting
  a release means removing that one line per package.
- **Navigation:** a page switch is a `Box.onTap` in the tree and state in the
  host, like every other interaction. A router per target would have been the
  alternative, and it would have made the two navigations two different things —
  the tree would describe a page and the hosts would disagree about where it
  lives. The cost is that a static export cannot switch pages, which is why the
  example writes one file per page.
- **Responsiveness:** the breakpoint is host state, not a token. A tree that needs
the width takes it as a parameter and each host answers for itself — Flutter by
measuring the window, a web host by asking CSS. The example used to carry a map
panel to demonstrate it; the panel is gone, because a host that measures was the
heaviest thing left in it, and the rule stands for an application that has one.
- **State:** a `StatefulNode` creates a `Store`; the store publishes an immutable
  state and the view is a pure function of it: one tree per state. The node never
  holds the instance, so the tree stays a description; `onMount` is where work
  starts, so a server render can draw the first state without running it. The
  vocabulary is the model's: a node, a store, a state and a view, with no events,
  cubits or blocs. The store is pure Dart in the core: `StateStore` keeps its own
  listener list, so the model keeps its no-dependency rule, and a state layer per
  target — the drift this project exists to remove — never appears. A view draws
  one tree; a modal is not modelled yet, which is in Deferred.
- **Design systems are packages:** the Material 3 type scale lives in
  `unibox_material`, not in `unibox_core` and not in a renderer. The core keeps
  one neutral default and no brand, a package of `const` tokens is what an
  application opts into, and a second system costs a second package instead of a
  mode in the core. The renderers stay unaware of all of them, which is what lets
  a tree use Material's scale on both targets without either host importing
  Material. Presets are values, not node types: a `TitleText`-shaped wrapper stays
  in the application, because a look baked into a node type cannot read a theme and
  the published API is the part that cannot be withdrawn cheaply. A component that
  owns children is the other kind, and it is a node built from the node that
  already draws it — `MaterialCard` extends `Box`, so it costs no renderer and no
  conformance case.

## Deferred

Deliberately out of scope for this pass, with the reason they were left:

- **mdui / Material web components as the Material implementation**: not adopted,
  and `design.md` §5.6 records why. A design system here is values plus nodes
  (`unibox_material`, `unibox_core` alone), so both renderers draw it and the
  conformance table can hold it; pairing a Material web component on the web with a
  Flutter widget on Flutter would put every design-system component outside the
  contract, add a fourth token layer (`--md-sys-*`, `--mdui-*`), and require a JS
  bundle for pages that render today without one. `@material/web` is also in
  maintenance mode pending new maintainers. The embed door stays open per component,
  for the behaviour-heavy and unportable ones.
- `Box.onScroll` and scroll position: needs a shared scroll model that neither
  `SingleChildScrollView` nor the browser state exposes the same way.
- A focus frame around a field: the browser's native ring is stripped (it sits
  inside the padding of the box around the field), so a focused field only shows
  its caret. Drawing a frame from the tree needs a `focus-within` state — Flutter
  would listen to descendants of a `Focus`, the web needs `:has(:focus-visible)` —
  which is a state model decision, not a token.
- `ImageNode.onError` / `onLoad`: callbacks that only make sense per target, and
  an embed covers them today.
- A tab bar (`BoxRole.tab` / `BoxRole.tablist`). `role="tab"` promises behaviour, not
  just a name: arrow keys between the tabs, a roving `tabindex` so the strip is one tab
  stop, and a panel wired with `aria-controls`. A box activates with `Enter`/`Space`
  and knows no arrow keys, on either target, so the role alone would make a reader
  hear "tab" and find the arrows do nothing — worse than saying nothing. A strip built
  from `BoxRole.button` plus `BoxSemantics.current` already says which item is the
  active one, and that is valid ARIA. Doing it properly needs a roving-focus model in
  both renderers first; **discarded** until a real tab bar asks for it.
- Tables (`BoxElement.table`, `.tr`, `.th`, `.td`). Not a token but a second layout
  engine: every box is a flex container — the web renderer writes `display: flex` on
  every element — which breaks both the layout and the semantics of a real table that
  needs column sizing, collapsing borders and header association. Flutter has the
  roles (`SemanticsRole.table`, `.row`, `.cell`) but no layout for them. **Discarded**;
  an embed covers the rare case until the model grows a second layout mode.
- A crawlable path between the exported pages. `LinkNode` already renders a real
  `<a href>`; what is missing is a decision in the *example*, not an API: real links
  mean a full page load on the web, which is right for a static site and wrong for the
  Flutter host's in-app navigation, and "in-app navigation with real urls" is a
  router — an application concern each host answers differently. **Discarded** from
  the library; the example README states the trade-off.
- A `PageNode` and a `BoxTheme` in core. A page node would carry a title, a
  language and a direction, and only the third is more than a document fact: RTL
  mirrors rows and flips `start`/`end`, so it changes the layout. But both platforms
  already resolve a logical direction natively — `Directionality` in Flutter, `dir` on
  the web — so setting it is a host duty like the font file, and the tree only has to
  speak logical tokens. A `BoxTheme` in core would be worse: `onPrimary` and
  `outline` are Material's words, and a design system is a package of values
  (`unibox_material`), not a concept the model has to carry. The outward projection
  that a core theme would have needed — `ThemeData` on one side, CSS variables on the
  other — is fifteen lines in a Material application, which is where it stays.
- A triggered keyframe timeline (`BoxAnimation`: `press`/`hover`/`focus`/`autoplay`
  or a host `play` key, with stops per look, rendered as CSS `@keyframes` and a
  Flutter `TweenSequence`). The portable part of what it was for is already here:
  `BoxTransition` eases any look on its own timeline, `transform` and `opacity`
  paint without moving the box, and a rounded box clips to its radius — so a colour
  can settle and a scale follow it. What is left is a timeline with several stops,
  and a ripple is the only thing that asks for it: a ripple is intrinsically
  platform specific (Material's ink layer against a CSS animation), which is exactly
  what `EmbedNode` exists for — one node, both implementations, reviewed together.
  Building an animation engine before the first release, for an effect an embed
  already covers, would be the wrong order; revisit with a real screen that needs
  it.
- `onDoubleTap` / `onSecondaryTap`: not part of the pointer, keyboard and touch
  intersection the state model is built on.
- Generating `BoxStyle` code: 18 fields is still hand manageable; revisit above
  25.
- `UniboxTheme`: typography inheritance covers today's needs, and a theme layer
  needs a decision about token overrides first.
- A browser sweep in CI. The reflow declaration was measured in Chromium and WebKit 18.2 by
  hand (a probe page, a container per width, `getBoundingClientRect`); wiring it into CI needs a
  browser driver the repository does not carry, and the acceptance for the hydrated page waits
  for the client build (Task 104). **Deferred**; the numbers are recorded in `design.md` §5.13.
- A child that fills a `PositionedNode` whose four edges are set. Flutter hands it tight
  constraints, so it fills; the web positions a flex container whose child keeps its
  content height, so the example's ripple ink painted a zero-height layer and the
  button looked empty. It needs a fill rule in the model (or a cross-axis alignment
  that reaches the child) before the rippled button returns to the Material page.
- An icon subset for the web export. Flutter's `--tree-shake-icons` is a build feature of
  the Flutter target; a Jaspr export serves whatever font the host puts beside its
  `@font-face`. The subset has to be produced once — the Flutter build already writes it,
  or `pyftsubset` makes one — and copied into the static site. **Deferred**: the
  material README states the recipe, and the example carries no icons.
- A circular progress indicator. A ring needs an arc, and the model has no gradient, no
  per-side border and no clipping that punches a hole, so it cannot be composed from
  boxes; indeterminate, it also needs an animation the model does not have. A node is
  therefore the only way to describe one, and it was written for the overlays PR with
  Material's defaults in core, no conformance case and a debug `assert` for the range.
  **Discarded** until it carries no design-system numbers, `validateTree` bounds the
  value and `unibox_testing` pins the determinate ring; a linear bar needs none of this
  and is already expressible with two boxes and `flex`.
