# unibox_flutter

Flutter renderer for [Unibox](../unibox_core) layout primitives.

```dart
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

const card = Box(
  width: double.infinity,
  padding: BoxSpacing.all(16),
  backgroundColor: BoxColor.white,
  borderRadius: 12,
  children: [TextNode('Hello')],
);

Widget widget = renderFlutter(card);
// or, equivalently — and the theme the roles of the tree need travels with it:
Widget widget = card.toWidget(theme: myTheme);
```

Every node type also exports the widget it renders to — `FlutterBox`,
`FlutterText`, `FlutterTextInput`, `FlutterImage`, `FlutterStack`,
`FlutterOverlay`, `FlutterStateful` — so a host or a test can address a rendered
node without depending on its position in the tree. The the web renderer package exports the
same shape under its own prefix, which is the rule: a renderer's classes are named
with their target.

## Box mapping

| Unibox                              | Flutter                                            |
| ----------------------------------- | -------------------------------------------------- |
| `direction: Axis.horizontal`        | `Row`                                              |
| `direction: Axis.vertical`          | `Column`                                           |
| no `direction`                      | `Column`, the same as `Axis.vertical`              |
| `writingDirection`                  | a `Directionality` around the flex, so the row itself reverses |
| `gap`                               | `SizedBox` separators between children              |
| `mainAlign` / `crossAlign`          | `mainAxisAlignment` / `crossAxisAlignment`, with `textBaseline` stated |
| `crossAlign: CrossAlign.baseline`   | `CrossAxisAlignment.baseline` with `TextBaseline.alphabetic` |
| `padding` / `margin`                | inner / outer `Padding`                             |
| `width`, `height`                   | `SizedBox`                                          |
| `aspectRatio`                       | `AspectRatio`, inside the sizes so it divides one of them |
| `minWidth`, `maxWidth`, ...         | `ConstrainedBox`                                    |
| `backgroundColor`, `borderRadius`, `border` | `DecoratedBox` with a `BoxDecoration` |
| `shadows`                           | a `CustomPaint` behind the box, painting each entry of the decoration's `boxShadow` clipped to the outside of the box — which is what CSS does, so a hairline is one pixel and a box with no fill does not paint its own rectangle |
| `overflow: Overflow.hidden`         | `ClipRect`, or a `ClipPath` to the padding box when the box draws a `border` or a `borderRadius`, inside the decoration so the shadow survives |
| `GridNode.columns`                  | a `Row` of `Expanded` children at their factors inside an `IntrinsicWidth`, so a column is the widest content per unit and a width the grid was given is divided; `CrossAlign.stretch` adds an `IntrinsicHeight` |
| `PositionedNode.alignment`          | `Positioned.fill` around an `Align`, with a directional alignment so a start or an end follows the writing direction |
| `shape`                            | `CustomPaint` with a `Path`: the fill, then the border as a stroke along it |
| `shape` + `overflow: Overflow.hidden` | `ClipPath` to the same path                       |
| `overflow: Overflow.scroll`         | `SingleChildScrollView`                             |
| `pin` / `pinOffset`                 | the flow unchanged, with the band drawn over the viewport at the edge it names: a `_RenderPinnedBand` repaints it into place on every scroll, so nothing rebuilds and the band keeps its slot |
| `fold`                              | a `_RenderFoldedBox` layer that interpolates the decoration, the opacity and the transform as it paints, from the box's own exit out of the viewport; nothing is rebuilt and nothing is laid out again |
| `onTap` / `onLongPress`             | `GestureDetector`                                   |
| `capturesPointer: false`            | `IgnorePointer`, so the hover, the cursor and the press reach the control under the box; `true` makes a leaf a `Listener` with an opaque hit test |
| `LinkNode` (a box that names a destination) | `GestureDetector` + `MouseRegion(cursor: click)` + `Semantics(link: true)`, opening through `FlutterLinkScope` unless it has an `onTap`; `Enter` opens it and `Space` does not, as in a browser. It is a `Box`, so it is drawn by `FlutterBox` and needs no widget of its own |
| `newTab` on a box                   | web only, ignored by the Flutter renderer |
| `onHover` / `hoverStyle`            | `MouseRegion` and the hovered token set             |
| `onScroll`                          | `NotificationListener<ScrollUpdateNotification>` around the scroll view, reporting `metrics.pixels` when the notification's `depth` is zero |

A `shape` is painted through a `CustomPaint` and built with `pathOf(shape, size)`:
the commands become a `Path`, so the same value draws the same silhouette at any
size, and the stroke is centred on the outline (half of it therefore lies outside a
box whose outline touches its edge, as it does in the browser). `ClipPath` clips the
pointer as well as the paint, so a shaped box that also says `overflow:
Overflow.hidden` answers only inside its outline — a browser answers for the whole
rectangle, which is one of the differences hit testing already had.

The scroll offset is the one report whose **edges** differ from the browser's: an iOS
bounce reports negative pixels and a value past the end, while `scrollTop` clamps at zero
and at the content's height. In the middle of the range the two numbers agree, which is
where a folding header or a "back to the top" control reads them.

A viewport a box builds runs under a **scroll configuration that drops the overscroll
decoration**: a Material application wraps a scroll view it did not write in a
`GlowingOverscrollIndicator` — a wash of the primary colour, or a stretch of the content —
and a browser paints nothing when a panel is pulled past its end. That wash is chrome, which
is the one thing a node never keeps, so pulling a box past its end shows only its content.
The physics, the devices a drag may use and the scrollbar stay the host's: the box says what
it looks like, not how a platform scrolls. On the web the same statement is
`overscroll-behavior: contain`, which stops the scroll chaining into the page while leaving the
box the pull that says "this is the end". What that pull reveals is the box's own
`backgroundColor` — so a panel that states the surface of the bar at its edge shows that surface
and never the page through a gap, on either target.

A **pin** is drawn by the box that scrolls: the band comes out of the flow, its slot stays
in it, and a `_RenderPinnedBand` repaints it at the edge it named — so a scroll costs a
repaint and not a rebuild, and a field inside the band keeps its state while it is carried
around. A pin that has no scrolling box above it in the tree is the one place the two
renderings part: a browser pins it to the document, which scrolls a page even though the
tree holds no viewport, while Flutter draws it where the flow put it, because the surface
an application is drawn on does not scroll. Put the scroll in the tree — a box with
`overflow: Overflow.scroll` — and the two agree, which is what the example does.

A **fold** is drawn the same way: a `_RenderFoldedBox` reads how far the box has left its
viewport when it paints and interpolates the decoration, the opacity and the transform
there, so a scroll costs a repaint of one layer. Two edges are worth knowing. A fold runs
as the box leaves through the *top* of the viewport, which is the journey a hero makes as
the content under it comes up; a box that leaves through the bottom keeps its resting look
here while a browser's `view()` folds it. And a Flutter tree whose box has no `Scrollable`
above it — the page of an application that does not scroll itself — keeps the resting look,
where the served document folds as the reader scrolls it.

`width`/`height: double.infinity` expands to fill the available space. Inside a
flex parent the expanding child is wrapped in an `Expanded` (using `flex`, or
`1` when unspecified), elsewhere it is a `SizedBox` that fills the bounded
parent. An infinite dimension in an unbounded parent is a layout error, exactly
like a tight infinite `SizedBox` in plain Flutter.

## Semantics

A node says what it *is* as well as how it looks, and Flutter can express most of
it. Nothing in this section changes a pixel.

| Token | Flutter |
| --- | --- |
| `TextNode.headingLevel` | `Semantics(header: true, headingLevel: n)` around the `Text` |
| `BoxSemantics.element` = `ul`, `ol` | `SemanticsRole.list` |
| `BoxSemantics.element` = `li` | `SemanticsRole.listItem` |
| `BoxSemantics.element` = `form` | `SemanticsRole.form` |
| `BoxSemantics.element` = `main`, `nav`, `header`, `footer`, `aside`, `section`, `article`, `figure` | nothing: Flutter's accessibility tree has no landmarks, and a phone reader navigates by headings and reading order |
| `BoxSemantics.role` | `button`, `link`, `header`, `checked`/`toggled` and the focused flag of `Semantics` |
| `BoxSemantics.expanded` / `.selected` | `Semantics.expanded` / `Semantics.selected` |
| `BoxSemantics.pressed` | `Semantics.toggled`, which is also what a `switch_`'s `checked` becomes |
| `BoxSemantics.hidden` | `Semantics.hidden`, and the box is never focusable |
| `BoxSemantics.liveRegion` | `Semantics.liveRegion` |
| `BoxSemantics.label` | `Semantics.label`, with the contents excluded so the two cannot drift |
| `BoxSemantics.current` | `selected: true`: Flutter has no `aria-current`, so the current item is announced as the selected item of a set |
| `Box.onLongPress` | `Semantics.onLongPress`: an action a reader can invoke, which is what a native `InkWell` offers. The web has no equivalent, so the web README records the difference |
| `TextInputNode.required` / `.invalid` | `Semantics.isRequired` / `Semantics.validationResult` |
| `TextInputNode.description` | `Semantics.hint`, announced after the label |

**One node per control.** A box that can be pressed is described by one `Semantics`
node carrying its role, its name and its action, the way Flutter's own buttons are:
the `Focus` widget around it is built with `includeSemantics: false`, and the focus
itself is stated by the box. A `Focus` that describes itself makes a node of its own
*inside* the control, and the label and the tap action merge into that one — so an
enabled button read as "Save" with a tap action and no role at all, while the role sat
on an empty parent. A disabled button, having no action to merge, was the only one
announced correctly.

## Text mapping

| Unibox                  | Flutter                                                        |
| ----------------------- | -------------------------------------------------------------- |
| `fontSize`              | `TextStyle.fontSize`                                            |
| `fontWeight`            | `TextStyle.fontWeight` (`light` → `w300`, `normal` → `w400`, `medium` → `w500`, `semiBold` → `w600`, `bold` → `w700`) |
| `color`                 | `TextStyle.color`                                               |
| `lineHeight`            | `TextStyle.height` (both are a multiple of the font size)       |
| `fontFamily`            | `TextStyle.fontFamily`                                          |
| `letterSpacing`         | `TextStyle.letterSpacing`                                       |
| `decoration`            | `TextStyle.decoration` (`none`, `lineThrough`, `underline`)     |
| `decorationColor`       | `TextStyle.decorationColor`                                     |
| `textAlign`             | `Text.textAlign`                                                |
| `maxLines` / `overflow` | `Text.maxLines` / `Text.overflow` (`clip`, `ellipsis`)           |

Typography tokens that are left unset are not passed to Flutter, so the ambient
`DefaultTextStyle` keeps providing them.

The ambient style is the model's, not the host's: `renderFlutter` wraps the tree in
a `DefaultTextStyle` carrying `BoxTextStyle.defaults`, so a text that declares
nothing is typeset at 16 logical pixels, black, with a 1.5 line height, exactly as
the web renderer's `:root` rule does. It is a merge, not a replacement: a host that
brought a font family keeps it, because the family is the one token the model
leaves to the application.

A line box is `fontSize * lineHeight` tall, which is the same length a unitless
CSS `line-height` gives on the web: that is the one measurement the two renderers
agree on exactly. Without a `lineHeight` the box is as tall as the font's own
metrics instead, which the browser and Skia do not have to compute the same way.

Where the glyphs sit inside that box is agreed on too. The leading the line height
adds is split half above them and half below, which is what CSS calls half-leading;
Flutter's own default distributes it in proportion to the font's ascent and descent,
and the two rules differ by about a pixel and a half at 16 pixels with a 1.5 line
height. Nothing about the layout moves either way — the box keeps its size and the
text moves inside it — which is what a reader sees as a jump when a page is handed
from the browser to Flutter, so the renderer asks for the CSS rule.

## Typography mapping

A `Box.textStyle` (or `BoxStyle.textStyle`) becomes a `DefaultTextStyle` around
the children of the box, merged with whatever the host application already
provides. Text nodes below it only pass the tokens they set themselves, so the
result is plain Flutter inheritance:

```dart
const card = Box(
  textStyle: BoxTextStyle(fontSize: 16, color: BoxColor.black),
  children: [TextNode('Inherits 16px'), TextNode('Still 16px', fontWeight: FontWeight.bold)],
);
```

`TextField` is the one widget that ignores `DefaultTextStyle`, so a
`TextInputNode` inside a box that sets typography takes its style from the
ambient text style explicitly. A field without such a box keeps Material's input
style, which is what a plain `TextField` does. The box records the resolved
typography in a `FlutterTextStyleScope`, the inherited widget the field looks for.

Precedence, from strongest to weakest: the tokens of the node, the tokens of its
`style`, the typography of the closest enclosing box, the `DefaultTextStyle` of
the host application, and finally the Flutter default.

`decorationThickness` is the one typography token this target does not pass on. The
model measures a line in logical pixels, which is what CSS's
`text-decoration-thickness` takes; `TextStyle.decorationThickness` is a multiple of
the thickness the font asks for, so the same number would be two pixels on the page
and twice the font's own line in the app. The app therefore draws the font's own
line — the same asymmetry as `srcSet` below, and the reason `decoration` and
`decorationColor` are in the conformance table while the thickness is not.

## State mapping

A box style can differ per interaction state. The states stack like CSS pseudo
classes: hover, then focus, then press, each laid over the resting style.

| Unibox state        | Flutter                                                     |
| ------------------- | ----------------------------------------------------------- |
| `BoxState.hover`    | `MouseRegion` toggling a rebuild, `hoverStyle` is its sugar  |
| `BoxState.focus`    | `Focus`, only when `semantics.role` can be acted on          |
| `BoxState.pressed`  | `GestureDetector.onTapDown` / `onTapUp` / `onTapCancel`      |
| `BoxState.disabled` | `enabled: false` on the handlers                            |
| enter / space       | `Focus.onKeyEvent` calling the `onTap` callback              |

`hoverStyle` is the long hand of `stateStyles[BoxState.hover]`; an entry in the
map wins over it. A box with a role the user can act on joins the tab order and
activates on Enter (on key down) and Space (on key up), which is what a button
does everywhere else.

`enabled: false` keeps the layout and the widget shape: the box still renders,
takes its `BoxState.disabled` style, reports itself as disabled through
`Semantics`, and gets no pointer cursor, no hover tracking and no callbacks.

## Semantics mapping

| Unibox                                  | Flutter                                                |
| --------------------------------------- | ------------------------------------------------------ |
| `BoxRole.button`                        | `Semantics(button: true)`                              |
| `BoxRole.link`                          | `Semantics(link: true)`                                |
| `BoxRole.heading`                       | `Semantics(header: true)`                              |
| `BoxRole.checkbox` + `checked`           | `Semantics(checked: …)`                                |
| `BoxRole.switch_` + `checked`            | `Semantics(toggled: …)`                                |
| `semantics.label`                        | `Semantics(label: …)`, replacing the contents           |
| `enabled`                                | `Semantics(enabled: …)`                                |
| a focusable role                         | `Semantics(focusable: true, focused: …)`                |

A box without semantics renders no extra `Semantics` node, so a plain container
costs nothing. A box with a label excludes the semantics of its contents: the
label *is* the accessible name, which keeps the announced text and the visible
text from drifting apart.

## Image mapping

| Unibox                        | Flutter                                             |
| ----------------------------- | --------------------------------------------------- |
| `src` with an `http(s)` URL   | `Image(image: NetworkImage(src))`                   |
| any other `src`               | `Image(image: AssetImage(src))`                     |
| `width` / `height`            | `Image.width` / `Image.height`                      |
| `fit`                         | `BoxFit` (`cover`, `contain`, `fill`, `scaleDown`), `scaleDown` when the node names none |
| `alt`                         | `Image.semanticLabel` (omitted when empty)          |
| `borderRadius`                | `ClipRRect`                                          |

A source that fails to load renders an empty box with the declared dimensions
instead of throwing, so a broken image never breaks the layout.

### What this target does not read

`srcSet`, `sizes`, `loading` and `fetchPriority` are web attributes, and a Flutter
image loads exactly one source:

| Unibox | Flutter |
| --- | --- |
| `srcSet`, `sizes` | nothing — `src` is what a device gets |
| `loading` | nothing — an `Image` starts loading as soon as it is built, which is `ImageLoading.eager`, the model's default |
| `fetchPriority` | nothing |

This is the one node field where the two renderings deliberately differ, and the
reason the model's default is `eager`: a default has to be the answer both targets
can give. Ship `src` at the size a phone needs; the wider candidates are then a
free improvement on the web. A density-aware Flutter image would need
`ResizeImage` and the laid-out width, which is a measurement a rendering does not
have.

## An image a host draws

`ImageNode` renders `Image(image: NetworkImage(src))`: no disk cache, no placeholder,
no key that depends on the space it is drawn in. The model has no token for any of
those — a cache and a placeholder are policies of an application — so the way an app
supplies them is the escape hatch the model already has, an `EmbedNode` of its own.

The shape of it: **a tree takes the image it should draw as a function**, and the host
passes the function.

```dart
// image_spec.dart — in the package that holds the trees, importing unibox_core only
/// The image a layout asks for.
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
  final bool priority;
}

/// What a tree draws when the host offers nothing of its own.
UINode defaultImage(ImageSpec spec) => ImageNode(
  spec.src,
  alt: spec.alt,
  height: spec.height,
  fit: spec.fit,
);
```

A builder takes `UINode Function(ImageSpec) image` and calls it where it used to write an
`ImageNode`. The app passes its own implementation, which returns
`FlutterWidgetNode(YourCachedImage(…))` — its disk cache, its placeholder, its blurhash,
its carousel — and everything around the picture still lays out with boxes.

**A tree built with a host embed is that host's tree.** `FlutterWidgetNode` carries a
`Widget`, so the web renderer reports an embed it cannot draw; the server, the static
export, the crawler and the test build the same page with `defaultImage`, which returns
the model's `ImageNode` and renders on both targets. That is why the function is a
parameter and not a lookup: one builder, two values, and no Flutter import in the library
that holds the trees.

## Colour roles

`renderFlutter(node, theme: myTheme)` resolves every role a tree names while the
widget tree is built, so everything below reads a concrete colour and nothing looks
anything up at paint time. `node.toWidget(theme: myTheme)` is the same call through the
extension on `UINode`, and it takes the theme for that reason: the shorthand must be able
to draw the themed trees it is advertised for.

| Unibox | Flutter |
| --- | --- |
| `BoxColor.role(AppColor.primary)` | the value `myTheme` gives that role |
| a literal `BoxColor` | itself, theme or no theme |
| a role and no theme | the tree is rejected by validation, naming the role |

The theme travels down in `UniboxThemeScope`. A host that roots its application in a
`FlutterStateful` passes it to that component (`FlutterStateful(node: …, theme: …)`)
instead of wrapping a scope itself; a host that renders part of a tree with another
theme still wraps `UniboxThemeScope` around it. An overlay is the one
place it has to be handed over by hand: its content lives on the root overlay, which
is outside the tree the page was rendered in, so `FlutterOverlay` reads the scope and
passes it on.
## Grid mapping

A `GridNode` is a `LayoutBuilder` that asks the node for the count and the cell
width at the constraints it was given, then lays out one `Row` per line of
fixed-width slots with `SizedBox` gutters. A short last line is padded with empty
slots of the same width — `auto-fill` creates every track, so the last cards keep
their track instead of stretching, which is why nothing here is `Expanded` or
`Flexible`. Cards are top-aligned in a row that is as tall as its tallest card
(`align-items: start` on the web).

A card that states `gridSpan` is given the width of that many tracks and the gutters
between them (`GridNode.spanWidthFor`), and the row it is on skips the tracks it
covers; a span that does not fit in the tracks a row has left starts the next row,
leaving the rest of the current one empty. `GridNode.spanOf` is the number of tracks,
clamped to the columns the width gives, so a banner that asks for more than the grid
has is a full row rather than an overflow.

An unbounded width — a grid inside a horizontal scroll view, or in a row that
lets its children be as wide as they like — gets one column of `minItemWidth`,
which is the answer `columnsFor` gives and the one that needs no surface.

## Navigation mapping

The destination is a token on the control, not a node around it, so there is nothing here
that a box does not already do:

| Unibox   | Flutter                                                        |
| -------- | -------------------------------------------------------------- |
| `url`    | a hand cursor, `Semantics(link: true)`, and a press that opens it through `FlutterLinkScope` |
| `onTap`  | `GestureDetector.onTap`, which answers the press instead of the scope |
| `onTapDown` | `GestureDetector.onTapDown`, which is where a ripple starts     |
| `newTab` | web only, ignored by the Flutter renderer                       |
| `BoxElement.a` with no `url` | a plain box: with no `href` there is nothing to follow and nothing to announce |

Flutter has no browser of its own, so the host application decides what following a
destination means and the renderer only reports it:

```dart
FlutterLinkScope(
  open: (String url) => launchUrl(Uri.parse(url)),
  child: renderFlutter(page),
);
```

A `LinkNode` is a click-cursor region that a screen reader hears as a link, and it opens
with `Enter` — not with `Space`, which a browser does nothing with on an anchor. A link
with an `onTap` is handled by the tree and the scope is not asked: one press, one answer, and the web renderer says the same thing by cancelling the navigation rather than
loading the document too. A destination with neither a scope nor an `onTap` is reported as
a host configuration error in debug builds instead of silently doing nothing.

Because the gesture stays the box's own, its pressed state and the ink a `MaterialInkWell`
starts on tap-down are its own too: a component is a destination by being given a url, and
the control a reader presses is the control a crawler reads.

## Stack mapping

| Unibox                            | Flutter                              |
| --------------------------------- | ------------------------------------ |
| `StackNode.children`              | `Stack` children, painted in order   |
| `StackNode.width` / `height`      | `SizedBox` around the stack          |
| `PositionedNode` offsets          | `Positioned`                         |
| `PositionedNode` without offsets  | plain stack child                    |

Stacks behave like CSS `overflow: visible` and do not clip their content. A
`PositionedNode` rendered outside a `StackNode` renders its child without
applying the offsets, because offsets are relative to the enclosing stack.

**A box that holds only a layer.** A `Box` with one `StackNode` child keeps its own
main and cross alignment for what the layer draws, which a browser gets for free:
there the stack is the flex's single flow child, so the pair places the stack itself
and its cell takes the size of its content. Flutter cannot hand a stack an unbounded
main axis — an aligned `PositionedNode` inside it needs a bounded one — so the stack
fills the box instead and the alignment becomes the stack's own, which is the same
rectangle for every child that is not positioned. That is what centres a segmented
button's label in its pill, and the cross of a chip's close target in it.

## Text input mapping

| Unibox                      | Flutter                                              |
| --------------------------- | ---------------------------------------------------- |
| `value`                     | `TextEditingController` text, kept in sync           |
| `placeholder`               | `InputDecoration.collapsed(hintText: …)`              |
| `obscureText`               | `TextField.obscureText`                              |
| `multiline`                 | `minLines` / `maxLines` and `TextInputType.multiline` |
| `maxLines`                  | `TextField.maxLines` of a multiline field            |
| `onChanged` / `onSubmitted` | `TextField.onChanged` / `TextField.onSubmitted`       |

The renderer builds on Material's `TextField`, so it needs a `Material`
ancestor such as `MaterialApp`. With `value: null` the field keeps whatever the
user typed; as soon as the owner passes a value the controller follows it,
replacing the text and moving the caret to the end.

The field itself carries no decoration: no underline, no fill, no content padding
and no 48 pixel minimum height, so it occupies exactly its line box. That is what
a plain `<input>` does on the web, and it is what lets one node tree look the
same on both targets — a box that wants a field to look like a field draws the
border, the background and the padding around it. The field does adopt the
typography of its box, line height included, through `FlutterTextStyleScope`; that
is what sizes it.

## Motion

A box with a `BoxTransition` eases the change of its paint tokens — background,
border colour, corner radius and shadows — between the resting style and a state
style. The `DecoratedBox` becomes a `TweenAnimationBuilder<Decoration>`, which
tweens from the decoration it painted last to the one the new state asks for; that
is exactly the set `BoxDecoration.lerp` covers, and `BoxCurve` maps one to one
onto `Curves.linear`, `Curves.ease`, `Curves.easeIn`, `Curves.easeOut` and
`Curves.easeInOut` — the five curves whose control points CSS shares, so both
targets ease the same way.

An `opacity` becomes an `Opacity` and a `transform` a `Transform` about the centre,
which is where CSS puts a transform by default; when the box can change its look, the
animated versions take over (`TweenAnimationBuilder` over `BoxTransform`,
`AnimatedOpacity`) and stay in the tree while the resting look is the identity, or a
state that introduces a scale would start from the end value instead of easing.

The parts of a transform are interpolated one by one, not as one matrix: a matrix lerp
would shrink a box that only turns. `scaleX` and `scaleY` multiply `scale` into the two
axes of that matrix, so a box can stretch sideways at its own height — which is how
Material's navigation indicator grows out of its icon. Layout never animates, and neither does the border
width: a state that moves the box changes the widget tree instead, which is what both
targets do when a layout change has to be animated by the host.

## Your own component

A component of your own is a function returning a node tree, or — when it needs
something the model does not have — an `EmbedNode` with one implementation per
renderer. This package is the Flutter half:

```dart
final class InkRipple extends core.EmbedNode {
  const InkRipple({required super.child, required this.onTap});

  final VoidCallback onTap;

  @override
  List<Object> get implementations => <Object>[
    // This target draws a FlutterWidgetEmbedBuilder, which receives the child.
    (Widget child) => InkWell(onTap: onTap, child: child),
  ];
}
```

An implementation is either a `Widget`, drawn as it is, or a `FlutterWidgetEmbedBuilder`
(`Widget Function(Widget child)`), which receives the rendered child — that is what
an effect that wraps content needs. `FlutterWidgetNode` is the convenience for a single
widget payload with no child; a node carrying an implementation this target cannot
draw, or two of them, is reported by `renderFlutter` instead of being skipped.

## Stateful nodes

A [`StatefulNode`](../unibox_core/README.md#state) is rendered by `FlutterStateful`,
written once for every node an application defines:

- the store is created when the widget mounts, subscribed to, and `onMount` is
  called; a rebuild with a node of the same type and key keeps the state, and a
  different key starts again;
- every notification rebuilds the view, and unmounting calls `onUnmount` and then
  `dispose` on the store;
- the view's tree is rendered in place, so it inherits the typography and the
  layout of the boxes around it;
- the view returns one tree; a dialog is an `OverlayNode` in it, presented through
  the root overlay, so nothing in this layer is modal.

## Overlays

An `OverlayNode` is presented through an `OverlayPortal` on the root overlay, so it
escapes the clipping and the scrolling of the boxes around it:

- the node's barrier covers the page with `barrierColor`; a press dismisses it
  when `barrierDismissible` is set and the node has an `onDismiss`;
- `Escape` calls `onDismiss` while the overlay has focus;
- a `FocusScope` with closed-loop traversal keeps Tab inside the content, and the
  focus that was on the page goes back to it when the overlay leaves;
- the content is bounded by the room the window gives it, and a dialog taller than
  that room scrolls: the layer is a scroll view whose content is the size of the
  window, so the same card is the same height here as on the web;
- the barrier rides inside the scroll view, so a press beside a long dialog is
  still a press on the scrim;
- the layer is announced as a route, so a screen reader enters it as a dialog;
- the node itself takes no room: the portal's child is empty.

A tree that contains an overlay needs an `Overlay` above it — every `MaterialApp`
or `WidgetsApp` provides one.

## Testing

```sh
flutter test
```

Widget tests build the widgets `renderFlutter` returns. `test/conformance_test.dart`
runs the renderer against [`unibox_testing`](../unibox_testing) — the table
of boxes both renderers are checked against — through
`test/support/appearance.dart`, which reads the presentation of a box back out of
the widget tree this renderer built. The the web renderer suite answers the same table from
the CSS it emits, so a token that stops rendering fails a test instead of only
making the two targets drift apart.
