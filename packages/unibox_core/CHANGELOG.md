# Changelog

## Unreleased

- `Box(fold: BoxFold(to: …, over: …, curve: …))` is a look that arrives as the box leaves the
  box that scrolls it: the reader's scroll is the clock, so a hero fades and shrinks as a
  toolbar comes up under it. It is paint only — the background, the border colour, the radius,
  the shadows, the opacity and the transform — because a frame of an eased layout is a picture
  neither engine can be held to, and the travel is the box's own exit so no number of pixels is
  written down. `BoxFold.progressAt` is the arithmetic both targets share and `looks` is the set
  they ease. `validateTree` reports a fold that names a layout token, one that names nothing,
  one that takes more than the whole exit, one on a box that pins, one on a shaped box, a
  border whose width it would move, and one look eased by both a transition and a fold.

- `LinkNode.of` keeps a box's `capturesPointer`: the field arrived after the conversion was
  written, and the constructor did not forward it either, so a box that asked to be decoration
  came back as a link that swallows the press it was told to pass on. The forwarding list is
  the cost of a node that is a box, and this is the first field it caught.

- `Box(pin: …, pinOffset: …)` keeps a band at the edge of the box that scrolls it:
  `BoxPin.start` is the top of the viewport, `BoxPin.end` the bottom, and `pinOffset` is the
  room a header above it takes. The band keeps its slot in the flow — nothing below it moves —
  and is painted above the content that scrolls under it, whether the scrolling ancestor is a
  box with `overflow: Overflow.scroll` or the document a page scrolls. A pinned box states its
  height: the slot the flow keeps is that number, so a pin without one is reported. So is a pin
  inside a box that scrolls sideways, a pin inside a box that only clips
  (`Overflow.hidden` never moves), a negative inset, and an inset with no pin to hold it.
  A band is also a child of the box that scrolls it — from one level down a browser pins it
  inside *that* box, so the two targets would come to rest in different places — and it keeps
  the height it states, so a `flex` share on it is reported rather than honoured by one
  target and ignored by the other.

- `Box.capturesPointer` says whether the pointer may land on a box, and `null` keeps today's
  rule: a box with children, a callback or a state style takes it, and a painted leaf lets it
  through. `false` says the box is decoration whatever it holds, so the hover, the cursor and
  the press reach the control under it — a count over a button's corner is a picture, not the
  first place a thumb lands.

- `validateTree` reports a box that fills its height as an overlay's content. The layer is a
  scrollport the size of the window on both targets, so the content is laid out with no end
  on that axis and `height: double.infinity` asks for infinite room — the construct a box
  that fills a scrolling parent is already reported for.

- `LinkNode.of(box, url)` is a box as a link: the same children, the same behaviour and the
  same look, with a destination added. The look travels as one `BoxStyle`
  (`Box.computedStyle`), so a token `Box` gains can never be forgotten by it — what a reader
  keeps in step are the facets that are not style, and the copy says so. Its flat accessors
  answer `null`, because the copy states its look as a bag; a renderer reads `computedStyle`
  and sees no difference.

- **Breaking: `LinkNode` is a `Box` that names a destination.** A link was a wrapper around a
  child, and a wrapper states no layout: the control inside one kept the `flex` share, the
  height and the padding the anchor should have had, and in Flutter a press inside it was a
  press the link never saw. The node is now the box itself —
  `LinkNode('/rooms/1', padding: …, children: <UINode>[…])` — so a destination can be a
  button, a card or a segment as easily as a line of text, with its own attributes (`url`,
  `newTab`), its own press and its own content model. `LinkNode(url, child: x)` becomes
  `LinkNode(url, children: <UINode>[x])`. A destination is a node rather than a field on
  `Box` because it is not style: it is the one thing on a box that brings an element token, a
  press, an activation key and a role with it.

- `BoxElement.a` names the anchor, so the element a node becomes is always the element token:
  a `LinkNode` implies `a`, stating both is consistent, and a link that names a landmark *and*
  a destination is reported instead of one of them winning silently. Stating `a` on a plain
  box writes an `<a>` with no `href` — HTML's own placeholder anchor, which nothing follows
  and nothing can tab to.

- An anchor is focusable without asking: an `<a href>` is in the browser's tab order, so a
  `LinkNode` is in Flutter's too (`LinkNode.isFocusable`, which a hidden link loses), and the
  two targets agree about what a keyboard can reach.

- `validateTree` reports two constructs HTML forbids and no renderer can resolve: a
  `LinkNode` inside another `LinkNode`, and a control inside one (a box with callbacks or a
  role the reader can act on, or a text field). It also reports a link that names a landmark.

- `validateTree` reports a box that fills an axis it was handed no end on: a box with
  `width: double.infinity` inside a row that scrolls along that axis, or inside any parent
  the model leaves unbounded there. Flutter throws `BoxConstraints forces an infinite width`
  at layout time and a browser resolves the same `100%` against the content of the
  scrollport, so nothing warned while the tree was built and the two targets then disagreed
  about a page that looked fine. The rule is the scroll along the main axis one's sibling:
  the tree is reported while it is built, with the box and its parent named.

- `Box.wrap` lets the children of a box flow onto another line when they do not fit, so a
  row of chips wraps instead of scrolling past the edge of a phone. `gap` is the space
  between two children and between two lines, and `mainAlign` and `crossAlign` keep the
  meaning they have in a `Wrap` and in `flex-wrap: wrap` — one line's distribution, and a
  child's place in its line. It is a token and not a `WrapNode` because it is the same
  element on the web. `validateTree` reports the three constructs the two targets cannot
  draw the same way: a `crossAlign` of stretch or baseline in a wrap, a `flex` on a child
  of one, and a box that both wraps and scrolls.

- `Box.aspectRatio` and `BoxStyle.aspectRatio` keep a box's shape — the width
  divided by the height — at whatever width the layout gives it, which is the one size
  that is neither a number of pixels nor a share of the parent: a thumbnail, an avatar
  tile, a video still. `validateTree` reports a ratio that is not positive, and one a
  box states beside both a width and a height where it has nothing left to divide.

- `CrossAlign.baseline` aligns a row's children on the alphabetic baseline of their
  first line of text, which is the one alignment that puts a small label and a large
  price on the same line rather than on the same box edge. A baseline is a horizontal
  line, so a column that states it is reported by `validateTree` rather than laid out
  two different ways by the two renderers.

- `Box.style` and `EmbedNode.payload` are gone, and no compatibility member replaces them:
  a bag is a list (`styles:`), and an embed states `implementations`. The library has one
  consumer — this repository — so a removed spelling is rewritten rather than forwarded.
- A box states its **shadows** as a list, not one shadow: `Box(shadows: <BoxShadow>[…])` and
  `BoxStyle.shadows`. An elevation is three layers in Material and in Flutter — an umbra, a
  penumbra and an ambient blur — and a single `BoxShadow` could only ever state one of them. The
  first entry paints on top, as it does in CSS, the transition part is `BoxProperty.shadows`, and
  a style compares the list by value so two boxes that state the same layers are the same box.

- `Box.gridSpan`, and `GridNode.spanOf` / `GridNode.spanWidthFor`: a card says how
  many columns it covers, so a banner that interrupts a card grid is one grid with
  one spanning child instead of two grids that agree on a column count. A span wider
  than the grid is clamped to the count the width gives, and `validateTree` reports a
  span on a box that is not a grid child.

- `TextDecoration` (`none`, `lineThrough`, `underline`), with `decorationColor` and
  `decorationThickness`, on `BoxTextStyle` and as flat tokens on `TextNode`. A
  struck through price is a line the text engine draws through its own line box, so
  it follows the type scale instead of being a box positioned over it. A line a box
  states reaches the texts inside it, and `validateTree` reports a text that states
  one below it — the two targets cannot combine two lines the same way.

- `FontWeight.light` (`300`). The model had no weight below `normal`, so a label
  typeset at 300 — the light end of Material 3's scale — came out at 400 on both
  targets. The five weights the model names, and the ones it leaves out, are stated
  in `design.md` §2.
- `Box.hasThreshold`: whether a box is drawn at only some widths, read from the tokens without
  resolving a style. A renderer asks it of every child of every box to know which box a container
  query measures, and answering that by merging every bag was work per node for a question about
  two tokens.
- `UniboxTheme.colorScheme` (`BoxColorScheme.light` or `dark`, light unless stated): the scheme a
  theme's values are painted in. It is not a preference — it is the fact a `color-scheme`
  declaration states, so the browser paints its own chrome to match the page. No renderer reads
  the reader's preference on its own.

- `BoxTransform.fractionX` and `BoxTransform.fractionY`: move a box by a multiple of its own size,
  which is the offset that needs no measurement — a tab indicator one tab wide moves a whole tab per
  step. They compose with `offsetX`/`offsetY` rather than replacing them.
- `BoxStyle.widthFraction` and `heightFraction`: a share of the parent instead of a number of pixels,
  so one element can be `1/count` of the row it sits in. A share wins over a stated size, and
  `validateTree` reports a box that states both.

- `Box.snap`: a scrolling box can settle on a child instead of wherever the gesture ended,
  with `ScrollSnap.page` — a pager, a carousel, a wizard step, along the box's own
  direction. `validateTree` reports a snap on a box that cannot scroll.

- `Box.onScroll`: a scrolling box reports how far its content has moved along its main axis,
  as one `double` — `0` at rest, growing as the content moves up (or left). Only a box with
  `overflow: Overflow.scroll` reports it, and only for its own scrolling: a scrollable nested
  inside it reports to its own box, which is what the browser's non-bubbling `scroll` event
  and Flutter's notification depth both give.

- `BoxBorder.cap` and `BoxShape.arc`: a border can state how its ends are drawn, and a shape can
  be an arc of a circle whose `sweep` is a number rather than a path. A cap only shows where an
  outline has ends — a rectangle's border meets itself at four corners — so `validateTree` reports
  one on a box with no shape. Together they draw Material's progress ring as one stroked circle
  with rounded ends instead of a filled band with radial cuts, and a sweep that a value, a state
  style or a timeline can move without either renderer learning what an indicator is.

- `BoxPress` and `replayPresses`: a press a page recorded before an application existed, and the
  one place it can be answered. The walk finds the node that carried the key, and a press is only
  answered where the tree names exactly one node with a callback — a key that matches nothing, two
  nodes or a node with no behaviour is dropped rather than guessed at, because firing whatever is
  nearby is how the wrong control goes off.

- `BoxScrollOffset`: where one scrolling region was scrolled to, before a tree drew it. A page
  records the offset of each region it rendered, keyed by the key that region's node carried,
  and the application that takes the page over starts there instead of at the top. It is a
  value with no host in it, which is why the model can hold it and both sides can speak it.

- `UINode.key` documents that a renderer may write the key into its output, and that
  only a `String` or an `int` survives that trip. Any other key keeps doing its job —
  a reordered child stays attached to its node — but its `toString()` is an instance
  hash, so a server render and the browser it sends the markup to would disagree about
  the name of one node. A key that has to be found again should be unique in the
  document and not only among its siblings; that is a fact about the tree a host builds,
  and the class says so rather than pretending to enforce it.
- `Box.onLongPress` says in its doc what each target does with it: the Flutter renderer
  hands it to a screen reader as an action, and a browser has no equivalent, so on the
  web a hold is a pointer gesture and a control only a hold reaches needs a visible
  target or a label that says what the hold does.

- `BoxSemantics.pressed` is the state of a toggle button: `aria-pressed` on the web and
  Flutter's `toggled`. It is not `selected`, and the difference is not cosmetic —
  `aria-selected` is only honoured on an option, a tab, a row or a grid cell, so a
  button that carried it announced its state to nobody. A chip and a segment are
  toggle buttons, and they say so now.

- `BoxTransform` takes `scaleX` and `scaleY`, so a box can stretch on one axis and keep
  its size on the other. They multiply `scale` rather than replacing it, and both targets
  paint the result with the same matrix: Material's navigation indicator grows sideways
  out of its icon at its own height, which one factor cannot say.

## 0.1.0

- `LinkNode.onTap` answers the press instead of following the link: a renderer does one
  thing with a press, so a page whose runtime opens a dialog from a link does not also
  load the document that link names. The `href` stays on the anchor, which is what a
  page without the runtime, a new tab, a context menu and a crawler read.

- `BoxAlignment` and `PositionedNode.alignment`: a stack child can be placed by where
  it sits — the nine positions of a cell — instead of by offsets, which is what a
  floating control needs: the child fills the stack and the alignment puts it at the
  bottom centre of any surface. `validateTree` reports an alignment and an offset on
  one node, since the child fills the stack when it is aligned.

- `BoxShape`: a box can be painted in an outline instead of a rectangle — a path in a
  view box, in the command vocabulary of SVG's `d` (`M`, `L`, `C`, `Q`, `A`, `Z`) with
  a fill rule. The background fills the path, the border is a stroke along it, layout
  is untouched and `overflow: hidden` clips the children to it. `BoxFillRule.evenOdd`
  turns two circles into a ring. `BoxShape.circle` and `BoxShape.ring(thickness:,
  sweep:)` state the two outlines people ask for — a ring is two circles under the
  even-odd rule, and a partial one is a single subpath of that band, so a progress
  indicator is two boxes rather than new geometry. A shape is not eased and casts no
  shadow, and
  `validateTree` reports it next to a corner radius, a shadow, an empty command list
  or a view box with no size.
- `BoxStyle.resolve` carries every token through, not only the ones a theme resolves:
  a themed box used to lose `corners`, `visibleFrom` and `visibleUntil` on the way to
  Flutter while the web kept them.

- `BoxBorderRadius` and `BoxStyle.corners`: the radius of each corner, so a box can be
  round at the top and square at the bottom — Material's filled text field and its
  bottom sheet. `borderRadius` stays the one-radius shorthand; a box that sets both
  is reported by `validateTree`, and a negative radius is reported too.

- A node's name is a **literal**: every node of this package states one, a subclass
  that states nothing inherits the name of the node it extends, and the type is never
  consulted. `runtimeType` is mangled by a compiled build, and a page that shipped
  `data-unibox-node="minified:-s"` was worse than one that says nothing.
- `UINode.debugLabel` and `UINode.debugName`: the name a renderer can write on the
  element it drew, and the rule that derives one from the type. `Box` reads `box`,
  `TextNode` reads `text`, a `MaterialCard` reads `material-card`. It is a development
  aid: nothing in the model reads it, and it is never part of a look.
- `TextInputNode.placeholderStyle` gives the hint its own typography, so a field can
  paint it quieter than the value without restyling the whole control. It is a token
  of the node rather than of the box around it because both targets hand the hint to
  the control itself.

- `BoxTapEvent`, `BoxPoint`, `BoxPointerKind` and the flat `Box.onTapDown`: a press now
  says where it landed inside the box and what pressed it. The position is the local
  one because it is the coordinate both hosts can produce exactly — Flutter's
  `localPosition`, a browser's `offsetX`/`offsetY` — while where a box sits on a page
  is a host fact. `onTap()` stays for the case where only the activation matters, and a box that
  only carries `onTapDown` counts as interactive, so it takes the press it listens
  for.

The first release of the platform agnostic core: the tree, the values it is made of,
and the checks that keep a tree renderable.

- `TextInputNode.padding`: the space inside the field, which is the only padding a press can reach; a box around the input keeps the paint.
- `GridNode`: equal columns whose count follows the width of the box, with a
  minimum item width, an optional column cap and a gutter, and `columnsFor` /
  `cellWidthFor` as the arithmetic both renderers apply. `validateTree` reports a
  grid child that flexes, sizes itself or asks for an infinite height, and an
  image whose height would wait for the file.
- `Box`, `TextNode`, `ImageNode`, `LinkNode`, `StackNode`, `PositionedNode`,
  `TextInputNode`, `StatefulNode` and `OverlayNode`, every one immutable, `const`
  where its values allow, and carrying an optional `key` that keeps state attached
  to the node it belongs to.
- `Box` is a flex container with flat parameters for direction, alignment, gap,
  `flex`, overflow, size and bounds, plus padding, margin, background, radius,
  border, shadow, opacity and a transform. `styles: <BoxStyle>[...]` composes
  reusable bags of tokens left to right, and a flat parameter wins over all of them.
- Typography is the one inherited axis: `Box.textStyle` reaches the texts inside, and
  `BoxTextStyle.defaults` (16 logical pixels, normal weight, black, 1.5, no letter
  spacing) is the default both renderers install at the root of a tree.
- A colour can name a **role** — `BoxColor.role(AppColor.primary)` — and a
  `UniboxTheme` says what each role is worth. The role is an enum member, so the
  compiler checks it and the theme is keyed by the same value; `BoxStyle.resolve`,
  `BoxBorder.resolve`, `BoxShadow.resolve` and `BoxTextStyle.resolve` turn a style
  into concrete colours, and `validateTree(root, theme: theme)` reports a role no
  theme can answer.
- `ImageNode` carries the responsive fields a browser reads — `srcSet` (candidate
  widths and their URLs), `sizes`, `loading` and `fetchPriority` — and resolves the
  `srcset` attribute itself, narrowest candidate first, so the same candidates
  always produce the same HTML. `validateTree` reports a candidate with no positive
  width, and a `sizes` that names nothing because there is no `srcSet`.
- `BoxTransition` and `BoxTransitionPart` ease a change of look, of opacity or of a
  transform, with `BoxProperty` naming the parts and `BoxCurve` the five curves CSS
  and Flutter define the same way.
- Semantics: `BoxSemantics` with `role`, `element`, `label`, `checked`, `expanded`,
  `selected`, `hidden`, `liveRegion` and `current`, plus `BoxElement`, `BoxRole` and
  `BoxCurrent`; `TextNode.headingLevel` makes a text a heading.
- State lives in a store: `Store` is the contract a `StatefulNode` creates, and
  `StateStore` is the ready made one, with a guarded `state` setter that notifies
  nobody when the value does not change.
- `validateTree` reports the trees no renderer can honour faithfully: a positioned
  node outside a stack, a link inside a link, a scrolling box that also distributes
  its children, a list item outside a list, a caption outside a figure, an embed
  with nothing to draw, a transition that changes nothing, an opacity outside 0 to
  1, and a dismissible barrier with nothing to dismiss.
- No dependencies at all, and no `dart:ui`: a tree can be built and validated on a
  command line, on a server, or in a test with no framework around it.
