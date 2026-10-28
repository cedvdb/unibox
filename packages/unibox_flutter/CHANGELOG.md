# Changelog

## 0.1.0

- A text input resolves a colour role in its `placeholderStyle` against the theme, like the colour of any other text; it threw before.
- A `BoxBorderRadius` becomes `BorderRadius.only`, so a box that rounds only two corners
  draws the same shape it does on the web.

- A `TextInputNode.placeholderStyle` becomes the field's `hintStyle`, so the hint of an
  empty field is drawn in the typography the tree asked for instead of the host's.

- A box with `onTapDown` reports the press: `TapDownDetails.localPosition` becomes a
  `BoxTapEvent` position and `PointerDeviceKind` becomes a `BoxPointerKind`, before
  the tap fires. A box that only listens for the press counts as interactive, so it
  still takes the pointer cursor.
- A box that holds a stack lays the stack out with the box's own constraints, so
  `Box(overflow: hidden, child: StackNode(...))` clips a layer instead of failing. A
  flex hands its children an unbounded main axis, and a stack cannot be laid out in
  one; the web renderer already drew that shape.

The first release of the Flutter renderer: one node tree becomes a widget tree.

- A `TextInputNode` with padding hands it to the field as `contentPadding`, so the whole field takes focus and not only its text line.
- `FlutterGrid` lays a `GridNode` out from the constraints it is given, one row
  per line of fixed-width slots, empty slots for a short last line and no
  `Expanded`, so a last-row card keeps its track.
- `renderFlutter(node)` and `node.toWidget()` render any node, and `renderNode` the
  same without re-validating a subtree that was already checked.
- A box is a `Flex` in `Padding`, `DecoratedBox`, `ClipRect`/`ClipRRect`, `SizedBox`
  and `GestureDetector`/`MouseRegion`; without a direction it is a column, and an
  empty box still renders its flex container.
- Typography is inherited through `DefaultTextStyle`, and the renderer installs
  `BoxTextStyle.defaults` around the tree so an undeclared text is typeset the same
  way the web renderer typesets it.
- A box hidden by `visibleFrom`/`visibleUntil` releases the share of the width its
  `flex` would claim, which is what `display: none` does to a flex item in CSS; and
  it keeps its subtree alive in a zero-sized box, so state survives a width change.
- `FlutterStateful` takes the same `theme:` as `renderFlutter`, so a host whose root
  is a stateful node states the theme once instead of remembering a scope around it.
- `renderFlutter` takes a `UniboxTheme` and resolves every colour role while it
  builds the widget tree, through a `UniboxThemeScope` that a host installing its own
  root can use directly. An overlay hands the theme to its content explicitly, since
  the portal sits outside the tree the page was rendered in.
- `FlutterImage` loads the node's `src`. The responsive fields of an `ImageNode`
  (`srcSet`, `sizes`, `loading`, `fetchPriority`) are web attributes and are not
  read here: Flutter loads one source, and the README records the difference.
- `BoxTransition` becomes implicit animation: the decoration tweens through
  `DecorationTween`, a delay is an `Interval` of the longest timeline, opacity is
  `AnimatedOpacity` and a transform is a `TweenAnimationBuilder` over
  `BoxTransform`, interpolated part by part rather than as one matrix.
- Interaction states are `MouseRegion` and `Focus`, with `Enter`/`Space` activation
  on a box whose role lets the user act on it, and a state style layering over the
  resting one exactly as the browser layers a pseudo class.
- Semantics: roles, labels, checked and disabled states, `isRequired`,
  `validationResult`, `hint`, expanded, selected, hidden and live regions; a heading
  becomes `Semantics(header: true, headingLevel: n)`.
- A `TextInputNode` is a `TextField` with no Material decoration, so it occupies its
  line box like a plain `<input>` and the box around it draws the field.
- `StatefulNode` renders through `FlutterStateful`: the store is created on mount,
  subscribed, rebuilt on a notification and disposed, and an `OverlayNode` is
  presented through an `OverlayPortal` on the root overlay behind its barrier.
- `FlutterWidgetNode` embeds any widget, and `FlutterLinkScope` is where a host says
  what following a link means.
