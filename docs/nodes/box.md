# Box

The container. It lays children out in a row or a column, spaces them, sizes
itself, paints a background, a border, rounded corners and shadows, and reacts to
taps and hover. A box that names a destination is a [`LinkNode`](link.md), which *is* a box.

```dart
Box(
  direction: Axis.horizontal,
  gap: 12,
  padding: BoxSpacing.symmetric(horizontal: 16, vertical: 10),
  backgroundColor: BoxColor.white,
  border: BoxBorder(color: BoxColor.rgb(0xE5, 0xE7, 0xEB)),
  borderRadius: 10,
  onTap: open,
  children: <UINode>[TextNode('Open')],
);
```

**Layout**

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `children` | `List<UINode>` | empty | The nodes laid out inside. |
| `direction` | `Axis?` | column | `Axis.horizontal` is a row, `Axis.vertical` a column. |
| `writingDirection` | `WritingDirection?` | inherited | The direction the words flow in: `rtl` packs a row from the other side, carries `start`/`end` with it, and is inherited by everything inside the box. It is not `direction` — a row is still a row — and the page states the same value as `dir` on `<html>`. |
| `mainAlign` | `MainAlign?` | start | Distribution along the direction: `start`, `center`, `end`, `spaceBetween`, `spaceAround`, `spaceEvenly`. |
| `crossAlign` | `CrossAlign?` | start | Alignment across the direction: `start`, `center`, `end`, `stretch`, `baseline`. A baseline is a horizontal line, so it is a row's alignment: a column that states one is reported by `validateTree`. A `stretch` fills the children that state no size across the direction and leaves the rest alone: a child with its own `width` keeps it, as a browser leaves a flex item whose cross size is `auto` alone. |
| `gap` | `double?` | none | Space between two children, and between two lines of a wrapping box. For space at the edges, use `padding`. |
| `wrap` | `bool?` | `false` | Whether a child that does not fit starts another line instead of running off the end. `gap` is the space between two lines as well, and `mainAlign` distributes one line while `crossAlign` places a child in it — what `Wrap` and `flex-wrap: wrap` each mean. A `stretch` or `baseline` cross alignment, a `flex` on a child, and a box that both wraps and scrolls are reported by `validateTree`, because the two targets cannot draw them the same way. |
| `flex` | `int?` | none | Share of the free space this box takes inside its parent: `flex: 1` is an `Expanded` in Flutter and `flex-grow: 1` on the web. |
| `gridSpan` | `int?` | one track | How many columns of a `GridNode` this box covers: a banner that interrupts a card grid states `2`, or more for a full row. Only a grid child has tracks, and `validateTree` reports it anywhere else. |
| `overflow` | `Overflow?` | visible | `hidden` clips the content, `scroll` makes the box scroll along its direction. |
| `snap` | `ScrollSnap?` | none | Where a scrolling box comes to rest. `page` makes it a pager: it moves one child at a time along its own direction and settles on a child rather than between two. It needs `overflow: Overflow.scroll`; `validateTree` reports a snap on a box that cannot scroll. |
| `page` | `int?` | none | The page a snapping box shows, counted along its direction: how a pager is *told* where to go, as a position rather than a controller. It moves the box when it changes, so a tree drawn twice with the same page leaves the reader alone. Only meaningful with `snap: ScrollSnap.page`. |
| `pin` | `BoxPin?` | none | The edge of the box that scrolls it that this box stays at, once the content would have carried it past: `start` is the top of the viewport, `end` the bottom. The band keeps its slot in the flow — nothing below it moves — and is painted above the content that scrolls under it. It is a relation to the nearest scrolling box, not an offset in the window, so it works when the document scrolls as well as inside a box with `overflow: Overflow.scroll`. The band is a child of that box and states its height (it is the room the flow keeps) and paints its own background, since the content passes underneath it. `validateTree` reports a pin inside a box that scrolls sideways, inside a box that only clips, one that is not a child of the box that scrolls it, one with no height, one that also asks for a `flex` share, and an inset with no pin. |
| `pinOffset` | `double?` | none | The room a pinned band keeps from its edge, in logical pixels: the same number as the `height` of the header above it, so the band comes to rest under it instead of over it. |

**Size**

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `width`, `height` | `double?` | content size | Logical pixels. `double.infinity` fills the space the parent gives — and that space has to have an end: a box that fills the width inside a row that scrolls along it, or inside any parent that offers it none, is reported by `validateTree`, because Flutter refuses the constraint at layout time and a browser resolves the share against the wrong box. |
| `aspectRatio` | `double?` | none | Width divided by height: `1.5` keeps three units across for every two down, whatever width the layout gives it. It needs one side to measure — a `width`, a `height`, a `widthFraction` or a parent that fills one — and `validateTree` reports a ratio a box states beside both a width and a height, because there is nothing left for it to divide. |
| `widthFraction`, `heightFraction` | `double?` | none | A share of the parent rather than a number of pixels: `0.5` is half of it. This is the size a box can state without knowing one — a share of a row, one tab of a bar — and it wins over `width`/`height`, which `validateTree` reports if a box states both. |
| `minWidth`, `maxWidth`, `minHeight`, `maxHeight` | `double?` | none | Bounds the box keeps even when its content wants otherwise. A box that also fills its parent stops at the bound: a measure inside a row that fills is as wide as the row or the measure, whichever is narrower. |
| `padding` | `BoxSpacing?` | none | Space inside the box, around its children. |
| `margin` | `BoxSpacing?` | none | Space outside the box. |

**Paint**

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `backgroundColor` | `BoxColor?` | none | Colour behind the children. |
| `border` | `BoxBorder?` | none | Line around the box, with a width, a colour and — for a shape's open outline — a cap. |
| `borderRadius` | `double?` | square | Corner radius in logical pixels, the same on all four. |
| `corners` | `BoxBorderRadius?` | square | The radius of each corner, for a box that is not round on all four — a filled text field rounds its top and leaves the bottom square. Takes precedence over `borderRadius`. |
| `shadows` | `List<BoxShadow>?` | none | Drop shadows, painted in the order they are written: colour, offset, blur, spread. The blur is in logical pixels, in Flutter's unit, and the web writes the CSS blur that paints the same width. |
| `shape` | `BoxShape?` | the rectangle | The outline the box is painted in, instead of its rectangle: a path in a view box, stretched to the box. The background fills it, the `border` is drawn along it, and the children are clipped to it when the box also says `overflow: Overflow.hidden`. See [shapes](#shapes). |
| `opacity` | `double?` | solid | `0` (invisible) to `1` (solid). The box keeps its room either way. |
| `transform` | `BoxTransform?` | none | Moves, turns or scales the box about its centre (`scale`, `rotation` in degrees, `offsetX`/`offsetY` in pixels, `fractionX`/`fractionY` in multiples of the box's own size). The fractions are the offsets that need no measurement — one tab, half a width — and they compose with the pixels. It paints differently without taking different room, so text inside never reflows. |
| `transition` | `BoxTransition?` | none | How long a change of the paint, the opacity or the transform takes, and how it eases. See [motion](../../README.md#motion). |
| `fold` | `BoxFold?` | none | The look the box takes as it leaves the box that scrolls it: `to` states the paint at the end of the travel, `over` how much of the exit the fold takes, and `curve` how it eases. Paint only — the same looks a `transition` eases — so nothing is laid out again as the reader scrolls. See [motion](../../README.md#motion). |

**Interaction**

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `onTap` | `TapCallback?` | none | Tapped, clicked, or activated with `Enter`/`Space` once the box is focusable. |
| `onTapDown` | `TapDownCallback?` | none | A press lands: where it landed inside the box and what pressed it (touch, mouse, pen, keyboard). It fires before `onTap`, which is what an effect that starts at the pointer needs. |
| `onLongPress` | `LongPressCallback?` | none | Pressed and held. |
| `onHover` | `HoverCallback?` | none | Pointer entered or left the box. |
| `onScroll` | `ScrollCallback?` | none | The box scrolled, with how far its content has moved along its main axis. Only a box with `overflow: Overflow.scroll` reports it, and only for its own scrolling — a scrollable nested inside it reports to its own box. It is what lets a header fold as the list under it moves. A box that states `page` *and* listens to `onScroll` is wired to itself: the move it was told to make reports every offset on the way, so the callback has to tell those from the reader's own scrolling. The example's tabs demo does it with one field, and the difference is visible: a pager sliding to a page a press chose reports 0, its whole width, then the page. |
| `enabled` | `bool` | `true` | A disabled box keeps its layout, drops its callbacks, leaves the tab order and is announced as disabled. |
| `capturesPointer` | `bool?` | the box decides | Whether the pointer may land on this box. Left unset, a box with children, a callback or a state style takes it and a painted leaf does not; `false` says the box is decoration whatever it holds, so the hover, the cursor and the press reach the control under it — a badge over a button. `true` makes a leaf a target of its own. |
| `semantics` | `BoxSemantics?` | none | What the box *is* for a screen reader: role, label, state, element. |
| `stateStyles` | `Map<BoxState, BoxStyle>?` | none | Looks for `hover`, `focus`, `pressed` and `disabled`, layered over the resting one. |
| `hoverStyle` | `BoxStyle?` | none | Shorthand for the `hover` entry of `stateStyles`. |

**Styles**

Instead of the flat parameters above, a box can wear one or more reusable bags:
`styles: <BoxStyle>[...]`. The bags merge left to right — a later bag wins a value
over an earlier one — and a flat parameter wins over all of them. `textStyle` is
different from the others: it is inherited by the texts inside the box (see
[typography](../../README.md#typography)).

```dart
const cardBase = BoxStyle(
  padding: BoxSpacing.all(16),
  backgroundColor: BoxColor.white,
  borderRadius: 12,
);
const cardBusy = BoxStyle(backgroundColor: BoxColor.rgb(0xF3, 0xF4, 0xF6));

const row = Box(
  styles: <BoxStyle>[cardBase, cardBusy],
  padding: BoxSpacing.all(8), // wins over both bags
);
```

**On each target.** A box is a `Flex` (`Row`/`Column`) wrapped in `Padding`,
`DecoratedBox`, `ClipRect`, `SizedBox` and `GestureDetector`/`MouseRegion` in
Flutter, and one `<div>` with `display: flex` and the matching CSS in the browser.
A box with no children still renders its flex container, so an empty box takes the
size the tree gave it instead of collapsing differently on each side.

**Worth knowing.** A box without a direction is a **column**, not "whatever the
platform does", so `gap` and the alignments work in every box. Nothing is inherited
from a box to its children except typography and the writing direction: a box never
pushes its padding, gap or alignment down, and those two are the tokens CSS and
Flutter inherit as well — `font` and `direction` in one, `DefaultTextStyle` and
`Directionality` in the other.

**A baseline is a row's alignment.** `crossAlign: CrossAlign.baseline` sits the
children on the alphabetic baseline of their first line of text — the one alignment
that knows where the glyphs are, so a 14px label and a 24px price share a line
instead of a box edge. It is Flutter's `CrossAxisAlignment.baseline` and the
browser's `align-items: baseline`, and both mean the same thing there because a
baseline is a horizontal line. A column has no baseline to align on: Flutter draws
the children as if the value were `start` while a browser shifts them sideways, so
`validateTree` reports a baseline on anything that is not a row.

**The two defaults that cost an afternoon.** Both are the same on both targets, and
both are the opposite of what an instinct says:

- **The cross axis starts; it does not stretch.** `crossAlign` is `start`, where a
  CSS flex container defaults to `stretch`. A column therefore hugs each child to its
  own content, and a band does not reach the page width on its own. A band that must
  span says `crossAlign: CrossAlign.stretch` on the column that holds it. A child
  that fills needs that too: `width: double.infinity` takes the space it is given,
  and a browser resolves `100%` against a parent that has a width.
- **A row is as wide as its content.** A horizontal box is a `Row` with
  `mainAxisSize: min` — a CSS flex row whose container hugs — so a row with
  `mainAlign: spaceBetween` distributes nothing unless its parent gave it a width.
  A row that must distribute is inside a box that did: `crossAlign:
  CrossAlign.stretch` on the column around it, or a `width`.

So the recipe, in one line: **a band that must span says `crossAlign:
CrossAlign.stretch`, and a row that must distribute is inside one that did.**

## Shapes

A box can be painted in an outline that is not a rectangle. The outline is a
`BoxShape`: a path in a **view box**, so the same value draws the same silhouette at
40 pixels and at 400.

```dart
const BoxShape hexagon = BoxShape(
  viewBoxWidth: 100,
  viewBoxHeight: 100,
  commands: <BoxPathCommand>[
    BoxPathMoveTo(50, 0),
    BoxPathLineTo(93, 25),
    BoxPathLineTo(93, 75),
    BoxPathLineTo(50, 100),
    BoxPathLineTo(7, 75),
    BoxPathLineTo(7, 25),
    BoxPathClose(),
  ],
);

Box(width: 40, height: 40, shape: hexagon, backgroundColor: BoxColor.white)
```

The commands are the ones SVG's `d` attribute has — `M`, `L`, `C`, `Q`, `A` and `Z`
— and every renderer has a method for each, so neither parses what the other wrote.
The model ships three values over that vocabulary, because they are asked for far more
often than the rest: `BoxShape.circle`, `BoxShape.ring` and `BoxShape.arc`.

```dart
// A band: the region between the edge and a circle 12 units inside it.
Box(width: 96, height: 96, shape: BoxShape.ring(thickness: 12), backgroundColor: grey)

// A value over it: the same band, a fraction of a turn, clockwise from twelve.
Box(width: 96, height: 96, shape: BoxShape.ring(thickness: 12, sweep: 0.42), backgroundColor: accent)

// A line: a circle's centreline, run along by an open path. What paints it is the border,
// and `cap` is what its two ends look like — which is how Material's indicator is drawn.
Box(
  width: 48,
  height: 48,
  shape: BoxShape.arc(stroke: 4, sweep: 0.42, viewBox: 48),
  border: BoxBorder(width: 4, color: accent, cap: BoxStrokeCap.round),
)
```

Five things follow from a shape:

- **The fill is the shape.** `backgroundColor` fills the path rather than the
  rectangle, and `border` is a stroke along the same path.
- **`fillRule` decides what is inside.** `BoxFillRule.evenOdd` punches a hole: two
  circles become a ring, which is how a donut is drawn without a second outline.
- **An open outline is a line, not a region.** `BoxShape.arc` closes nothing, so what a
  reader sees is the border's stroke — and `BoxBorder.cap` (`butt`, `round`, `square`)
  states how its two ends are drawn. A cap on a rectangle draws nothing, so
  `validateTree` reports one there.
- **Layout does not change.** Children are laid out in the same rectangle as before,
  which is what puts a label inside the hole of a ring; `overflow: Overflow.hidden`
  is what clips them to the outline.
- **A shape paints; it does not cast.** It has no shadow (put the shadows on the box
  around it) and it does not ease (there are no numbers to interpolate between two
  outlines). `validateTree` reports a shaped box that also names a shadow or a
  corner radius, because a box has one outline.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
