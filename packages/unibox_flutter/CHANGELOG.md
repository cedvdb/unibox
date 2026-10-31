# Changelog

## Unreleased

- A box that hides its overflow now hides it *inside* its border, where a browser hides it:
  `overflow: Overflow.hidden` on a bordered box cut the whole box, so a child that filled it
  painted over the line — a chosen segment broke the outline of the pill around it, and the tint
  of a hover lit the 1 pixel band a page leaves alone. The clip is the padding box, with the
  corner reduced by the border's width, so the fill and the tint stop at the outline on both
  targets and Material's segmented button keeps the line it draws around a chosen segment.

- A shadow is painted the way CSS paints one: outside the border box, never through it. A box
  with no fill was handing its shadows to a `DecoratedBox`, which paints them as a second shape
  *behind* the box, so a hairline — `BoxShadow(offsetY: 1, blurRadius: 0)` on a row that paints
  no background — filled the whole rectangle: the catalogue's tab bar came out as a solid band
  the height of its tabs. The shadows are now painted by a painter that clips them to the
  complement of the box's outline.

- A box that fills only up to a measure is no longer an `Expanded` in the row that holds it.
  `width: double.infinity` with a `maxWidth` is CSS's `min(100%, max-width)`, which the
  container's alignment then places; claiming the whole line left that alignment nothing to
  move, so a centred band's 1080-pixel column was drawn against the row's leading edge.

- A grid that states its columns is a `Row` of `Expanded` children at their factors inside an
  `IntrinsicWidth`: every child is measured at its max intrinsic width and laid out at the widest
  content per unit, which is the arithmetic Material's own segmented control uses. A parent with
  less room divides what it has between the columns, so a label too long for its column is cut
  rather than widening the grid, a child the width does not draw keeps no column, and
  `CrossAlign.stretch` measures the height too, so every column can be as tall as the tallest.

- An aligned `PositionedNode` child follows the writing direction, as the browser's class always
  did: `Align` was given `Alignment.centerRight` for a `centerEnd` child, so in a page written
  right to left the row mirrored and the control floating over it did not. It is now an
  `AlignmentDirectional`, the same mapping the stack's own alignment already used, and the
  physical `toAlignment` mapping is gone rather than left for a second caller to pick up.

- A box that states `writingDirection` wraps its content in a `Directionality`: the flex reads it
  when it lays its children out, so a row reverses and nothing else in the tree changes. A box
  that states none adds no `Directionality` of its own, so the direction a tree inherits is the
  application's own.

- A box that scrolls paints no overscroll decoration: its viewport runs under a scroll
  configuration that passes the host's physics, drag devices and scrollbar through and drops its
  `GlowingOverscrollIndicator`. A Material application tints or stretches a scroll view pulled
  past its end and a browser paints nothing, and that tint is host chrome — the same reason a
  field keeps no underline and a link no blue.

- A box that states `fold` paints the look it names as it leaves its viewport. A `_RenderFoldedBox`
  layer interpolates the decoration, the opacity and the transform when it paints, from the box's
  own exit, so a scroll repaints one layer: nothing is rebuilt and nothing is laid out again.
  A box with no `Scrollable` above it keeps its resting look, and so does a box that leaves
  through the bottom of the viewport, which a browser's `view()` would fold.

- A box that states `pin` stays at the edge it names while its viewport scrolls. The flow is
  laid out exactly as before — a column, with the band's stated height left in its slot — and
  the band is drawn over the viewport by a layer that repaints itself into place as the scroll
  offset changes, so nothing rebuilds and a field inside the band keeps its state. It paints
  above the content that scrolls under it and takes a press there, which a band left in the
  flow order would lose. A band that is not a child of the box that scrolls it, a pin inside a
  box that scrolls sideways, a pin inside a box that only clips, a pinned box with no height
  and one that also asks for a `flex` share are reported by `validateTree` and drawn in the
  flow. So is a pin at the top of a tree with no scrolling box above it: the web pins it to the
  document, while the surface an application is drawn on does not scroll.
- The catalogue on the site shows a sticky band: a screen whose app bar is the first child of the
  body that scrolls, so it comes to rest at the top and the list runs under it.

- A box that states `capturesPointer: false` is wrapped in an `IgnorePointer`, so a press, a
  hover and the cursor pass through it to the control underneath — the same statement the web
  writes as `pointer-events: none`. `true` makes a leaf a `Listener` with an opaque hit test,
  which is what `auto` means for a box that would otherwise let the pointer through. A Material
  icon button's count has the pointer wrong in Flutter too: the glyph-sized square's corner
  answered nothing, so a hover there showed a plain arrow and a press did not run the control.

- An overlay's content is bounded by the window, and scrolls when it is taller: `FlutterOverlay`
  draws it in a `SingleChildScrollView` whose content is at least the room the overlay has.
  A dialog holding more than the window was cut off at the window here and drawn at the
  height of its content on the web — one node, two heights, which the example's sign-up card
  showed — and both targets bound it now, with the rest a scroll away. The scroll view is the
  layer, so the scrim moved inside it: a scroll view covering the layer would take the
  presses the barrier answers.

- `FlutterLink` is gone, and `link_node.dart` is `link_scope.dart`. A `LinkNode` is a `Box`, so
  `FlutterBox` draws it: the file keeps the one thing a host supplies — `FlutterLinkScope` and
  its `FlutterLinkOpener` — and the node needs no widget of its own.

- A `LinkNode` renders as the link it is: a hand cursor, `Semantics(link: true)`, and a press
  that runs its own `onTap` or, without one, opens the url through the enclosing
  `FlutterLinkScope`. It keeps its gesture, so its pressed state and the ink a
  `MaterialInkWell` starts on tap-down are its own. A link with neither a scope nor an `onTap`
  is reported in debug builds.

- A link is activated by `Enter` and not by `Space`, on both targets: a box with a url joins
  the tab order, `Enter` opens it, and `Space` is left alone because a browser does nothing
  with it on an `<a href>`. The role a link is announced with wins over the one a component
  passed, so a button turned into a destination is announced as a link rather than as both.

- A box that states `wrap: true` renders as a `Wrap`: its children break into runs at the
  width they are given, `gap` spaces a run and the runs, and `mainAlign` and `crossAlign`
  distribute one run and place a child in it.

- `Box.aspectRatio` becomes an `AspectRatio` inside the box's sizes, so a box that
  states a width and a ratio is given the height the ratio asks for — the same answer
  a browser gives `width` and `aspect-ratio` together. A box that states both a width
  and a height keeps them, as CSS does.

- `CrossAlign.baseline` becomes `CrossAxisAlignment.baseline`, with the alphabetic
  `textBaseline` a baseline aligned `Row` demands — the same line the browser aligns
  the children on with `align-items: baseline`.

- A box's shadows become one entry of the decoration's `boxShadow` per layer, so the elevation a
  design system states as three shadows is painted as three instead of one.

- `GridNode` honours `Box.gridSpan`: a card that names several tracks is given that
  many alongside a `SizedBox` gutter, and a span that does not fit what is left of a
  row starts the next one — the placement `auto-flow: row` gives on the web. Both
  sides read the count from `GridNode.spanOf`, so a span wider than the columns the
  width gives is clamped rather than overflowing.

- `TextNode.decoration` and `decorationColor` become `TextStyle.decoration` and
  `TextStyle.decorationColor`, so a struck through price is one text node instead of
  a stack and a positioned box. `decorationThickness` is left out on purpose:
  Flutter's thickness is a multiple of the font's own line where the model measures
  pixels, so this target draws the font's own line and `README.md` says why.

- `FontWeight.light` is `w300`, so a light label keeps its weight instead of
  rendering at `w400` like a normal one.

- `UINode.toWidget({UniboxTheme? theme})` takes the theme, so the shorthand can draw a
  tree built from colour roles. It forwarded nothing before, which meant validation
  rejected every themed tree with the role in the message and the extension the README
  leads with could not be used on the trees it advertises.

- A line of text sits where CSS puts it. The extra height a `lineHeight` adds is
  split half above the glyphs and half below them — CSS's half-leading — where
  Flutter's own default distributes it in proportion to the font's ascent and
  descent. The line box was already the same height on both targets; now the
  baseline inside it is too, so text no longer shifts by a pixel or two when a page
  is handed from the browser to Flutter.

- `snap: ScrollSnap.page` is `PageScrollPhysics` on the box's scroll view, so a drag that
  ends between two children comes to rest on one.

- `Box.onScroll` is reported from the box's own scroll view (`ScrollUpdateNotification` with
  a depth of zero), so a nested scrollable does not report to the box around it. An iOS
  bounce reports negative pixels and a value past the end, where a browser clamps: the
  middle of the range is where the two agree.

- A shaped box strokes its outline with the cap its border states, and `toStrokeCap` maps the
  token to Flutter's `StrokeCap`. An open outline — `BoxShape.arc` — has two ends, and the cap is
  what draws them: `BoxStrokeCap.round` gives the rounded ends Material's progress indicator has,
  where the previous filled band stopped on a radius.

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
