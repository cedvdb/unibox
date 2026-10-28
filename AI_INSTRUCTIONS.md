# Building Unibox components with an AI assistant

This file is for an assistant writing application code **with** Unibox. The rules for
changing Unibox itself are in [`AGENTS.md`](AGENTS.md); the full parameter tables are
in [`README.md`](README.md).

Unibox is not on pub.dev and is not in any model's training data. An assistant that
has not read this file will write Flutter widgets, call them Unibox, and invent
parameters that do not exist. Hand it three things:

1. **This file**, pasted into the context or `@`-mentioned.
2. **[`README.md`](README.md)** — the reference: every node, every token, every
   default. It is the ground truth when the two disagree.
3. **If the assistant can read files**, `packages/unibox_core/lib/src/` (the source is
   documented member by member) and `example/unibox_example_shared/lib/src/` (a
   complete page as one `StatefulNode`, with a form, a dialog and a navigation
   bar, in plain Dart).

A prompt that works:

```text
Read AI_INSTRUCTIONS.md and README.md from the Unibox repository before writing any
code. Build <the component> as a Unibox node tree in a file that imports only
package:unibox_core, plus package:unibox_material when it uses the Material roles.
Do not use Flutter, Jaspr or HTML widgets. Return the tree, and separately the small
host that renders it.
```

## The model in eight lines

- A screen is an immutable Dart tree of nodes: `Box`, `TextNode`, `ImageNode`,
  `LinkNode`, `StackNode` + `PositionedNode`, `TextInputNode`, `StatefulNode`,
  `OverlayNode`, `GridNode`, `EmbedNode`.
- One tree, two renderers: `renderFlutter(tree)` or `tree.toWidget()` in a Flutter
  app, `renderJaspr(tree)` or `tree.toComponent()` in a Jaspr one.
- A node describes *what* is on screen, never which framework draws it. There is no
  `Text`, `Row`, `Column`, `Container`, `Colors`, `EdgeInsets`, `TextStyle` or
  `BoxFit` in the tree.
- Styling is tokens — `BoxColor` and the `BoxColors` palette, `BoxSpacing`,
  `BoxBorder`, `BoxShadow`, `BoxTextStyle`, `BoxTransform`, `BoxTransition`,
  `BoxSemantics` — collected in reusable `BoxStyle` bags.
- State that changes while the page is up belongs to the tree through a node that
  owns it: `StatefulNode` creates a `Store`, the store holds one immutable state
  value, and the view draws one tree per state. What stays with the **host** is what
  a node cannot know: the surface, the fonts, the document, how a link opens.
- An overlay is a node too. `OverlayNode` sits in the tree where the state says it
  belongs — a dialog is in the tree while it is open, and absent while it is closed.
- A token that is unset has a default in the model (a box is a column, text is 16px
  black at a line height of 1.5, an image scales down), and both renderers apply it.
  Never reach for the host's default.
- `unibox_material` is optional: the fifteen Material type roles as `const`
  `BoxTextStyle` values, the colour roles as `MaterialPalette` (`light` and `dark`,
  each a `const` set of `BoxColor`s — or a palette grown from one brand colour with
  `MaterialPalette.fromSeed(seed, variant:, isDark:, contrastLevel:)`), and twelve
  components built on nodes the
  renderers already draw — `MaterialCard`, `MaterialListTile`, `MaterialButton`,
  `MaterialChip`, `MaterialSegmentedButton`, `MaterialNavigationBar` and `MaterialIcon`
  are `Box` subclasses, `MaterialInkWell`,
  `MaterialTextField` and `MaterialSpinner` are `StatefulNode`s (the ink a press
  spreads; the text, the focus and whether the field has been touched; the step a
  ring turns), `MaterialCheckMark` is a `StackNode` (Material's tick, drawn, so a
  chosen control needs no font), and `MaterialDialog` and `MaterialBottomSheet` are
  `OverlayNode`s. The palette is a value the tree wears —
  pass the roles into the builders; there is no `Theme` lookup at render time.
  Wiring the same roles into the platform (`ColorScheme`, CSS custom properties) is
  the application's job.


## The rules that make generated code run

1. **Import the tree with a prefix.** `Axis`, `TextAlign`, `FontWeight`,
   `TextOverflow`, `BoxBorder` and `BoxShadow` also exist in Flutter. In any file
   that imports Flutter or Jaspr:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:unibox_core/unibox_core.dart' as core;
   ```

   Better: keep the tree in a library that imports no renderer at all, the way
   `example/unibox_example_shared/` does, and let the host import both.
2. **The node names are not Flutter's.** `TextNode`, not `Text`; `ImageNode`, not
   `Image`; `StackNode`, `PositionedNode`, `LinkNode`. `Box` keeps its bare name
   because Flutter has no `Box`.
3. **Flat parameters beat style bags.** `Box.computedStyle` merges `style`
   (deprecated) → `styles` left to right → the flat parameters. A state style
   (`hoverStyle`, `stateStyles`) overlays the resting one; `disabled` overlays all.
4. **A box is a column by default.** `direction` unset means `Axis.vertical`, and
   `mainAlign` and `crossAlign` default to `start` — not Flutter's `center` cross
   alignment and not CSS's `stretch`. Say what you mean.
5. **Dimensions are `double?` in logical pixels.** `double.infinity` fills the space
   the parent gives; `flex: 1` is the `Expanded` spelling. `gap` is the space between
   children, `padding` the space inside, `margin` the space outside.
6. **Nothing platform specific in the tree.** No `MediaQuery`, no `Theme`, no router,
   no `DateTime.now()`. Measure in the host, read the theme in the host, and pass the
   answer in as a parameter.
7. **Callbacks are `void Function()`.** `onTap`, `onLongPress`, `onHover`,
   `onChanged`, `onSubmitted`, `onFocusChanged`. The host supplies the function, and a
   node that captures a closure cannot be `const`.
8. **A dialog is an overlay node.** `OverlayNode` carries the policy — `onDismiss`,
   `barrierDismissible`, `barrierColor`, `alignment` — and sits in the tree where the
   state says it belongs; being in the tree is what makes it show. Do not build one
   out of a `StackNode` and a positioned box, and do not reach for `showDialog`: no
   node has a modal slot and no view has an overlay slot. On a page that is rendered
   without a click (a static export, a screenshot, a test), render the state the
   dialog should start in.
9. **State belongs to a store, not to a view.** A tree that reacts is a
   `StatefulNode`: it creates a `Store` (`StateStore` is the ready-made one), the
   store holds one immutable state value and publishes when it is replaced, and the
   view is a function of state that returns one tree. No `setState`, controller or
   stream inside the tree, and no field on the node.
10. **Give an interactive box semantics.** A box with `onTap` and no `semantics` is
    not announced as a button and is not keyboard reachable. Add
    `semantics: BoxSemantics(role: BoxRole.button, label: '…')`.
11. **A link is a destination; a button is an action.** `LinkNode` is for a place a
    reader can go — its `url` is a real `href`, which is what a page without a client
    runtime follows and what a crawler reads. A control that opens a dialog or changes
    something in place is a `Box(onTap: …)` with the button role, and it carries no
    link: a press that is both a dialog and a page load is the flash a reader sees
    before the dialog they asked for.
12. **Key a list.** Children of a list that can reorder take `key:` — the id of the
    model they describe — or typed text follows the position instead of the row.
13. **Do not invent a parameter.** If it is not in the README tables or in
    `packages/unibox_core/lib/src/`, it does not exist. For anything the model cannot
    express, use an `EmbedNode` with one implementation per renderer, or ask.

## Translating what a model already knows

### From Flutter

| Flutter | Unibox |
| --- | --- |
| `Container`, `Padding`, `SizedBox` | `Box(padding:, margin:, width:, height:)` |
| `Column(children: …)` | `Box(children: …)` — a column is the default |
| `Row(children: …)` | `Box(direction: Axis.horizontal, children: …)` |
| `mainAxisAlignment` / `crossAxisAlignment` | `mainAlign` / `crossAlign` |
| `Expanded(child: …)` | `flex: 1` on the child box |
| `SizedBox(height: 8)` between children | `gap: 8` on the parent |
| `Colors.white`, `Color(0xFF112233)` | `BoxColor.white`, `BoxColor(0xFF112233)` |
| `Colors.grey`, `Colors.red`, `Colors.blueGrey` | `BoxColors.grey`, `BoxColors.red`, `BoxColors.blueGrey` — the same values |
| `Color.fromRGBO(r, g, b, opacity)` | `BoxColor.rgba(r, g, b, alpha)` — its alpha is `0`–`255`, or `BoxColor.rgb(r, g, b).withOpacity(0.5)` |
| `EdgeInsets.all(16)` | `BoxSpacing.all(16)` (`.symmetric`, `.only`, `.zero`) |
| `BoxDecoration(color:, border:, borderRadius:)` | `backgroundColor`, `border`, `borderRadius` |
| `BoxShadow(color:, offset:, blurRadius:, spreadRadius:)` | `shadow: BoxShadow(...)` — same names |
| `Text('Hi', style: TextStyle(…))` | `TextNode('Hi', fontSize:, fontWeight:, color:, lineHeight:)` |
| `TextStyle.height` | `lineHeight`, a **multiple** of the font size (`1.5`, not `24`) |
| `DefaultTextStyle` | `Box(textStyle: BoxTextStyle(...))`, inherited by the texts inside |
| `Image.network(src, fit:)` | `ImageNode(src, fit: ImageFit.cover, alt: '…')` |
| `GestureDetector(onTap:)` | `Box(onTap: …)` |
| `MouseRegion` | `Box(onHover: (bool hovered) { … })` |
| `Opacity(opacity:)` | `opacity:` on the box |
| `Transform.scale`, `Transform.rotate` | `transform: BoxTransform(scale:, rotation:, offsetX:, offsetY:)` |
| `AnimatedContainer` | `transition: BoxTransition(...)` plus a `BoxState` style |
| `ClipRRect` | `overflow: Overflow.hidden` with `borderRadius` |
| `BorderRadius.vertical(top:)`, `BorderRadius.only(...)` | `corners: BoxBorderRadius(topLeft:, topRight:)` — a box that is not round on all four |
| `SingleChildScrollView` | `Box(overflow: Overflow.scroll)` |
| `Stack` + `Positioned` | `StackNode` + `PositionedNode` |
| `Semantics(button: true, label:)` | `semantics: BoxSemantics(role: BoxRole.button, label: …)` |
| `TextField` | `TextInputNode(value:, placeholder:, inputType:, onChanged:)`, or `MaterialTextField(label:, validator:, onChanged:)` for Material's frame, which validates itself once the field has been touched |
| `showDialog`, `Dialog` | `MaterialDialog(title:, content:, actions:, onDismiss:)` — an `OverlayNode`, not a call |
| `showModalBottomSheet` | `MaterialBottomSheet(title:, content:, actions:)` — the same overlay at the bottom |
| `SegmentedButton`, a `ToggleButtons` row | `MaterialSegmentedButton(segments:, selected:, onSelect:)` — one pill of equal segments, the chosen one filled |
| `NavigationBar`, `BottomNavigationBar` | `MaterialNavigationBar(destinations:, selected:, onSelect:)` — one 80 pixel row of equal shares, the chosen destination on a `secondaryContainer` pill; where it sits is the tree's business, so being at the bottom is the last row of a column or a `PositionedNode` |
| `Chip`, `FilterChip`, `ChoiceChip` | `MaterialChip(label:, selected:, leading:, onTap:)` — 32 pixels tall, an outline when unselected, the secondary container when chosen |
| `Icon(Icons.check)`, under a chosen chip or segment | `MaterialCheckMark(color:, size:)` — Material's tick drawn from two bars, no font asset needed |
| `InkWell`, `InkResponse` | `MaterialInkWell(onTap:, borderRadius:, ink:, child:)` — a state layer plus the ink a press spreads; it paints no surface, so the filled box goes around it |
| `StatefulWidget` + `setState` around a tree | `StatefulNode` + a `StateStore` |
| `GridView`, a `Wrap` of cards | `GridNode(minItemWidth:, maxColumns:, gap:)` — equal columns that follow the width, no breakpoint |
| `Card` | `MaterialCard` (from `unibox_material`) |
| `Icon` | `MaterialIcon.codePoint(Symbols.home.codePoint)`, or `MaterialIcon.ligature('home')` when the font is not tree-shaken anyway |
| `ListTile` | `MaterialListTile` (from `unibox_material`) |
| `Theme.of(context).textTheme.titleLarge` | `MaterialTypography.titleLarge` |
| `Theme.of(context).colorScheme.primary` | `MaterialPalette.light.primary` (or `dark`), or `MaterialPalette.fromSeed(brand).primary`, passed into the tree |
| `ColorScheme.fromSeed(seedColor:, brightness:)` | `MaterialPalette.fromSeed(seed, isDark: true)`, whose roles are the ones that scheme answers |
| `MediaQuery`, `LayoutBuilder` | host work: measure there and pass the answer in |
| a third party widget | an `EmbedNode` that carries that `Widget` in `implementations` |
| reading a rendered page in an inspector | every element carries `data-unibox-node="spot-card"`; name a node with `debugLabel`, never with `key` |

### From HTML and CSS

| HTML / CSS | Unibox |
| --- | --- |
| `<div>` | `Box` |
| `display: flex; flex-direction: row` | `Box(direction: Axis.horizontal)` |
| `justify-content` / `align-items` | `mainAlign` / `crossAlign` |
| `gap` | `gap` |
| `padding` / `margin` | `padding` / `margin` (`BoxSpacing`) |
| `background-color` / `border-radius` | `backgroundColor` / `borderRadius` |
| `border: 1px solid #e5e7eb` | `border: BoxBorder(color: BoxColor.rgb(0xE5, 0xE7, 0xEB))` |
| `box-shadow` / `opacity` | `shadow` / `opacity` |
| `transform: scale(…)` | `transform: BoxTransform(scale: …)` |
| `color`, `font-size`, `font-weight`, `line-height`, `letter-spacing` | the same tokens on `TextNode` or `BoxTextStyle` |
| `overflow: hidden` / `auto` | `overflow: Overflow.hidden` / `Overflow.scroll` |
| `<a href>` | `LinkNode(url, child: …)` |
| `<img src alt>` | `ImageNode(src, alt: …)` |
| `<h1>`–`<h6>` | `TextNode('…', headingLevel: 1)` |
| `<main>`, `<nav>`, `<ul>`/`<li>`, `<article>` | `semantics: BoxSemantics(element: BoxElement.main)`, `.nav`, `.ul` + `.li`, `.article` |
| `:hover`, `:focus-visible`, `:active` | `stateStyles` / `hoverStyle` with a `BoxState` key |
| `@media (min-width: 900px)` | host work: Flutter measures, the web host uses CSS |
| `<input>`, `<textarea>` | `TextInputNode`, `TextInputNode(multiline: true)` |

## A component, end to end

A plan card. Every parameter here exists; nothing is a Flutter widget.

```dart
import 'package:unibox_core/unibox_core.dart';

/// A plan card: a title, a line of copy and a button, in one column.
UINode pricingCard({
  required String plan,
  required String price,
  required void Function() onChoose,
}) {
  return Box(
    width: 320,
    gap: 12,
    padding: BoxSpacing.all(20),
    backgroundColor: BoxColor.white,
    borderRadius: 16,
    border: BoxBorder(color: BoxColor.rgb(0xE5, 0xE7, 0xEB)),
    shadow: BoxShadow(
      color: BoxColor(0x14000000),
      offsetY: 6,
      blurRadius: 16,
    ),
    // Inherited by every text below it, the way a font property is in CSS.
    textStyle: BoxTextStyle(
      fontSize: 15,
      lineHeight: 1.5,
      color: BoxColor(0xFF111827),
    ),
    children: <UINode>[
      TextNode(plan, fontSize: 20, fontWeight: FontWeight.semiBold),
      TextNode(price),
      Box(
        direction: Axis.horizontal,
        mainAlign: MainAlign.center,
        padding: BoxSpacing.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: BoxColor.rgb(0x2D, 0x6C, 0xF3),
        borderRadius: 10,
        transition: BoxTransition(duration: Duration(milliseconds: 150)),
        hoverStyle: BoxStyle(backgroundColor: BoxColor.rgb(0x1D, 0x4E, 0xD8)),
        semantics: BoxSemantics(role: BoxRole.button, label: 'Choose $plan'),
        onTap: onChoose,
        children: <UINode>[
          TextNode(
            'Choose $plan',
            color: BoxColor.white,
            fontWeight: FontWeight.medium,
          ),
        ],
      ),
    ],
  );
}
```

What it demonstrates: a column with a `gap` instead of spacer boxes, typography set
once on the parent, a button built from a box that gains a hover look through a
state style, a transition that eases the change, and semantics that make the button
announce itself and take keyboard focus.

## State lives in a store

A tree that reacts needs state, and the model keeps that state in the tree without
making the tree mutable: a `StatefulNode` creates a store, the store holds one
immutable value, and the view is a plain function of that value.

```dart
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// What the page shows: the typed address and whether the dialog is open.
final class SignupState {
  const SignupState({this.email = '', this.open = false});

  final String email;
  final bool open;

  SignupState copyWith({String? email, bool? open}) =>
      SignupState(email: email ?? this.email, open: open ?? this.open);

  @override
  bool operator ==(Object other) =>
      other is SignupState && other.email == email && other.open == open;

  @override
  int get hashCode => Object.hash(email, open);
}

/// Every interaction of the page as one assignment.
final class SignupStore extends StateStore<SignupState> {
  SignupStore({bool open = false}) : super(SignupState(open: open));

  void setEmail(String value) => state = state.copyWith(email: value);
  void openDialog() => state = state.copyWith(open: true);
  void closeDialog() => state = state.copyWith(open: false);
}

/// The page as one node: the field, the trigger and, while it is open, the dialog.
final class SignupNode extends StatefulNode<SignupState, SignupStore> {
  SignupNode({bool open = false})
    : super(
        create: () => SignupStore(open: open),
        view: (SignupState state, SignupStore store) => Box(
          padding: BoxSpacing.all(24),
          gap: 12,
          children: <UINode>[
            TextInputNode(
              value: state.email,
              placeholder: 'you@example.com',
              inputType: InputType.email,
              onChanged: store.setEmail,
            ),
            Box(
              padding: BoxSpacing.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: BoxColors.blue,
              borderRadius: 10,
              semantics: const BoxSemantics(
                role: BoxRole.button,
                label: 'Sign up',
              ),
              onTap: store.openDialog,
              children: const <UINode>[
                TextNode('Sign up', color: BoxColors.white),
              ],
            ),
            if (state.open)
              OverlayNode(
                onDismiss: store.closeDialog,
                child: MaterialCard(
                  width: 360,
                  gap: 8,
                  children: <UINode>[
                    const TextNode(
                      'Join Unibox',
                      style: MaterialTypography.headlineSmall,
                    ),
                    TextNode('We will email ${state.email}.'),
                    Box(
                      padding: BoxSpacing.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      backgroundColor: BoxColors.blue,
                      borderRadius: 10,
                      semantics: const BoxSemantics(
                        role: BoxRole.button,
                        label: 'Confirm',
                      ),
                      onTap: store.closeDialog,
                      children: const <UINode>[
                        TextNode('Confirm', color: BoxColors.white),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
```

What it shows: the state is one value, every callback is an assignment on the store,
and the dialog is simply absent while `open` is false. There is no `setState`, no
modal call and no overlay slot anywhere.

The host is then small, because it only supplies what a node cannot know:

```dart
// Flutter: the node owns the state, the host owns the surface.
MaterialApp(
  home: Scaffold(body: FlutterStateful(node: SignupNode())),
);
```

The Jaspr host is the same shape: subclass `JasprStateful`, return the node from
`createNode()`, and let the document own the `html`/`body` height and the font. Both
hosts of the example are one small file each, and
[`example/unibox_example_shared/lib/src/page_node.dart`](example/unibox_example_shared/lib/src/page_node.dart)
is the long form of the node above.

When a host really has to own a value — the route, the window width, something that
outlives every node — it passes it into the node as a parameter, the way the example
passes the form a static document starts with. What it must not do is keep a value
the tree could have kept: that is the drift the model exists to prevent.

## Before you return the code

- The file that holds the tree imports `package:unibox_core/unibox_core.dart` — and
  `package:unibox_material/unibox_material.dart` when it uses the Material roles or
  components — and nothing else. No Flutter, no Jaspr, no `dart:ui`.
- `dart analyze` is clean, and `core.validateTree(tree)` reports no errors. It
  catches a positioned node outside a stack, a link inside a link, a scrolling box
  that also distributes its children, a transition that changes nothing, and a
  dismissible barrier with no `onDismiss`.
- Every list and map is typed — `<UINode>[...]`, `<BoxState, BoxStyle>{...}` — because
  a mixed literal otherwise infers an element type that is not the one the node takes.
- A dialog is an `OverlayNode` in the tree, not a `StackNode` with a positioned box
  and not a call on a host: absent while it is closed, present while it is open.
- A tree that reacts is a `StatefulNode` with a store — no `setState`, no controller,
  no mutable field on a node, and the view returns one tree.
- Nothing in the tree reads a clock, a window, a theme or global state.
- Buttons and links carry `semantics`; images carry `alt`; headings use
  `headingLevel` rather than a larger font.
- A list that can reorder passes `key:`, and the key is the id of the row, not its
  index.
- If a widget or a plugin is needed that Unibox does not model, it is an `EmbedNode`
  with one implementation per renderer — never a host widget smuggled into a box.

## Where the rest of the API is

| Need | Read |
| --- | --- |
| Every `Box` parameter and its default | [`README.md#box`](README.md#box) |
| Text, typography and inheritance | [`README.md#textnode`](README.md#textnode), [`#typography`](README.md#typography) |
| Images, links, stacks, inputs, embeds | [`#imagenode`](README.md#imagenode), [`#linknode`](README.md#linknode), [`#stacknode-and-positionednode`](README.md#stacknode-and-positionednode), [`#textinputnode`](README.md#textinputnode), [`#embednode`](README.md#embednode) |
| A dialog, a sheet, a banner | [`#overlaynode`](README.md#overlaynode), and the policy in [`packages/unibox_core/README.md#overlays`](packages/unibox_core/README.md#overlays) |
| State, a store and a lifecycle | [`#statefulnode`](README.md#statefulnode), and the rules in [`packages/unibox_core/README.md#state`](packages/unibox_core/README.md#state) |
| Material type roles and components | [`packages/unibox_material/README.md`](packages/unibox_material/README.md) |
| What has to look the same on both | [`packages/unibox_testing/README.md`](packages/unibox_testing/README.md) |
| Motion, states and semantics | [`#motion`](README.md#motion), [`#semantics`](README.md#semantics) |
| What the tree leaves to the host | [`#what-the-host-owns`](README.md#what-the-host-owns) |
| The model's defaults, and why | [`packages/unibox_core/README.md`](packages/unibox_core/README.md) |
| Complete trees to copy | [`example/unibox_example_shared/lib/src/`](example/unibox_example_shared/lib/src/) |
| What a token becomes on each target | [`packages/unibox_flutter/README.md`](packages/unibox_flutter/README.md), [`packages/unibox_jaspr/README.md`](packages/unibox_jaspr/README.md) |


