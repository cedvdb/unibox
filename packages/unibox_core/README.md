# unibox_core

Platform agnostic Unibox AST, style tokens and layout types.

This package has zero external dependencies: it never imports `dart:ui`,
Flutter or the web renderer. Renderers live in `unibox_flutter`, `unibox_css` and `unibox_html`.

## Nodes and tokens

| Type              | Purpose                                                      |
| ----------------- | ------------------------------------------------------------ |
| `Box`             | flex container, the primary building block                    |
| `LinkNode`        | a `Box` that names a destination: the link a press follows    |
| `TextNode`        | a run of text                                                 |
| `ImageNode`       | a network or bundled image                                    |
| `StackNode`       | layered children, with `PositionedNode` placing them           |
| `TextInputNode`   | a single line or multiline field                              |
| `StatefulNode`    | a subtree that owns a `Store` and draws the tree of its state |
| `GridNode`        | equal columns whose count follows the width of the box         |
| `OverlayNode`     | content drawn above the page, with a barrier and a dismissal |
| `Store`           | the state contract a `StatefulNode` draws                     |
| `StateStore`      | the ready made `Store`: one state value and its listeners     |
| `BoxColor`, `BoxColors`, `BoxSpacing`, `BoxBorder`, `BoxShadow` | visual tokens            |
| `BoxAlignment`    | where a child sits in a stack cell: nine positions, and a `Start` or an `End` follows the writing direction |
| `BoxShape`, `BoxPathCommand`, `BoxFillRule` | an outline a box is painted in            |
| `BoxStyle`        | a bundle of every layout and visual token                     |
| `BoxTextStyle`    | a bundle of typography tokens                                 |

## Default typography

`BoxTextStyle.defaults` is the typography a text is typeset in when the tree says
nothing else: 16 logical pixels, `FontWeight.normal`, black, a line height of 1.5
and no letter spacing. Both renderers apply it to the root of the tree they
render, so an undeclared text looks the same on both targets.

It has to live here rather than in a host, because the two hosts do not agree:
Flutter falls back to 14 logical pixels of black, a browser to 16 pixels of
`canvastext` — a colour that flips in a dark theme — at a `normal` line height. A
default that lives in the host is exactly the drift this package exists to
prevent.

The font family is the one token the default leaves unset, because a font file is
an asset of the application and not of the model. Unset means the platform's UI
font: the engine default in Flutter, the generic `system-ui` family in CSS.

## Defaults

A tree says what it wants and nothing else, so every unset token needs an answer,
and the answer has to be the model's — the two platforms would each give their own
and the difference would show:

| Unset | The model's answer |
| --- | --- |
| `Box.direction`, `mainAlign`, `crossAlign` | a column, laid out from the start (`BoxStyle.resolvedDirection`) |
| any typography token | `BoxTextStyle.defaults` |
| `decoration` | no line; and a line a box states reaches every text inside it, so a text that states its own below it is reported |
| `ImageNode.fit` | `ImageFit.scaleDown` (`ImageNode.resolvedFit`), i.e. `BoxFit.scaleDown` and `object-fit: scale-down` |
| `TextInputNode` chrome | none on either target: no border, padding, background, focus ring or resize grip, and the typography of the tree |
| `StackNode` clipping | none, and a child that is not positioned keeps its own size |
| `Box.shape` | the rectangle: a box paints its border box, and a corner radius rounds it |

Writing direction is the one token with no answer in this table, and the reason is in the
model rather than in a host: a direction belongs to the script the words are written in,
and the model cannot read words it did not write. A box that says nothing inherits from
the box above it, so a tree written right to left states it once, at its root — and
`toDocument(writingDirection: …)` is the same statement for the page, written as the `dir`
of `<html>`. Resolving a default here would either force left to right over a page that is
correctly Arabic, or guess from a `lang` — and a language is not a direction, because
Azerbaijani, Kurdish and Punjabi are written in both scripts.
| `Box.gridSpan` | one track: a card covers one column, and only a grid child covers more |
| `Box.wrap` | off: a box is one line, and a child that does not fit runs past its edge until the box says otherwise |
| `Box.equalShares` | off: a row lays each child out at its own size, and only a box that says so makes every child as wide as the widest one |
| `Box.pinOffset` | zero: a pinned band keeps none of the edge it pins to (`BoxStyle.resolvedPinOffset`) |
| a link's paint | the browser's blue and underline: cancelled on an anchor, so a link looks like the box that states it |
| `LinkNode.url` | nowhere on a `Box`, which is a container: a destination is the node's own field, and a disabled link writes no `href` |
| `LinkNode` inside a link | reported: a link inside a link navigates twice |

What is left to the host, because only the host can answer it: the font family (a
font file is an asset), the colour of a placeholder, a caret or a selection, the
look of a scrollbar, and the rendering of the glyphs themselves.

## Roles and the theme

A colour can name a **role** instead of carrying channels, and the application says
what the role is worth:

```dart
enum AppColor { primary, surface, outline }

const theme = UniboxTheme(
  colors: <AppColor, BoxColor>{
    AppColor.primary: BoxColor(0xFF2D6CF3),
    AppColor.surface: BoxColor(0xFFFFFFFF),
    AppColor.outline: BoxColor(0xFFE5E7EB),
  },
);

const Box(backgroundColor: BoxColor.role(AppColor.primary));
```

- The role is an **enum member**, so a misspelling is a compile error, and the
theme's map is keyed by the same value: no string is typed anywhere.
- The tree stays `const` and still says what it means — "this is the primary
  surface" — instead of repeating a hex value per element.
- `BoxColor.role(...)` has no channels until a theme answers it. Reading `value`
  before that throws, and `validateTree(root, theme: theme)` reports the role by
  name instead of letting a box paint nothing.
- A literal colour keeps working, so a tree can mix roles and values, and a small
  page that wants no theme never needs one.

`BoxStyle.resolve(theme)` gives back a style whose colours are all concrete, which
is what the Flutter renderer calls once per node. The web renderer does the
opposite: it writes `var(--unibox-color-primary)` in the class rule and the theme
once in a `:root` block, so a host stylesheet, a dark-mode block or an embed can
outrank the tree without touching it. The property name is the enum member in
kebab case (`onPrimary` → `--unibox-color-on-primary`).

## Motion

`BoxTransition` is how one look becomes another: a duration and one of the five
curves CSS and Flutter share the control points of (`linear`, `ease`, `easeIn`,
`easeOut`, `easeInOut`). The resting style declares it, a `BoxState` style names
the tokens that change, and the change eases.

What it covers is the paint — background, border colour, corner radius and shadows —
and nothing else. Layout never animates, because a transition on a width or a gap
would move everything around the box on one target and not the other; the border
width is out for the same reason, since CSS animates it as a layout change while
Flutter animates it as paint.

```dart
const Box(
  backgroundColor: BoxColor.white,
  transition: BoxTransition(duration: Duration(milliseconds: 150)),
  hoverStyle: BoxStyle(backgroundColor: BoxColor.rgb(0xF3, 0xF4, 0xF6)),
)
```

`validateTree` reports a transition that changes nothing and one declared on a
state style instead of the resting one, where no renderer would apply it.

`BoxFold` is the other kind of motion, and the one the reader drives: a box paints
another look the further it has travelled out of the viewport that scrolls it.

```dart
const Box(
  height: 132,
  fold: BoxFold(
    to: BoxStyle(opacity: 0, transform: BoxTransform(scale: 0.75)),
    over: 0.75,
  ),
)
```

The travel is the box's own exit, so nothing states a number of pixels; `over` is the
share of that exit the fold completes over, and `progressAt` is the arithmetic both
targets share, in the order a browser applies it — the range first, then the curve.
`BoxFold.looks` is the set a renderer eases, and it is the same set a transition covers,
which is what makes a fold paint only. `validateTree` reports a fold that names
a layout token, one that names nothing, one that takes more than the whole exit, one on
a box that pins (a pinned band never leaves), one on a shaped box, a border whose width
a fold would move, and one look eased by both a transition and a fold.

## Structure and semantics

A node says what it is as well as how it looks, and none of it changes a pixel:

| Token | Meaning |
| --- | --- |
| `TextNode.headingLevel` | the text is a heading of level 1 to 6: `<h1>`–`<h6>` on the web, `Semantics(header: true, headingLevel: n)` in Flutter |
| `BoxSemantics.element` | the element the box becomes: `div`, `main`, `nav`, `header`, `footer`, `aside`, `section`, `article`, `form`, `figure`, `ul`, `ol`, `li` or `a` |
| `BoxSemantics.role` | the ARIA role of a hand drawn control: button, checkbox, switch, link or heading |
| `BoxSemantics.expanded`, `.selected`, `.pressed`, `.hidden`, `.liveRegion` | the state a reader announces and a browser exposes as `aria-expanded`, `aria-selected`, `aria-pressed`, `aria-hidden` and `aria-live` |
| `BoxSemantics.current` | which item of a set the box is: `aria-current` (`BoxCurrent.page`, `.step`, `.location`) |
| `TextInputNode.required`, `.invalid`, `.description` | what the form needs from a field and why a value was rejected: `aria-required`, `aria-invalid`, `aria-description` on the web and the same state in Flutter |
| `BoxSemantics.label` | the name to announce instead of the contents |

A heading is a text rather than a container, and the element brings no look: the
web renderer cancels the user agent's margin, size and weight, so a heading is
typeset by the tree like every other text. A hidden box is hidden from assistive
technologies and never focusable, so it cannot be reached by keyboard either.

`validateTree` reports a `BoxElement.li` whose parent is not a `ul` or an `ol` —
the one combination HTML forbids — and the renderers report the issues they cannot
compensate for.

## Navigation

A press that goes somewhere is a destination, and the model says so with a node:
`LinkNode` is a `Box` that names one, so the box itself *is* the `<a href>` — its look, its
children and its press are its own. A callback (`Box.onTap`) is for a press that *does*
something: opens a dialog, submits a form, toggles a filter. A picture or a line of text is
the same node around that leaf, because it takes every parameter a box takes.

```dart
// The whole segment is the link: padding, fill, ink and all.
LinkNode(
  '/?category=meetingRoom',
  padding: BoxSpacing.symmetric(horizontal: 12, vertical: 6),
  onTapDown: startInk,
  children: <UINode>[TextNode('Meeting room')],
)
```

| The node says | and the model answers |
| --- | --- |
| `url` | a destination: the element is the anchor (`BoxSemantics.element: BoxElement.a`) and the web writes `<a href>`, with `target` and `rel` for a `newTab` |
| `Box` and no `LinkNode` | a container, or a control with a callback — never an anchor |
| `url` and `enabled: false` | no `href`: a disabled control drops what it does, and a link that still navigated would be the drift |
| `url` and `onTap` | both: the callback answers the press and the `href` stays for a reader without a runtime, a new tab and a crawler |
| `url` and `stateStyles` | the tints of a press, unchanged: the anchor is the box, so its states are its own |
| `element: BoxElement.a` with no url | HTML's placeholder anchor: a browser paints it as text, nothing follows it and nothing can tab to it |

A box a component has already built becomes a link with `LinkNode.of(box, url)`: the same
children, behaviour and look, with a destination. The look travels as one `BoxStyle`, so a
token `Box` gains cannot be lost by it, and the copy's flat accessors answer `null` — read
`computedStyle`, which is what a renderer reads.

A link that says it is an `article` *and* names a destination is reported, because one tag is
written and the anchor is the one that navigates: put the landmark around the link.

Two constructs are reported rather than painted differently: a link inside a link, and a
control inside a link — HTML forbids interactive content in `<a>`, and neither target can
say whether the inner press runs or navigates. Compose them as siblings, or make the
control the destination: a chip with a remove cross is two nodes, not one inside the other.

## Your own component

Most components are a function that returns a node tree, and both renderers already
understand that:

```dart
UINode priceTag(String price) => Box(
  padding: const BoxSpacing.symmetric(horizontal: 8, vertical: 4),
  borderRadius: 6,
  backgroundColor: BoxColor.white,
  children: <UINode>[TextNode(price, fontWeight: FontWeight.bold)],
);
```

That is the whole story for everything the model can express, and it is what the
example does throughout: props are parameters, variants are enums, looks are
`const BoxStyle` values.

When an effect cannot be one description — a Material ink ripple and a CSS
animation are not the same thing — the escape hatch is `EmbedNode`: a node that
carries **one implementation per renderer** and the child they wrap.

```dart
final class InkRipple extends EmbedNode {
  const InkRipple({required super.child, required this.implementations});

  @override
  final List<Object> implementations;
}
```

Nothing in this package knows what those payloads are. Each renderer draws the
first one whose type it understands — a `Widget` or a `Widget` builder in Flutter,
a `Component` or a `Component` builder on the web — and reports the node when it
finds none, or two. So a node class this package has never heard of renders
everywhere that can draw one of its payloads, and a third renderer needs no change
here.

The payloads are platform values, which is the honest cost of the hatch: the node
has to be built either in a package that can see both types or, more usually, with
the host injecting its own half — the same shape the example uses for the map.
`validateTree` reports an embed that carries nothing at all.

## State

`StatefulNode` is the one node with a lifecycle. It carries a factory for a
`Store` and a view function; a renderer creates the store once, subscribes,
calls `onMount`, and disposes it on unmount. The state is a value the store
publishes, so the view is a pure function of it:

```dart
final class SignupNode extends StatefulNode<SignupState, SignupStore> {
  SignupNode() : super(create: SignupStore.new, view: signupView);
}

UINode signupView(SignupState state, SignupStore store) =>
    TextNode(state.pending ? 'Joining…' : 'Join');
```

The view returns one tree for the state, so every state a component can be in is
an ordinary tree the renderers already draw. A view draws no overlay of its own:
a dialog is an `OverlayNode` in the tree the view returns, so the state decides
whether it is there and the node decides how it is presented.

`Store` names no platform, and `StateStore` is the ready made implementation: a
value, a listener list that belongs to this package, and a guarded setter, so a
store runs in Flutter, on a server and in a browser without a dependency.
`onMount` is where an initial request starts, which is why a server render can
draw the first state without starting one.

## Overlays

An `OverlayNode` is content drawn above the page instead of in the layout of its
parent. It is a node like any other: it is in the tree where the state says it
should be, so there is no `open` flag and no overlay slot on a view.

```dart
if (state.details != null)
  OverlayNode(
    onDismiss: store.closeDetails,
    child: TextNode(state.details!.name),
  ),
```

The node states the policy — `onDismiss`, `barrierDismissible`, `barrierColor`
and `alignment` — and the renderer presents it: Flutter through an `OverlayPortal`
on the root overlay, the web as a fixed layer. The layer is the window on both, so
the content is bounded by it and a dialog taller than the window scrolls rather
than growing past it. `validateTree` reports the two combinations that do nothing:
a dismissible barrier with no `onDismiss`, and a content that fills its height,
which a room without an end cannot give it.

## Inheritance

`Box.textStyle` (or `BoxStyle.textStyle`) is inherited by the descendants of the
box; every other token only applies to the box itself. Typography is the single
inherited axis because it is the only one CSS and Flutter agree on: a box maps to
`DefaultTextStyle` in Flutter and to the inherited font properties in CSS.

A node resolves its own typography with `computedStyle`, which merges its flat
tokens over its `style`. `Box.computedTextStyle` does the same for a box, so both
renderers resolve identical values from identical input.

## Beside Flutter

This package declares a few names that `package:flutter/material.dart` also
declares, because both describe the same things:

| Name | Beside Flutter |
| --- | --- |
| `Axis`, `BoxBorder`, `BoxShadow`, `TextOverflow` | `ambiguous_import`, reported by the analyzer |
| `TextAlign`, `FontWeight` | shadowed silently: Flutter re-exports these from `dart:ui`, and an SDK declaration loses to a package declaration with no diagnostic at all |

A file that needs the tree _and_ a renderer therefore prefixes this import:

```dart
import 'package:flutter/material.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

Widget view() => const core.Box(direction: core.Axis.vertical).toWidget();
```

Better still, keep the tree in a library of its own: a package that imports
`unibox_core` but no renderer never sees both APIs, needs neither a prefix nor
`hide`, and is where a shared Flutter/web tree belongs anyway. `unibox_flutter`
and `unibox_html` never re-export this package, so importing a renderer is
always safe.

## Validation

`validateTree(node)` reports the trees no renderer can honour: a `PositionedNode`
outside a `StackNode`, a `LinkNode` nested inside another one, and a control inside
one, and a scrolling
box that also distributes its children along the main axis. Both renderers run it
inside an assertion, so a broken tree fails while it is being built.
