# Unibox Design Blueprint

## 1. Intent & Architecture
Unibox provides pure Dart layout primitives that draw natively as Flutter widgets and render as HTML and CSS a crawler can read.

- **Workspace:** Dart 3.13+ workspace in `packages/`:
  - `packages/unibox_core`: Pure Dart AST & tokens. Zero dependencies (no Flutter, no web framework, no `dart:ui`).
  - `packages/unibox_css`: Depends on `unibox_core` only. The token-to-CSS mapping and the class hash the web renders from.
  - `packages/unibox_element`: Depends on `unibox_core` + `unibox_css`. The element plan: what each node becomes.
  - `packages/unibox_html`: Depends on `unibox_core` + `unibox_css` + `unibox_element`. Writes a fragment or a document.
  - `packages/unibox_flutter`: Depends on `unibox_core` + Flutter SDK.
  - `packages/unibox_material`: Optional design-system tokens and one component (the Material 3 type scale and `MaterialCard`). Depends on `unibox_core` only; no renderer depends on it.
- **Engineering Agency:** You have permission to diverge, adjust signatures, or simplify types where it makes sense, as long as the packages remain decoupled and work seamlessly across both platforms.

---

## 2. Shared Types & Tokens (`unibox_core`)

- **`BoxColor`**: Encapsulates 32-bit ARGB (`0xAARRGGBB`) with `.rgb()`, `.rgba()` and `white`, `black`, `transparent` next to the constructors. **`BoxColors`** is the palette an interface reaches for before it has one of its own (the grey ladder and the common hues, at the values Flutter's `Colors` uses for the same names); the hues cannot sit on `BoxColor` itself, where `red`, `green` and `blue` are the channel getters.
- **`BoxSpacing`**: Represents margin/padding (`all`, `symmetric`, `only`, `zero`).
- **Dimensions**: Standard `double?` for width, height, min/max dimensions.
  - Standard numbers (`width: 250`) represent logical pixels / px.
  - `double.infinity` represents expanding to fill available space (`100%` on web, `Expanded` / infinite constraints in Flutter).
- **Layout Enums**:
  - `Axis`: `horizontal`, `vertical`.
  - `MainAlign`: `start`, `center`, `end`, `spaceBetween`, `spaceAround`, `spaceEvenly`.
  - `CrossAlign`: `start`, `center`, `end`, `stretch`.
  - `Overflow`: `visible`, `hidden`, `scroll`.
  - `ImageFit`: `cover`, `contain`, `fill`.
  - `FontWeight`: `normal`, `medium`, `semiBold`, `bold`.
  - `TextAlign`: `left`, `center`, `right`, `justify`.
  - `TextOverflow`: `clip`, `ellipsis`.

---

## 3. Primitives to Implement (`unibox_core`)

All nodes extend `abstract class UINode`.

1. **`Box`** (Layout & Container):
   - **Flat layout props:** `direction`, `mainAlign`, `crossAlign`, `gap`, `flex`, `overflow`.
   - **Direction default:** an unset `direction` resolves to `Axis.vertical` (`BoxStyle.resolvedDirection`), so every box is a flex container on every target and `gap`, `mainAlign`, `crossAlign` and a child's `flex` never silently do nothing.
   - **Dimensions:** `width`, `height`, `minWidth`, `maxWidth`, `minHeight`, `maxHeight` (`double?`).
   - **Visuals:** `padding`, `margin`, `backgroundColor`, `borderRadius` (`double?`), `corners`
     (`BoxBorderRadius?` — the four radii, for a shape that is not round everywhere), `border`,
     `shadows`.
   - **Actions:** `onTap`, `onLongPress`, `onHover`.
   - **Tokens/Overrides:** Optional `style: BoxStyle?` and `hoverStyle: BoxStyle?`.
   - `computedStyle`: Helper that overlays explicit flat parameters onto `style`.
2. **`TextNode`**: `text`, `fontSize`, `fontWeight`, `color`, `textAlign`, `maxLines`, `overflow`.
3. **`ImageNode`**: `src`, `alt`, `width`, `height`, `fit`, `borderRadius`.
4. **`LinkNode`**: `url`, `child`, `newTab`, optional `onTap`.
5. **`StackNode`**: Container for layered children (`children: List<UINode>`).
6. **`PositionedNode`**: Direct child of `StackNode` (`top`, `right`, `bottom`, `left`, `child`).
7. **`TextInputNode`**: `value`, `placeholder`, `obscureText`, `multiline`, `maxLines`, `onChanged`, `onSubmitted`.

---

## 4. Platform Mappings

### Flutter (`unibox_flutter`)
- Provide `node.toWidget()` and `renderFlutter(UINode)`.
- `Box` maps to a `Row`/`Column`; an unset direction means a column.
- `Box` with `overflow: Overflow.scroll` wraps in `SingleChildScrollView`.
- `onTap` maps to `GestureDetector`.
- `onHover` maps to `MouseRegion`.
- `LinkNode` renders child with tap navigation.
- `StackNode` / `PositionedNode` map to Flutter `Stack` and `Positioned`.
- `TextInputNode` renders managed `TextField`.

### The web (`unibox_html`)
- Provide `toHtml(UINode)` for a fragment and `toDocument(UINode, title: …)` for a page.
- `Box` renders a `<div>` with `box-sizing: border-box`.
- Map layout to CSS flexbox (`display: flex`, `gap`, etc.); a box without a
  direction is a flex column.
- `width == double.infinity` maps to `100%`.
- `LinkNode` outputs a native `<a>` tag with `href` and `target`.
- `StackNode` renders `<div style="position: relative">`.
- `PositionedNode` renders `<div style="position: absolute">`.
- `TextInputNode` renders `<input>` or `<textarea>`.

---

## 5. API Conventions

These rules are part of the public contract: a change that violates them is a
breaking change even when it compiles.

### 5.1 Naming
- Nodes live in `unibox_core` and extend `UINode`.
- Every node but `Box` carries the `Node` suffix. The suffix answers Flutter,
  which consumes the tree: `Text`, `Image`, `Stack` and `Positioned` are all
  widgets, so four of six names would have to be qualified anyway and the family
  is better off uniform. `Box` has no Flutter counterpart and stays unsuffixed.
- Tokens are prefixed with `Box` (`BoxColor`, `BoxSpacing`, `BoxBorder`,
  `BoxShadow`, `BoxStyle`), enums are unprefixed (`Axis`, `MainAlign`, ...).
- Renderer side classes are prefixed with their target (`FlutterBox`, `FlutterText`, ...). The platform is the *package's* job, so the class
  says which one it belongs to and the model keeps one vocabulary: a `Box` is a
  `Box` in the tree, and each target names the thing that draws it. Both packages
  export the same shape — the entry point, the extension, the embed node and one
  class per node, all public, so a host or a test can address a rendered node
  without depending on its position. What the web renderer does not export is the
  link scope, because the web needs no hook: a `<a href>` navigates itself. A
  renderer package exports only those names and **never** re-exports
  The rule covers classes and typedefs alike: `FlutterWidgetNode` and
  `FlutterWidgetEmbedBuilder` are the Flutter-side names for the embed that
  carries a `Widget`, `HtmlEmbed` the web one, `FlutterLinkOpener` the signature a host implements to follow a
  link. Only functions are exempt, because they already name their target
  (`renderFlutter`) or extend a core type (`toWidget`).
  `unibox_core`, so a host file can import it next to `flutter/material.dart`;
  the `naming_test.dart` of each renderer package writes every export out
  beside that import to keep it true.
- `unibox_core` itself does not stay out of Flutter's way, and a host that needs
  both imports the tree with a prefix:
  `import 'package:unibox_core/unibox_core.dart' as core;`.
  - Reported by the analyzer: `Axis`, `BoxBorder`, `BoxShadow`, `TextOverflow`.
  - Reported by nothing: `TextAlign`, `FontWeight`. Flutter re-exports those two
    from `dart:ui`, and an SDK declaration loses to a package declaration without
    a diagnostic, so the failure surfaces later as
    `a value of type 'TextAlign' can't be assigned to a parameter of type
    'TextAlign?'`.
  - A tree in its own renderer-free library needs neither prefix nor `hide`,
    because no file sees both APIs. That is the arrangement the example uses.

### 5.2 Precedence
1. Flat node parameters (`gap`, `padding`, `fontSize`, ...).
2. `style` tokens (`BoxStyle`, `BoxTextStyle`).
3. Inherited typography from the closest ancestor box.
4. The host ambient style (Flutter `DefaultTextStyle`, page CSS).
5. Renderer defaults.

`computedStyle` exposes levels 1 and 2, so both renderers resolve the same
values. Level 3 is the only inherited level: layout, spacing and sizing are
never inherited (CSS does not inherit them either).

### 5.3 Dimensions
- `double` values are logical pixels, which the web renderer emits as `px`.
- `double.infinity` fills the available space: `100%` on the web, `Expanded`
  inside a flex parent and an infinite `BoxConstraints` elsewhere in Flutter.
- Unbounded parents plus an infinite dimension is a layout error in both
  targets, exactly like combining `double.infinity` with an unbounded
  `SizedBox` in plain Flutter.

### 5.4 Parity
- One tree, one shape: a node has to produce the same layout on both targets, so
  a default that only one of them has is a bug. `direction` is the case that
  matters: an unset direction means `Axis.vertical` everywhere rather than the
  `Column` of one target and the block flow of the other.
- A default lives in the model (`BoxStyle.resolvedDirection`), not in each
  renderer, so the two can only ever agree on it.
- A token that cannot take effect is either honoured or reported by
  `validateTree`; silently accepting it is not an option.
- Filling a width needs a width to fill. `width: double.infinity` means "as wide as I
  am offered": Flutter hands a child the incoming constraint, and a browser resolves
  `100%` against its parent's width — which, for a column that hugs its content, is
  `auto`, so the child hugs too. The two then disagree, and the example's listing rows
  did: the price stopped half way across the card. The model's answer is the parent's
  `crossAlign: CrossAlign.stretch`, which both targets honour (a flex `stretch`, a
  `CrossAxisAlignment.stretch`), and a component that holds a row states it —
  `MaterialCard` stretches what it holds for exactly this reason.
- Platform chrome belongs to the tree. A node never keeps a decoration its
  platform adds by itself — no Material underline under a field, no user agent
  border, focus ring or padding around an input, no user agent underline under a
  link — because the same node would then look different on the two targets.
  Whatever a field or a link should look like is expressed as a box around it.
  The focus ring is the subtle case: a browser draws it around the field, which
  sits inside the padding and the border of the box that wraps it, so keeping it
  paints a second frame inside the one the tree asked for. Dropping it leaves the
  caret as the only cue, which is the one thing both targets draw, and it is
  left out for the reason given below: a field cannot be given a frame by the tree yet.
- A state rule may only contribute the tokens of its state. The browser layers
  `:hover` over the resting rule exactly like the Flutter renderer merges a
  state style, so a state rule that restated the layout would reset it.
- Parity is *tested*, not assumed: `unibox_testing` lists the boxes every
  renderer has to present the same way and the texts every renderer has to
  typeset the same way, and each renderer suite reads the appearance back out of
  its own output — the Flutter one from the widget tree, the web one from the
  emitted CSS. A renderer that drops a token therefore fails its own suite, and
  because both answer the same entry, one target cannot be relaxed without the
  other failing.
- The contract stops where the two platforms stop agreeing, and it says so: what
  is compared is what a renderer *declares* — layout, spacing, paint, the six
  typography tokens, alignment and truncation — never what a text engine makes of
  it. Glyph rasterisation, hinting and line breaking belong to the engine, and
  `unibox_testing/README.md` has the table that says which is which. One
  length is exempt from that, because both sides compute it the same way: a line
  box is `fontSize * lineHeight` on both.
- The default typography is part of the model, not of a host: renderers install
  `BoxTextStyle.defaults` at the root of the tree they render — a
  `DefaultTextStyle` around the widget tree, a `:root` rule on the page — because
  the hosts disagree about the answer (14 logical pixels of black in Flutter, 16
  pixels of `canvastext`, a colour that flips with the theme, in a browser) and a
  default that lives in the host is the drift this library exists to remove. The
  font family is the one token the default leaves out: a font file is an asset of
  the application, so unset means the platform's UI font on both targets
  (`system-ui` in CSS, the engine default in Flutter).
- The surface a tree is drawn on is host business: a `100%` box needs a root with
  a height, and a font needs a host that has one. An application declares both in
  its own idiom (`MaterialApp`, or the head `toDocument` writes) and the renderer stays out of
  it.
- The *size* of that surface is host business too, which is why a breakpoint is
  not a token. A box cannot ask how wide the window is, so a page that has to
  know takes the answer as a parameter and each host produces it the way its
  medium allows: Flutter measures the window before it builds, the web host hands
  the question to CSS as a media query, because a static render happens before a
  viewport exists. Both answers reduce to the same two layouts as long as a
  hidden element is equivalent to an absent one — a `display: none` box takes no
  room, like a node that was never added.
- No node may inherit a *look* from its platform. Whatever the tree does not
  declare is decided by the model and written into the output, because the two
  hosts answer differently and both answers would be visible: a box without a
  direction is a column, a text without typography gets
  `BoxTextStyle.defaults`, an image without a fit scales down, a text area
  without `maxLines` is one row tall with no resize grip, and a stack child that
  is not positioned keeps its own size instead of stretching to the cell. Each of
  those was a divergence before it was a default, and none of them is a token: the
  tree still says nothing, the renderers just stop asking the user agent.
- Approximate is allowed where the platforms genuinely differ: font face, line
  breaking, shadow blur, placeholder, caret and selection colours, scrollbars, hit
  testing. Similar, not identical.

### 5.5 Interaction
- A box reacts to tap, long press, hover, focus and press. These five states
  exist on pointer, keyboard and touch input alike, so no state is web-only or
  Flutter-only.
- `enabled: false` suppresses callbacks, keeps the node in the accessibility
  tree as disabled, and never changes layout.
- Styling a state uses `stateStyles`, never a per-platform mechanism.
- Keyboard focus is opt-in: a box joins the tab order only when its
  `BoxSemantics.role` is one the user can act on. A plain container never does.
- Dragging, scrolling gestures and pointer move tracking are out of scope.

### 5.6 Non-goals
- No CSS cascade: no selectors, no specificity, no `inherit` keyword, no
  `!important`. Typography is the single inherited axis.
- No style sheet abstraction with class names; shared looks are expressed as
  `const BoxStyle` values.
- No breakpoint that changes *structure*: a width may dress a node differently
  (`visibleFrom` / `visibleUntil`, §5.15), never decide which children exist, and
  never be read from a viewport the other renderer cannot see.
- No third-party component runtime as the implementation of a design system. A
  Material view is a package of **values plus nodes** (`unibox_material`), drawn by
  whatever renderer the host uses; it is not an `EmbedNode` pairing a Material web
  component on one target with a Flutter widget on the other. That pairing is the
  one thing conformance cannot check — it is two implementations of one design, and
  the library's promise would be false exactly where most trees are built. The
  embed door stays open for the components that are behaviour-heavy and
  unportable (a date picker, a rich editor, a map), one at a time, documented as
  outside the contract. Two further facts decide it in practice: `@material/web` is
  in maintenance mode pending new maintainers by its own README, and either
  library brings its own token layer (`--md-sys-*`, `--mdui-*`) that would become a
  fourth source of truth next to the tree, the host theme and the CSS variables.
- No SEO or document metadata: a title, a language, a description, a canonical
  url and structured data describe a *document*, while a tree describes a region
  of one. The host owns them, which is also what keeps the same tree usable as a
  page, a card inside a page or a section of a Flutter screen. What the tree does
  contribute is structural markup — real text, `<img alt>`, `<a href>` and the
  `role` attributes of `BoxSemantics` — so a crawler reads it without JavaScript.
- A grid is the model's second layout engine, and the last one. `GridNode` is
  admitted because its answer is one arithmetic rule — a column count and a cell
  width from a single minimum — that both targets can apply and a test can read
  back; a table is refused because column sizing, collapsing borders and header
  association are a family of algorithms with no single answer to compare. The
  test is the same in both cases: can the result be read back and compared?
- No widget/component wrapper API: renderers only translate nodes. `EmbedNode`
  is the single, explicit exception: host content enters the tree as an opaque
  payload that only its own renderer accepts, and any other renderer throws.

### 5.7 Compatibility
- Additions (new optional parameters, new nodes, new tokens) are minor.
- Renames and removals are breaking, and are made outright: this library has one
  consumer, the repository itself, so an old spelling is not kept as a deprecated
  forwarding member. The change lands on every call site here and there is nothing
  else holding the old name.
- Every published change is listed in the package `CHANGELOG.md`.

### 5.8 Structure and semantics
- A node says what it *is* as well as how it looks, and the two are separate
  tokens: `BoxSemantics.element` picks the element a box becomes, `BoxRole` picks
  the ARIA role of a hand drawn control, `TextNode.headingLevel` says a text is a
  heading, and `expanded`, `selected`, `pressed`, `hidden` and `liveRegion` describe
  its state. None of them changes a pixel, which is the test the semantics tests run:
  a heading measures the same as the text it would be without the element.
- `selected` and `pressed` are not interchangeable. `aria-selected` belongs to an
  *option*, a tab, a row or a grid cell — the item of a set — while a toggle button
  states its own state with `aria-pressed`. A browser ignores both when they sit on
  the wrong role, so a chip or a segment that said "selected" was announced as an
  ordinary button, and the state was lost on the web alone.
- A heading is a text and not a container: `<h1>`–`<h6>` on the web,
  `Semantics(header: true, headingLevel: n)` in Flutter. The element brings no look
  of its own — the renderer cancels the user agent's margin, size and weight —
  because typography is the tree's business. `BoxRole.heading` stays for a heading
  that cannot be written as one run of text.
- The two targets are not equally expressive, and the gap is documented instead of
  papered over: HTML has landmarks (`main`, `nav`, `header`, `footer`, `aside`) and
  Flutter has none, so a landmark is structure a browser gets and a Flutter screen
  reader does not need. Where Flutter *does* have the concept — a list, its items,
  a form — both targets say the same thing.
- The renderer states the reset a semantic element needs. A `<ul>`, an `<ol>` and
  a `<figure>` come with an indent or a margin that no Flutter counterpart has, so
  the space is written as `0` unless the box declares it; a `role` is only written
  when the element does not already imply it.
- Structure that HTML forbids is a tree error, not a rendering surprise: a
  `BoxElement.li` outside a `ul` or an `ol` is reported by `validateTree`.
- What stays host work: navigation between documents (a `LinkNode` or the host's
  router), `aria-current`, figure captions, tables, and anything that describes the
  *document* rather than the tree (see 5.6).
- Motion is a token before it is an embed. `BoxTransition` states a duration and a
  curve, and the curve is one of the five CSS and Flutter define with the same
  control points, so a hover fade is interpolated identically on both targets. It
  covers the paint and never the layout: a transition that moved things would make
  the two targets agree on the duration and disagree on the result.
- `opacity` and `transform` are paint too. Both are values the tree states
  (`BoxTransform`: scale, rotation in degrees, offset in logical pixels), both paint
  the box without giving it different room, and both are in the transitioned set —
  which is what makes a press-scale or a fade-in a state style rather than an
  animation. A transform is applied about the centre in a fixed order (translate,
  rotate, scale) because CSS and Flutter both compose matrices left to right and
  neither may choose the order, and its parts are interpolated one by one: a matrix
  lerp would shrink a box that only turns. Anything that ripples from a pointer
  position or runs a timeline of its own is not a token, and that is what the next
  bullet is for.
- The escape hatch is `EmbedNode`, and it is the one place the model admits that
  two implementations may differ: a node carries opaque objects, one per renderer
  that can draw it, and each renderer takes the first one whose type it
  understands — a `Widget` or a builder that wraps the child, a `Component` or a
  builder that wraps the child. The model names no target, so a third renderer
  needs no change here, and a node class it has never seen renders as long as it
  brings a payload of a shape that renderer draws. Nothing about an embed is in the
  conformance contract, because the two halves can look different by definition;
  what the model can check is that the hatch is not empty (`validateTree`) and that
  a renderer never silently skips a node it cannot draw.
- The portable route stays the token set: transitions, opacity and transforms are
  the effects both platforms express exactly, and an embed is for what is left
  over. When that work lands, an effect belongs in a token first and in an embed
  only if it cannot be described as one.

### 5.9 Design systems are packages
- A design system is a set of token values, not a mode of a renderer. It lives in
  its own package, depends on `unibox_core` (and on nothing that draws), and
  exports `const` values a tree can use — so the renderers never learn that
  Material exists and a tree typeset with Material's scale is drawn by the same
  code as one with hand written values.
- `unibox_material` is the first one: the fifteen roles of the Material 3 type
  scale as `BoxTextStyle` values. Each role is a complete look (size, weight,
  tracking, line height), because a partial style would let the surrounding text
  turn a `titleMedium` bold. `color` and `fontFamily` are the two tokens left
  unset, and for the same reason they are left unset in `BoxTextStyle.defaults`:
  a colour scheme and a font file are the application's, and inheritance is what
  lets one scale serve a light theme, a dark theme and a branded control.
- A line height is written as the division the specification's pixel height
  implies (`64 / 57` for display large), because the token is a multiple of the
  font size on both targets; the resulting line box is the specification's, and
  the suite checks `fontSize * lineHeight` against it.
- `unibox_core` stays neutral about design systems. It has one default, chosen so
  that the two hosts cannot disagree, and no opinion about a particular brand's
  scale. A second design system can be added as a second package without touching
  the core or a renderer, and an application that wants no system at all is not
  made to carry one.
- A design system is values for looks and nodes for structure. A role enters a
  tree through `Box.textStyle` or `TextNode.style`, and a product that wants its
  own names writes a class of `const` values in its own package. No
  `TitleText`-shaped wrapper is exported: a look baked into a node type cannot
  read a theme (the tree has no context), names a look like a structure
  (`headingLevel` is a separate token) and duplicates Material's own vocabulary.
- A component that owns children is a node, and it is built from the node that
  already draws it. `unibox_material` exports `MaterialCard`, a `Box` with the
  card's surface, shape, elevation and body typography: no renderer change, no new
  token and therefore no conformance case, and the two suites pin the property it
  rests on — a node that extends `Box` renders as that box on both targets. The
  distinction is what keeps the package honest: a look is a value, a component is
  a node, and neither is a new renderer.
- A text takes one `style`, not a list of them. Typography composes by
  inheritance (`Box.textStyle`) and by `merge` at author time, so a
  `TextNode.styles` list would add a second, node local cascade — the CSS cascade
  §5.6 rules out.
- A value can be computed. `MaterialPalette.fromSeed` grows the twenty-four colour
  roles from one brand colour with Material's own algorithm
  (`material_color_utilities`, pure Dart, Apache-2.0, no widget layer), and the
  result is still a value: the tree reads it while it is built, no renderer
  resolves anything at paint time, and the package gained a dependency rather than
  a mode. It is the one dependency a value package may take — an algorithm that
  answers with a colour, not a host that answers with a picture. The written
  `MaterialPalette.light`/`.dark` stay, because they are the specification's
  baseline scheme and because a `const` value composes into other `const` values.
- `BoxStyle` and `BoxTextStyle` are `final` classes with structural equality and
  a `merge` that returns the base type, so a preset is always a value and never a
  subtype. A catalogue type (`TextStyles`, `BoxStyles`) would therefore be a
  namespace of constants; since the core holds kinds rather than looks, that
  namespace belongs to `unibox_material` or to the application.
- The cost asymmetry fixes the order of work: a preset catalogue can be added to
  an application at any time, or to a package as a minor release, while a
  component layer inside the published API could only be withdrawn as a breaking
  change. The token vocabulary is therefore the layer to stabilise, and every
  convenience sits above it.



### 5.10 A subtree that owns its state
- `StatefulNode` is the one node with a lifecycle. It carries `create` — a factory,
  never an instance — and `view`, a function of the state. A renderer calls
  `createStore`, subscribes, calls `onMount`, rebuilds on a notification, and calls
  `onUnmount` and `dispose` on unmount. The tree itself stays immutable, so it can
  still be built, compared and rendered twice.
- The state is a value. A `Store` publishes an immutable state and notifies a
  listener; `StateStore` drops a published value equal to the current one, so a
  rebuild follows a change of the description rather than a call.
- The view returns one tree for the state. Every state a component can be in — a
  pending request, a result, an error — is therefore an ordinary tree that the
  renderers, `validateTree` and the conformance table already handle. A view draws
  no overlay: a dialog is not part of the model yet, and adding one is a decision
  about the view's shape and each renderer's modal layer, which §5.13 answered by making
  an overlay a node.
- A store is pure Dart, in the core. `StateStore` keeps its own listener list and
  a guarded `state` setter, so the model keeps its promise of no package
  dependencies and one store still runs in Flutter, in a browser and in a
  `dart test`. `flutter/foundation` cannot be used: core and the web renderer may
  not import Flutter, and a state layer per target is the drift this project
  exists to remove.
- `StatefulNode` is a component in the sense of §5.9 — a node built from nodes —
  with one difference: its children come from a view the renderer builds at render
  time, so `validateTree` sees an empty child list and a renderer validates each
  view in debug builds.
- The web renderer draws the state the store starts with: it creates the store, reads its
  state, renders the tree and never calls `onMount`. A document has no runtime, so a press
  cannot change it — that is the application's job once it takes the page over, and the node
  is constructed there because its behaviour is Dart closures, which no markup can carry. A
  first state of "loading" therefore renders a page that loads, and a store that
  starts with the server's data renders the page as it should look.
- The vocabulary is the model's: a node, a store, a state and a view. There are no
  events, no cubits and no blocs — those are one naming of a pattern this model
  describes in its own words, and borrowing them would promise an API the library
  does not have.


### 5.11 Presentation is written once

A tree repeats itself. Six listings share a look, a label appears in two places, and
writing the declarations on each element makes the output cost grow with the number
of elements instead of with the number of *distinct* looks. The web renderer
collects them: every distinct set of declarations becomes one class rule in a single
`<style>` element, and the element carries the class (`UniboxStylesheet`).

A class name shared between two elements was not enough, which is what the earlier
shape got wrong: a box that styled an interaction state emitted its own `<style>`
element next to itself, so the *name* was deduplicated while the *rules* were written
once per instance — six identical cards, six identical blocks.

Two consequences are the reason for the rule, and neither is about size:

- **A host keeps the last word.** An inline style outranks every stylesheet, so a
  page with one per element cannot be themed by a custom property, a
  `@media (prefers-color-scheme: dark)` block or a rule of the host's own. A class
  can be outranked, which is what makes a design system a value the host supplies
  rather than a copy of the host's values in the markup.
- **The markup says what, not how.** An element reads as its structure and carries
  one class; the CSS next to it can be cached and read.

Flutter needs no equivalent: a widget tree has no serialised output, and the
allocation cost of a decoration is a profiled concern rather than a correctness one.
The parity of the two renderings is unaffected — the conformance table compares
resolved values, and where a value lives is invisible to it.

A component rendered outside a rendering — `renderNode` called directly, or a node's
renderer used in a test — still writes its declarations inline, because there is no
sheet in scope to register them in.

### 5.12 A colour role is a value the host answers

A tree that carries literal colours is a third copy of a design system: the host has
its `ColorScheme`, the page its stylesheet, and every element its own hex. So a
colour can name a **role** — an `enum` member — and the application supplies a
`UniboxTheme` that says what each role is worth.

The role is typed rather than a string because a string is a name the compiler
cannot check and a reader cannot rename; the theme is keyed by the same enum value,
so "the colour this role is worth" is a map lookup on an identity, and
`validateTree(root, theme: theme)` reports a role the theme does not define.

The theme is an **argument**, not a scope a node looks up: `renderFlutter(node,
theme:)` resolves each role while it builds the widget tree, `toDocument(node,
theme:)` writes the theme once in `:root` and points the rules at
`var(--unibox-color-…)`. Two pages rendered in one process can carry different
themes, a tree stays `const`, and the whole palette is emitted on the web whether or
not a node uses each role — a host stylesheet has to be able to read one the tree
leaves alone.

What follows honestly: a role is a runtime failure if no theme is given (it is
reported, and the renderers refuse the tree rather than paint nothing), the
conformance table compares a value in Flutter with a `var()` and a `:root` block on
the web, and the CSS name follows the enum identifier, so renaming a member is a
breaking change for a host stylesheet that names it.

### 5.13 Overlays are nodes
- Content above the page is a node, not a mode: `OverlayNode` wraps the content,
  sits in the tree where the state says it belongs, and disappears from the tree
  when the state says so. Presence is the tree's answer; there is no `open` flag
  and no overlay slot on a view, so a `StatefulNode` never learns that a dialog
  exists.
- The node states policy, not mechanism: `onDismiss`, `barrierDismissible`,
  `barrierColor` and `alignment`. How an overlay is presented belongs to the
  renderer — an `OverlayPortal` on the root overlay in Flutter, a fixed layer in
  the browser — which is what keeps it escaping the clipping of the box it sits
  in.
- An overlay is never drawn in the flow of its parent. A target that cannot
  present one must say so; rendering the content inline would make the same tree
  a modal on one side and a paragraph on the other.
- `validateTree` reports the one combination that cannot do anything: a
  dismissible barrier with no `onDismiss`.
- Dismissing is interaction, so on the web it waits for the client build; the
  server writes the layer and its barrier so the page looks right first.

### 5.14 Reflow is a grid

A tree states a rule, not a breakpoint. `GridNode(minItemWidth, maxColumns, gap)`
means "fit as many columns of at least `minItemWidth` as the width allows, stop at
`maxColumns`, and let the tracks share the width", and nothing in it knows a
viewport:

- the web renderer writes `repeat(auto-fill, minmax(min(100%, max(minItemWidth,
  (100% - (maxColumns - 1) * gap) / maxColumns)), 1fr))`, which the browser
  resolves against the width of the grid itself;
- Flutter applies the same arithmetic — `columnsFor` and `cellWidthFor` in core —
  to the constraints of the grid, so the two agree at **every** width rather than
  at the widths a breakpoint happens to name. Measured in Chromium and WebKit
  18.2 at 250, 375, 600, 899, 900, 901, 1280 and 1440: the counts and gutters are
  identical and the cards agree to the 1/64 pixel a browser lays out with, which
  is why a sweep compares widths with a 0.02 pixel tolerance.

The clamp is not decoration: below `minItemWidth` the CSS track is `100%`, which
is the one column `cellWidthFor` answers. The `max(...)` is the cap: the minimum
track becomes a share of the width once the width fits `maxColumns`, so the count
stops there and the cards keep growing.

**The last row is where the targets could disagree, so the model fixes it.**
`auto-fill` creates every track whether or not a card lands in it, so a short last
row leaves its remaining tracks empty. Flutter pads the row with empty slots of the
same width and uses no `Expanded` or `Flexible`, because a flexing child would
stretch over the empty track in one target and not in the other. A grid child
therefore may not flex or size itself: `validateTree` reports a `flex`, a finite
`width` and an infinite `height`, and it reports an image whose height would wait
for the file unless the height is known at layout time (a finite height, both
dimensions, or an ancestor with a definite height — a ratio box, when the model
has one, joins that list).

`align-items: start` on both targets is the other half: a row is as tall as its
tallest card and shorter cards are not stretched, which is also what keeps the
Flutter side free of intrinsic measurement a card containing a scroll view could
not answer.
### 5.15 Visibility is a style, and a width is measured where it is drawn

**The screen.** A listings page: cards in a grid on a wide surface with a map beside
them, and below 900 logical pixels a single column of cards with a floating button
that opens the map as an overlay. It is the first screen in this project that
genuinely needs to *dress* a node differently at a different width — not just
distribute it differently — so it is also the first one that pins this rule.

Four mechanisms carry it, and only one of them is new:

| What the screen needs | Mechanism | Why it is not a breakpoint in the tree |
| --- | --- | --- |
| two cards per row, then one | `GridNode(minItemWidth: 280, maxColumns: 2)` | arithmetic on the grid's own width (§5.14) |
| the map beside the cards, and absent when narrow | `Box.visibleFrom: 900` | the map stays in the tree and in the DOM; only its `display` changes |
| the floating button when narrow, and gone when wide | `Box.visibleUntil: 900` | the same token, the other direction |
| the map as its own view on a phone | `StatefulNode` state plus an `OverlayNode` | state may change structure; width may not |

**Why a width is measured on the box, not on the window.** `visibleFrom` becomes a
**container query** on the web — `@container (min-width: 900px) { … }` — and a
`LayoutBuilder` over the box's constraints in Flutter. *Which* box declares the
container is the renderer's decision, not the author's: a box whose subtree holds a
threshold becomes `container-type: inline-size`, so the nearest enclosing layout box
is what a threshold measures, on both targets, and a node drawn in a panel — a card
in a sidebar, one half of the showcase — measures the panel rather than the window. A media query would measure the *viewport* while Flutter
measures the *node*, and the two disagree the moment a node is not full bleed: in
the showcase each panel is about 640 pixels wide inside a 1280 pixel window, so a
media query would say "wide" exactly where Flutter says 640. Container queries ask
the same question of the same box, which is what makes the two renderings agree at
every width rather than on full-width pages only.

**Why not a `LayoutBuilder` in the tree.** A tree that measures the surface and
returns a *different* subtree cannot be rendered by a server — no viewport exists at
export time — and two subtrees duplicate the content in the crawlable DOM. So the
node states a threshold and the renderer resolves it; the child is always present,
on both targets, at every width.

**Hidden is not absent.** `display: none` removes the *boxes*, not the markup: the
element and its subtree stay in the DOM, stay in the HTML a crawler reads, and stay
queryable — what they lose is layout, paint, focus and their place in the
accessibility tree. That is the property the whole design leans on (the markup is the
same at every width, so nothing that adopts it can draw a different page), and it is
also its price: a hidden subtree still ships, and an `<iframe>` inside one may still
load. Hiding because of **state** is the opposite and stays the view's job — a node
the view does not return is genuinely absent from the DOM, which is why the map's
overlay only exists while it is open.

That leaves one honest tension in this screen: the map appears inline on a wide
surface and as an overlay on a narrow one, so while the overlay is open a phone holds
two copies — one unpainted. A single instance would need the map's *placement* to
depend on state and width together, which is the compound rule this design refuses.
The rule that keeps it honest is therefore measurable: **exactly one map is painted at
every width**, which the example's tests assert, and the unpainted copy is documented
rather than assumed away.

One rule fell out of using it: a hidden box **releases what it claimed** — a
`flex` factor included — because `display: none` removes a flex item from the layout
rather than leaving a gap. The Flutter renderer keeps the subtree alive in a
zero-sized box so its state survives the width change, which is the closest a widget
tree gets to the DOM that stays.

What that buys, stated as the invariants the feature has to keep:

- the markup is identical at every width, so a client that adopts it draws the same
  page;
- every variant is in the CSS, mobile-first: the base rule describes the narrow
  layout and the container query adds the wide one, so a browser without container
  queries still renders the mobile layout rather than a broken desktop one;
- a hidden box takes no room, exactly like an absent node, which is what Flutter's
  `Visibility` does with the same threshold;
- removing a threshold removes exactly its rules — the box's own class rule and its
  one query block — and nothing else;
- no renderer reads a viewport anywhere: the web asks CSS, Flutter asks the
  constraints of the node it is drawing.

### 5.16 A name is for a developer, and it is not a look
- An element's `class` is the hash of its declarations, which is what makes six
  listings with one look cost one rule. That name says nothing to a reader, so every
  element a node drew also carries the name of its node:
  `data-unibox-node="material-card"`.
- It is written always, and not behind a flag. A name carries no look, so there is
  nothing a switch could protect; and a page cannot disagree between its server render
  and the client that adopts it when there is no switch for the two to differ on.
- It is an attribute and not a class because `class` is the stylesheet's namespace. A
  second class there would either carry no rule — misleading every reader of the
  output, including the suites, which resolve a look through the classes an element
  wears — or become a look a host can write and Flutter cannot draw.
- A label is never part of the presentation: no class, no class key, no rule, no
  element, no layout. Two node types with the same look share one class and one rule
  while carrying different names, which the suite pins.
- The name is a **literal** a node states in `UINode.debugLabel`, never its type: a
  compiled build mangles class names, so a derived name reads `minified:-s` in a
  browser — measured in a `dart compile js -O2` build, which is why every node of
  `unibox_core` and `unibox_material` states one and why a subclass that says nothing
  inherits the name of the node it extends.
- What it is not: a semantic. A screen reader hears the element, its `role` and its
  `aria-*`; nothing reads the label back, and nothing may start to.
- A wrapper a renderer invents — a stack's cell — has no name, because no node drew
  it. That absence is meaningful: an element without the attribute is not part of the
  description.

======
### 5.17 A shape is a path in a view box

- A box is a rectangle, and every design system eventually asks for something else: a
  ring, a badge, a triangle, a gauge. The answer is one token, `BoxStyle.shape`, whose
  value is a `BoxShape` — a path and the view box it was authored in.
- **A view box and not the box's own numbers.** The outline is written in the
  coordinates it was authored in — a 100 by 100 grid, or whatever an SVG said — and
  each renderer stretches it to the box. One value then draws the same silhouette at 40
  pixels and at 400, and a shape copied out of a drawing tool needs no arithmetic.
- **A command list and not an SVG `d` string.** `dart:ui` has no path parser, so a
  string would put a parser in the Flutter renderer. With the model owning the six
  commands SVG's `d` has, every renderer maps them to its own primitive — `Path` in
  Flutter, the `d` attribute on the web — and neither parses what the other wrote.
- **The shape is the box's outline, not an effect over it.** The background fills the
  path, the border is a stroke along the path, and `overflow: hidden` clips the children
  to it. A box still has exactly one outline, which is why `validateTree` reports a
  shape next to a corner radius.
- **`fillRule` is part of the value.** `BoxFillRule.evenOdd` makes a subpath inside
  another punch a hole, so a ring is two circles and no stroke token: the effect that
  motivated shapes in the first place needs no second primitive. A partial ring is the
  same band cut short — one subpath of two arcs and two radial edges, filled under
  `nonZero` — which is why `BoxShape.ring(thickness:, sweep:)` can be a value rather
  than a component, and why a progress indicator is two boxes instead of a node type.
  The model ships that factory and `BoxShape.circle` because arc arithmetic is the one
  thing every caller would otherwise get subtly wrong; anything else is composed.
- **Layout does not know.** A shape paints differently and lays out identically: the
  children stay in the same rectangle, which is what puts a label in the hole of a ring
  and why a shape cannot be used to place anything.
- **What it is not.** It does not cast a shadow, it cannot be interpolated (two
  outlines have no numbers between them), and two outlines cannot be combined. Each of
  those is a `validateTree` report or an `EmbedNode`, never a silent approximation.
- Canvas is the wrong layer for this and stays the escape hatch: a painter has no
  implementation on the server — `dart:ui` does not exist on the VM — so a page drawn by
  one is invisible to a crawler and impossible to render without the client bundle. A
  path is a value: it can be compared, cached as a class, rendered on the server and
  held to the same numbers by both targets.

<<<<<< HEAD
### 5.18 A key is identity, and a host may have to find it

- `UINode.key` identifies a node among its siblings so a renderer keeps an element
  attached to it. A web renderer also writes it out — `data-unibox-key="page"` — so a
  host can find the element a node drew without counting siblings.
- That is what a page needs in order to survive being replaced by an application: a
  document that was scrolled, or a control that was pressed, before the runtime arrived
  names what it was looking at, and the tree that takes over answers for it. The
  identity already existed; writing it out is what makes it readable from outside the
  tree.
- Only a `String` or an `int` is written. Any other key's `toString()` is an instance
  hash, so a server render and the browser it sends the markup to would name one node
  two ways — a page that disagrees with itself, which is worse than one that says
  nothing. Such a key stays a `ValueKey` and nothing more.
- It is an attribute, never an `id`: an `id` is unique in a document while a key is
  unique among the siblings of one node, so the same tree drawn twice on a page — a
  card in a listing and the same card alone — is valid for a key and invalid for an
  `id`; and an `id` is fragment-addressable and styleable, which is a look one target
  applies and the other cannot draw.
- A key that has to be found again should be unique in the document as well. That is a
  fact about the tree a host builds, not a rule `validateTree` can check: only a
  document knows how many trees it holds.
- The key is not a semantic and not a look: no class, no rule, no element, nothing read
  back, and two elements with the same look keep sharing one class while carrying
  different keys — the same argument §5.16 makes for the name.

### 5.19 A locale is an input, and the host chooses it

- The model holds strings, and a string is a value like a colour: copy is decided where
  the tree is built. What it refuses is an ambient lookup. `Localizations.of` reads a
  `BuildContext`, and `toDocument` renders a tree with no context, no binding and no
  second frame — a tree that reads the locale is a tree that cannot be a page. The
  pattern is therefore one builder called once per language, not one page that swaps its
  text: `UINode buildPage({required SiteCopy copy, required SiteRoutes routes})`.
- The copy is a `const` instance per locale, not a `Map` of keys. A missing key in a map
  is a blank on one page at runtime; a missing `required` field is a compile error in
  every language, which is the whole reason a translated page starts as a class.
- Copy and routes travel together and come from one tag. The bug a localised site
  actually has is a page in one language whose links, canonical or `alternates` point at
  another — so a builder takes the editions it needs from a single value, never a `String`
  from one place and a path from another.
- The address is the source of truth, because a crawler sends no `Accept-Language` and
  keeps no cookie: `/de/apartments/` is the German page, and a language switch is a `LinkNode`
  to the other address — followable, crawlable and shareable, the same shape the example's
  palette picker uses to be a page a crawler can reach. A state in a store is the honest
  answer for a language change inside an application; a link is the honest answer for a
  page that has to be found.
- One document per locale, and each one states its own three facts: `lang` for the
  language it is written in, `canonical` for its own address, and `alternates` for the
  whole set, itself included. `hreflang` is the only thing that tells a search engine three
  pages of translated text are one page in three languages rather than three pages
  competing for one query.
- Beyond one page, `.arb` and `intl` belong to the application. `intl` is a pure Dart
  package, so the no-dependency rule — which binds `unibox_core` — leaves a consumer free
  to use it; plurals, number and date formats and collation are exactly the things a
  renderer must not pick an implementation of, because it would have to pick one on both
  targets. The model's share of localisation is what a translated page still has to say
  correctly: real strings, `alt` text, `BoxSemantics.label`, and headings at the level the
  page's structure asks for.
- What the model deliberately does not grow: a `locale` on a node (a language is a document
  fact, §5.6, and a node is a region of a document), a mutable current locale (one build
  step writes every language in one process, so a global would make output depend on write
  order), and a key catalogue in core (a key map gives up the compiler's help and would be
  the first dependency the model cannot have).
