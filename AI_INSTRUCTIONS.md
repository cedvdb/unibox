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
Do not use Flutter or HTML widgets. Return the tree, and separately the small
host that renders it.
```

## The model in eight lines

- A screen is an immutable Dart tree of nodes: `Box`, `TextNode`, `ImageNode`, `LinkNode`
  (a `Box` that names a destination), `StackNode` + `PositionedNode`, `TextInputNode`,
  `StatefulNode`, `OverlayNode`, `GridNode`, `EmbedNode`.
- One tree, two renderings: `renderFlutter(tree, theme: …)` or `tree.toWidget(theme: …)`
  in a Flutter app, and `toDocument(tree, theme: …)` or `tree.toHtml(theme: …)` in
  `unibox_html` for a page a crawler reads. A tree that names colour roles needs the
  theme on both targets — leaving it out is a validation error naming the role, not a
  fallback to a host colour.
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
  `MaterialPalette.fromSeed(seed, variant:, isDark:, contrastLevel:)`), and fifteen
  components built on nodes the
  renderers already draw — `MaterialCard`, `MaterialListTile`, `MaterialButton`,
  `MaterialIconButton`, `MaterialChip`, `MaterialSegmentedButton`, `MaterialNavigationBar`
  and `MaterialIcon` are `Box` subclasses, `MaterialInkWell` and `MaterialTextField` are `StatefulNode`s
  (the ink a press spreads; the text, the focus and whether the field has been
  touched), `MaterialCheckMark` is a `StackNode` (Material's tick, drawn, so a
  chosen control needs no font), `MaterialProgressRing` is a `Box` and `MaterialSpinner`
  a `StatefulNode` (a value, and the value nobody knows), and `MaterialDialog` and
  `MaterialBottomSheet` are
  `OverlayNode`s. The palette is a value the tree wears —
  pass the roles into the builders; there is no `Theme` lookup at render time.
  Wiring the same roles into the platform (`ColorScheme`, CSS custom properties) is
  the application's job.


## The rules that make generated code run

1. **Import the tree with a prefix.** `Axis`, `TextAlign`, `FontWeight`,
   `TextOverflow`, `BoxBorder` and `BoxShadow` also exist in Flutter. In any file
   that imports Flutter:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:unibox_core/unibox_core.dart' as core;
   ```

   Better: keep the tree in a library that imports no renderer at all, the way
   `example/unibox_example_shared/` does, and let the host import both.
2. **The node names are not Flutter's.** `TextNode`, not `Text`; `ImageNode`, not
   `Image`; `StackNode`, `PositionedNode`, `LinkNode`. `Box` keeps its bare name because
   Flutter has no `Box`.
3. **Flat parameters beat style bags.** `Box.computedStyle` merges `styles`
   left to right, then the flat parameters. A state style
   (`hoverStyle`, `stateStyles`) overlays the resting one; `disabled` overlays all.
4. **A box is a column by default, and it hugs.** `direction` unset means
   `Axis.vertical`, and `mainAlign` and `crossAlign` default to `start` — not Flutter's
   `center` cross alignment and not CSS's `stretch`. Two consequences are worth
   reading twice, because both fail silently:

   - a column hugs every child to its content, so a band does not reach the page width
     until the column says `crossAlign: CrossAlign.stretch` — and a
     `width: double.infinity` inside it needs that too, or the two targets disagree
     about a `100%` with no parent width;
   - a horizontal box is a `Row(mainAxisSize: min)`, so `mainAlign: spaceBetween`
     distributes nothing unless the parent gave the row a width. A row that must
     distribute is inside a column that stretches, or has a `width`.

   Say what you mean: `direction`, `crossAlign: CrossAlign.stretch` on a band, and a
   width on a row that distributes.
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
11. **A link is a destination; a button is an action.** A place a reader can go is a
    `LinkNode` — a box that names a destination, so the whole control is the `<a href>`
    a page without a client runtime follows and a crawler reads, and a picture or a line
    of text is the same node around that leaf. A control that opens a dialog or changes something in
    place is a `Box(onTap: …)` with the button role, and it carries no url: a press that
    is both a dialog and a page load is the flash a reader sees before the dialog they
    asked for. A control inside a link is invalid HTML and `validateTree` reports it —
    put the two beside each other.
12. **Key a list.** Children of a list that can reorder take `key:` — the id of the
    model they describe — or typed text follows the position instead of the row. The
    same key is written on the element the node drew (`data-unibox-key`), so give it a
    `String` or an `int` and keep it unique when something outside the tree has to find
    that element again — a control that a page should be able to press on the app's
    behalf, a box that scrolls.
13. **A callback is half a feature.** A `Box(onTap: …)` in Flutter binds itself; on the web the same
    node needs `unibox_dom`'s `events.dart` to know it. A component whose control answers in the app and
    not on the page is that gap, and it is silent — nothing throws.

14. **A pager you tell a page to, you must not listen to.** `Box(page: …)` moves the box, and
    `Box(onScroll: …)` reports every offset of that move: read as the reader's, they undo the
    press that started it, and the tab a reader chose never appears chosen. Keep the two apart
    — a field naming the page you sent it to, cleared when the offset arrives there — or keep
    one direction only.

15. **Copy is a value, and the locale is an argument.** The tree holds strings, so a
    translation is another call of the same builder: pass a `const` copy object
    (`SiteCopy.de`) into it and never read `Localizations.of(context)` inside it. A tree
    that reads the locale from a context cannot be rendered as a document — `toDocument`
    runs with no context — so the app's language would then decide whether the page can
    exist at all.

16. **Do not invent a parameter.** If it is not in the README tables or in
    `packages/unibox_core/lib/src/`, it does not exist. For anything the model cannot
    express, use an `EmbedNode` with one implementation per renderer, or ask.

## Translating what a model already knows

### From Flutter

| Flutter | Unibox |
| --- | --- |
| `Container`, `Padding`, `SizedBox` | `Box(padding:, margin:, width:, height:)` |
| `AspectRatio(aspectRatio: 1.5, child: …)` | `aspectRatio: 1.5` on the box |
| `Column(children: …)` | `Box(children: …)` — a column is the default |
| `Row(children: …)` | `Box(direction: Axis.horizontal, children: …)` |
| `Directionality(textDirection: TextDirection.rtl, child: …)` | `writingDirection: WritingDirection.rtl` on the box that owns the region — inherited, like the widget |
| `mainAxisAlignment` / `crossAxisAlignment` | `mainAlign` / `crossAlign` |
| `CrossAxisAlignment.baseline` | `crossAlign: CrossAlign.baseline` on a **row** — on a column `validateTree` reports it, because Flutter draws it as `start` and a browser shifts the children sideways |
| `Expanded(child: …)` | `flex: 1` on the child box |
| `SizedBox(height: 8)` between children | `gap: 8` on the parent |
| `Colors.white`, `Color(0xFF112233)` | `BoxColor.white`, `BoxColor(0xFF112233)` |
| `Colors.grey`, `Colors.red`, `Colors.blueGrey` | `BoxColors.grey`, `BoxColors.red`, `BoxColors.blueGrey` — the same values |
| `Color.fromRGBO(r, g, b, opacity)` | `BoxColor.rgba(r, g, b, alpha)` — its alpha is `0`–`255`, or `BoxColor.rgb(r, g, b).withOpacity(0.5)` |
| `EdgeInsets.all(16)` | `BoxSpacing.all(16)` (`.symmetric`, `.only`, `.zero`) |
| `BoxDecoration(color:, border:, borderRadius:)` | `backgroundColor`, `border`, `borderRadius` |
| `BoxShadow(color:, offset:, blurRadius:, spreadRadius:)` | `shadows: <BoxShadow>[BoxShadow(...)]` — same names, and a list because an elevation is several layers |
| `Text('Hi', style: TextStyle(…))` | `TextNode('Hi', fontSize:, fontWeight:, color:, lineHeight:)` |
| `TextStyle.height` | `lineHeight`, a **multiple** of the font size (`1.5`, not `24`) |
| `TextStyle.decoration`, `TextDecoration.lineThrough`, `decorationColor` | `decoration: TextDecoration.lineThrough`, `decorationColor:`, `decorationThickness:` — `none`, `lineThrough`, `underline`; `overline` has no Flutter counterpart |
| `DefaultTextStyle` | `Box(textStyle: BoxTextStyle(...))`, inherited by the texts inside |
| `Image.network(src, fit:)` | `ImageNode(src, fit: ImageFit.cover, alt: '…')` |
| `GestureDetector(onTap:)` | `Box(onTap: …)` |
| `Navigator.push`, `go_router`, an `InkWell` that goes somewhere | `LinkNode('/rooms/1', …)` — a box that names a destination, so it *is* the `<a href>`: one href for the crawler, a real press for a reader without the runtime, and the box keeps its ripple. `newTab: true` adds `target`/`rel` on the web. Give it an `onTap` only when the tree must answer the press instead of navigating |
| `Hyperlink` around a picture or a line of text | `LinkNode(url, children: <UINode>[theLeaf])` — the leaf form, and the same node a button uses |
| `Row` of `Expanded` children, a `Table` of equal columns, `grid-template-columns: 1fr 2fr 1fr` | `GridNode.columns(<int>[1, 2, 1], children: …)` — one column per child, and the factor is the `1fr` of CSS and the `flex` of `Expanded`. Every column is the widest content per unit, or an equal part of the width the grid was given. A child states neither a `flex` nor a width (`validateTree` reports both, and a `gridSpan`), because the column is the grid's answer, and a rule *between* two columns is a `PositionedNode` inside the child beside it, layered over it |
| `MouseRegion` | `Box(onHover: (bool hovered) { … })` |
| `Opacity(opacity:)` | `opacity:` on the box |
| `Transform.scale`, `Transform.rotate` | `transform: BoxTransform(scale:, rotation:, offsetX:, offsetY:)` |
| `AnimatedContainer` | `transition: BoxTransition(...)` plus a `BoxState` style |
| `ClipRRect` | `overflow: Overflow.hidden` with `borderRadius` |
| `CircularProgressIndicator` | `MaterialProgressRing(value:, size:, thickness:)` — the ring is a `BoxShape.ring`, so a determinate bar is one node; `MaterialSpinner()` is the value nobody knows |
| `ClipPath`, `ShapeBorder`, `clip-path` | `Box(shape: BoxShape(...))` — a path in a view box, which the fill, the border and (with `overflow: Overflow.hidden`) the clip all follow; `BoxFillRule.evenOdd` makes a ring |
| `BorderRadius.vertical(top:)`, `BorderRadius.only(...)` | `corners: BoxBorderRadius(topLeft:, topRight:)` — a box that is not round on all four |
| `SingleChildScrollView` | `Box(overflow: Overflow.scroll)` |
| `Wrap` | `Box(wrap: true, gap:, mainAlign:, crossAlign:)` — `gap` is both the space between two children and between two lines, and the alignments keep their meaning per line, which is what `flex-wrap: wrap` does. A box cannot both wrap and scroll, a `flex` child cannot grow in a wrap, and a `crossAlign` of `stretch` or `baseline` means nothing in one: `validateTree` reports all three |
| `Stack` + `Positioned` | `StackNode` + `PositionedNode` |
| `Semantics(button: true, label:)` | `semantics: BoxSemantics(role: BoxRole.button, label: …)` |
| `Semantics(button: true, toggled: true)`, `aria-pressed` | `semantics: BoxSemantics(role: BoxRole.button, pressed: true)` — a toggle button, which is what a chip and a segment are; `selected` is for the item of a set (an option, a tab) and a browser ignores it on a button |
| `TextField` | `TextInputNode(value:, placeholder:, inputType:, onChanged:)`, or `MaterialTextField(label:, validator:, onChanged:)` for Material's frame, which validates itself once the field has been touched |
| `FilledButton`, `TextButton`, `OutlinedButton`, `ElevatedButton` | `MaterialButton.filled(…)`, `.text(…)`, `.outlined(…)` or `.tonal(…)` — a label on a fill with the ink of a press; all four paint 40 tall and at least 64 wide, and `padding`, `height`, `minWidth` and `iconGap` restyle them |
| `showDialog`, `Dialog` | `MaterialDialog(title:, content:, actions:, onDismiss:)` — an `OverlayNode`, not a call |
| `showModalBottomSheet` | `MaterialBottomSheet(title:, content:, actions:)` — the same overlay at the bottom |
| `SegmentedButton`, a `ToggleButtons` row | `MaterialSegmentedButton(segments:, selected:, onSelect:)` — one pill of equal segments, the chosen one filled: a segment is always as wide as the widest one, whether or not the control has a `width`, which is what a segmented button is. `border` is the line around the pill and between its segments. A segment with a `url` is a destination: one `<a href>` per unchosen choice, no `onSelect`, and `aria-current` on the chosen one |
| `NavigationBar`, `BottomNavigationBar` | `MaterialNavigationBar(destinations:, selected:, onSelect:)` — one 80 pixel row of equal shares, the chosen destination on a `secondaryContainer` pill; where it sits is the tree's business, so being at the bottom is the last row of a column or a `PositionedNode` |
| `Chip`, `FilterChip`, `ChoiceChip` | `MaterialChip(label:, selected:, leading:, onTap:)` — 32 pixels tall, an outline when unselected, the secondary container when chosen; `padding`, `height` and `gap` make a denser one, and `onRemove` adds a close target whose name is `removeSemanticsLabel` |
| `Icon(Icons.check)`, under a chosen chip or segment | `MaterialCheckMark(color:, size:)` — Material's tick drawn from two bars, no font asset needed |
| `InkWell`, `InkResponse` | `MaterialInkWell(onTap:, borderRadius:, ink:, child:)` — a state layer plus the ink a press spreads; it paints no surface, so the filled box goes around it. `url:` makes it a destination instead of a callback, and `fill:`/`border:`/`shadows:` give it the surface so one node can be a whole control |
| `StatefulWidget` + `setState` around a tree | `StatefulNode` + a `StateStore` |
| `GridView`, a `Wrap` of cards | `GridNode(minItemWidth:, maxColumns:, gap:)` — equal columns that follow the width, no breakpoint; a card that interrupts the row states `gridSpan:` on its box |
| `Card` | `MaterialCard` (from `unibox_material`) — surface only: it has no padding and no press, so `Card(child: InkWell(…))` becomes `MaterialCard(children: [MaterialInkWell(url: …, padding: BoxSpacing.all(16), child: …)])` |
| `Icon` | `MaterialIcon.codePoint(Symbols.home.codePoint)`, or `MaterialIcon.ligature('home')` when the font is not tree-shaken anyway |
| `IconButton`, `FilledButton.tonalIcon` around one glyph | `MaterialIconButton(icon:, label:, onTap:, variant:, badgeCount:)` — a glyph in a 40 pixel square in the four Material 3 shapes, `label` for a screen reader because a glyph names nothing, and `badgeCount` for the count pill over the corner |
| `ListTile` | `MaterialListTile` (from `unibox_material`) |
| `Theme.of(context).textTheme.titleLarge` | `MaterialTypography.titleLarge` |
| `Theme.of(context).colorScheme.primary` | `MaterialPalette.light.primary` (or `dark`), or `MaterialPalette.fromSeed(brand).primary`, passed into the tree |
| `ColorScheme.fromSeed(seedColor:, brightness:)` | `MaterialPalette.fromSeed(seed, isDark: true)`, whose roles are the ones that scheme answers |
| `MediaQuery`, `LayoutBuilder` | host work: measure there and pass the answer in |
| `Localizations.of(context).title`, an `.arb` lookup in the tree | `SiteCopy.de.title` — a `const` value per language, passed into the builder; the host chooses which one from the address |
| a third party widget | an `EmbedNode` that carries that `Widget` in `implementations` |
| reading a rendered page in an inspector | every element carries `data-unibox-node="spot-card"`; a keyed node also carries `data-unibox-key="<key>"` when the key is a `String` or an `int`; name a node with `debugLabel`, never with `key` |

### From HTML and CSS

| HTML / CSS | Unibox |
| --- | --- |
| `<div>` | `Box` |
| `display: flex; flex-direction: row` | `Box(direction: Axis.horizontal)` |
| `dir="rtl"`, `direction: rtl` | `writingDirection: WritingDirection.rtl` on the region, or `toDocument(writingDirection: …)` for the page — a language is not a direction, so `lang="ar"` says nothing about it |
| `justify-content` / `align-items` | `mainAlign` / `crossAlign` |
| `gap` | `gap` |
| `padding` / `margin` | `padding` / `margin` (`BoxSpacing`) |
| `background-color` / `border-radius` | `backgroundColor` / `borderRadius` |
| `border: 1px solid #e5e7eb` | `border: BoxBorder(color: BoxColor.rgb(0xE5, 0xE7, 0xEB))` |
| `box-shadow` / `opacity` | `shadows` / `opacity` |
| `transform: scale(…)` | `transform: BoxTransform(scale: …)` |
| `color`, `font-size`, `font-weight`, `line-height`, `letter-spacing` | the same tokens on `TextNode` or `BoxTextStyle` |
| `text-decoration: underline`, `text-decoration-color` | `decoration: TextDecoration.underline`, `decorationColor:` — `none`, `lineThrough`, `underline`; `double`, `wavy` and `overline` are not in the model, because Flutter draws one solid line and has no overline |
| `overflow: hidden` / `auto` | `overflow: Overflow.hidden` / `Overflow.scroll` |
| `position: sticky; top: 0` | `pin: BoxPin.start`, on a child of the box that scrolls, with the band's `height` stated: it stays at the edge of that box and keeps its slot in the flow. `bottom: 0` is `BoxPin.end`; the `<header>` above it is `pinOffset:` — the same number as the header's height |
| an animation driven by the scroll (`animation-timeline: view()`, `@keyframes`) | `fold: BoxFold(to: BoxStyle(…))` on the box that leaves: paint tokens only, and `over:` for the share of its exit the fold takes |
| `<a href>` | `LinkNode(url, …)`, which *is* the `<a href>` |
| `<a>` with no `href` | `semantics: BoxSemantics(element: BoxElement.a)`: a placeholder that nothing follows |
| `<img src alt>` | `ImageNode(src, alt: …)` |
| `<h1>`–`<h6>` | `TextNode('…', headingLevel: 1)` |
| `<main>`, `<nav>`, `<ul>`/`<li>`, `<article>` | `semantics: BoxSemantics(element: BoxElement.main)`, `.nav`, `.ul` + `.li`, `.article` |
| `:hover`, `:focus-visible`, `:active` | `stateStyles` / `hoverStyle` with a `BoxState` key |
| `@media (min-width: 900px)` | host work: Flutter measures, the web host uses CSS |
| `<input>`, `<textarea>` | `TextInputNode`, `TextInputNode(multiline: true)` |
| `<html lang="de">`, `<link rel="alternate" hreflang="en">`, a `/de/…` prefix | `toDocument(lang: 'de', head: DocumentHead(alternates: {'de': …, 'en': …}))` — one document per language, the locale taken from the address |

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
    shadows: <BoxShadow>[
      BoxShadow(color: BoxColor(0x14000000), offsetY: 6, blurRadius: 16),
    ],
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

The web host is smaller still: `toDocument(tree, head: DocumentHead(title: …))` writes the page,
and the host only states the document's own metadata — the title, the head, the font it ships.
Both hosts of the example are one small file each, and
[`example/unibox_example_shared/lib/src/page_node.dart`](example/unibox_example_shared/lib/src/page_node.dart)
is the long form of the node above.

When a host really has to own a value — the route, the window width, something that
outlives every node — it passes it into the node as a parameter, the way the example
passes the form a static document starts with. What it must not do is keep a value
the tree could have kept: that is the drift the model exists to prevent.

## A page that becomes the application

Two files, one on each side. The server writes a document; the application reads what the
reader did before it existed.

```dart
// the server, or a build step
final String page = toDocument(
  ListingsPage(listings),
  head: const DocumentHead(title: 'Apartments'),
  takeover: const Takeover(boot: '../../flutter/app.js'),
);
```

```dart
// the application
void main() => runApp(
  ExampleApp(
    offsets: scrollOffsetsFromPage(),   // where a region was scrolled to
    presses: pressesFromPage(),         // what was pressed
  ),
);
```

- **`toDocument` is synchronous and needs no framework.** It writes one `<style>`, the head and the
tree; it runs in a build step, a CLI or a server.
- **`Takeover` is one argument, not three.** It prefetches the bundle, places the recorders before
  the boot, and starts the boot on a signal. Do not assemble those by hand: swapping `prefetch` and
  `scripts` ships a page that boots on a cold cache.
- **A scrolling region needs a `key`.** The recorder writes `data-unibox-key`, and the application
  finds the region by that key. Without one there is nothing to replay.
- **The scroll comes back as the controller's initial position**, so a region is in place at the
  first layout; a record whose key is not the box is ignored.
- **A press is data and is answered once.** `FlutterStateful(presses: …)` replays it against the
  first view it builds, which is where the callbacks exist. A key that matches no node, two nodes
  or a node with no behaviour is dropped — never fire whatever is nearby.
- **Do not expect a string to run a callback.** A document carries text, not closures: a press is
  replayed by the application, not by the page, and a link is followed by the browser.

## An image the host knows how to draw

`ImageNode` is the model's picture: a source, an alt, a size, a fit. On Flutter it renders
`Image(image: NetworkImage(src))`, which has no disk cache, no placeholder and no key that
depends on the space it is drawn in — and the model has no token for any of those, because a
cache and a placeholder are policies of an application, not values of a design.

The answer is the escape hatch the model already has: **the tree takes the image it should
draw as a function**, and the host passes the function.

```dart
// image_spec.dart — in the package that holds the trees; imports unibox_core only
/// The image a layout asks for: what it is, where it goes and how big.
class ImageSpec {
  const ImageSpec({
    required this.src,
    this.alt = '',
    this.height,
    this.fit = ImageFit.cover,
    this.priority = false,
  });

  final String src;
  final String alt;
  final double? height;
  final ImageFit fit;

  /// The one picture above the fold, so the host may fetch it first.
  final bool priority;
}

/// What a tree draws when the host offers nothing of its own.
UINode defaultImage(ImageSpec spec) => ImageNode(
  spec.src,
  alt: spec.alt,
  height: spec.height,
  fit: spec.fit,
  loading: spec.priority ? ImageLoading.eager : ImageLoading.lazy,
  fetchPriority: spec.priority ? ImageFetchPriority.high : ImageFetchPriority.auto,
);
```

Every builder that draws a picture takes `UINode Function(ImageSpec) image` and calls it:
`image(const ImageSpec(src: '…', alt: 'A bright room', height: 220))`. The tree still says
*which* picture and *how big*; the host decides how it is fetched and what is on screen
until it arrives.

```dart
// main.dart — the Flutter host, the one file that knows what a cache is
final UINode page = ListingsPage(
  listings,
  image: (ImageSpec spec) => FlutterWidgetNode(
    // whatever the app already uses: a disk cache, a placeholder of the same height,
    // a blurhash, a key that includes the width it is drawn at
    YourCachedImage(
      url: spec.src,
      height: spec.height,
      fit: spec.fit,
      semanticsLabel: spec.alt,
    ),
  ),
);
```

**The consequence, because it bites a server.** An `EmbedNode` carries a payload for one
target, so a tree built with a host's image function is *that host's tree*: it renders in
the app and the web renderer reports an embed it cannot draw. The server, the static
export, the crawler and the test build the same page with `defaultImage`, which is why the
function is a parameter rather than something the tree reaches for. One builder, two
values — and never a Flutter import in the library that holds the trees.

## A page in more than one language

The tree holds strings, so a translation is another value of the same builder — never an ambient
lookup.

```dart
// site_copy.dart — one const value per language, in your own package
abstract final class SiteCopy {
  const SiteCopy({required this.title, required this.cta});

  final String title;
  final String cta;

  static const SiteCopy en = SiteCopy(title: 'Apartments', cta: 'See the listings');
  static const SiteCopy de = SiteCopy(title: 'Wohnungen', cta: 'Zu den Angeboten');

  static SiteCopy of(String tag) => switch (tag.split('-').first) {
    'de' => de,
    _ => en,
  };
}

// the builder takes the copy, so a missing string is a compile error in every language
UINode buildListingsPage(SiteCopy copy) => … TextNode(copy.title) …
```

- **Pass the locale in; do not read it.** `Localizations.of(context)` needs a `BuildContext`, and
  `toDocument` renders with none — it is synchronous and framework-free. A tree that reads the
  locale can only ever be a widget, so the app's language decides whether the page exists.
- **A `const` class per language beats a `Map<String, String>`.** A missing key in a map is a blank
  on one page at runtime; a missing `required` field is a compile error in every language. Move to
  `.arb` and `intl` (plurals, dates, numbers, collation) when the catalogue outgrows a file — in
  your package, never in the tree.
- **Ship the copy and the routes together.** A German page whose links and canonical still point at
  the English addresses is the bug localised sites actually have: take both from the language tag.
- **The address is the locale.** `/de/…`, not a cookie or `Accept-Language`, because a crawler
  sends neither. A language switch is a `LinkNode` to the other address — followable and
  crawlable like any other link — and a language change inside the app is a
  `Store` publish.
- **One document per language, each naming the whole set.** `lang` is what it is written in —
  an attribute of the root element rather than a head element — and the head carries
  `canonical`, its own address, and `alternates`, the others:

  ```dart
  final String page = toDocument(
    buildListingsPage(SiteCopy.de),
    lang: 'de',
    head: DocumentHead(
      title: SiteCopy.de.title,
      canonical: 'https://example.com/de/apartments/',
      alternates: <String, String>{
        'de': 'https://example.com/de/apartments/',
        'en': 'https://example.com/apartments/',
        'x-default': 'https://example.com/apartments/',
      },
    ),
  );
  ```

  Without `alternates` a search engine sees translated copies of one page and keeps one of them.

## Before you return the code

- The file that holds the tree imports `package:unibox_core/unibox_core.dart` — and
  `package:unibox_material/unibox_material.dart` when it uses the Material roles or
  components — and nothing else. No Flutter, no web framework, no `dart:ui`.
- The theme travels with the call that draws the tree: `toWidget(theme: …)`,
  `renderFlutter(…, theme: …)`, `toDocument(…, theme: …)`. A tree that names
  `BoxColor.role(...)` and is drawn without one fails validation by naming the role,
  so this is the first thing an error about a colour means.
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
| Images, links, stacks, inputs, embeds | [`#imagenode`](README.md#imagenode), [`#links`](README.md#links), [`#stacknode-and-positionednode`](README.md#stacknode-and-positionednode), [`#textinputnode`](README.md#textinputnode), [`#embednode`](README.md#embednode) |
| A dialog, a sheet, a banner | [`#overlaynode`](README.md#overlaynode), and the policy in [`packages/unibox_core/README.md#overlays`](packages/unibox_core/README.md#overlays) |
| State, a store and a lifecycle | [`#statefulnode`](README.md#statefulnode), and the rules in [`packages/unibox_core/README.md#state`](packages/unibox_core/README.md#state) |
| Material type roles and components | [`packages/unibox_material/README.md`](packages/unibox_material/README.md) |
| What has to look the same on both | [`packages/unibox_testing/README.md`](packages/unibox_testing/README.md) |
| Motion, states and semantics | [`#motion`](README.md#motion), [`#semantics`](README.md#semantics) |
| What the tree leaves to the host | [`#what-the-host-owns`](README.md#what-the-host-owns) |
| The model's defaults, and why | [`packages/unibox_core/README.md`](packages/unibox_core/README.md) |
| Complete trees to copy | [`example/unibox_example_shared/lib/src/`](example/unibox_example_shared/lib/src/) |
| What a token becomes on each target | [`packages/unibox_flutter/README.md`](packages/unibox_flutter/README.md), [`packages/unibox_html/README.md`](packages/unibox_html/README.md) |


