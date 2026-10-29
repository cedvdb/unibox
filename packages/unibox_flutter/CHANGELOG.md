# Changelog

## Unreleased

- `pressesFromPage()` and `FlutterStateful(presses: …)`: the presses a page recorded, answered
  once against the first view the node builds — which is the only place their callbacks exist,
  since the view is a function of the store created when the widget mounts. A rebuild is not a
  second press.

- `UniboxScrollScope` and `scrollOffsetsFromPage()`: a box that scrolls opens where a reader
  left it. The document records the offset of each region it rendered, a browser reads the
  record through one call, and the offset becomes the controller's *initial* position — so a
  region is in place at the first layout rather than after a correction, and a rebuild never
  moves the reader back. A record for another key is ignored and a box with no key starts at
  the top: moving whichever region happens to scroll is how the wrong list jumps.

- `scrollOffsetsFromPage()` is chosen by a conditional export rather than a runtime check, so
  the JavaScript never reaches an iOS or Android build, and every read is defensive: an
  exception in the boot path is a blank screen where a wrong offset is only a jump.

## 0.1.0

- A pressable box is one semantics node carrying its role, its name and its action, as
  Flutter's own buttons are. The `Focus` widget around it described itself, which made a
  node inside the control that took the label and the tap action: an *enabled* button was
  read as "Save" with no role at all, while its role sat on an empty parent, and only a
  disabled one — with no action to merge into — was announced as the button it is.
- A box with an `onLongPress` announces it as `Semantics.onLongPress`, which is what a
  native `InkWell` offers: a "hold to delete" row is now findable and invokable by a
  reader. A browser has no such action, so the web renderer stays quiet about it and its
  README records the difference.

- A box whose semantics state `pressed` is announced as toggled, which is what Flutter
  calls the state a browser writes as `aria-pressed`. A toggle button — a filter chip, a
  segment — used to be announced as the selected item of a set instead, so the two
  targets described the same control two ways.

- A box whose only child is a `StackNode` now places what the layer draws by its own
  `mainAlign` and `crossAlign`: the stack still fills the box, because an aligned
  `PositionedNode` needs a bounded main axis, and the pair becomes the stack's own
  alignment. Before, the pair was dropped, so a label the browser centres in its pill
  — the one inside a segmented button's segment or a chip's close target — arrived at
  the top in Flutter.

- A `LinkNode` with an `onTap` calls the handler and not the enclosing
  `FlutterLinkScope`: one press, one answer, which is what the web renderer does by
  cancelling the navigation instead of loading the document as well. A link without an
  `onTap` still opens through the scope.

- The clip of a box is applied inside its decoration, so a card with `overflow: hidden`
  keeps the shadow it casts: CSS cuts an element's content to its radius and never its
  own `box-shadow`, and a `ClipRRect` around a `DecoratedBox` was swallowing it.

- `PositionedNode.alignment` renders as `Positioned.fill` around an `Align`, so an
  aligned child fills the stack and sits where the alignment says.

- A text input resolves a colour role in its `placeholderStyle` against the theme, like the colour of any other text; it threw before.

- A shaped box is drawn with a `CustomPaint` over `pathOf(shape, size)`: the fill is
  the path, the border is a stroke along it, and `overflow: hidden` clips through a
  `ClipPath`. `pathOf` is exported for a host that draws a shape itself.
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
