# Changelog

## Unreleased

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
