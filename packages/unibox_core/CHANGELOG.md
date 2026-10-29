# Changelog

## Unreleased

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
