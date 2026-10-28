# unibox_jaspr

Jaspr renderer for [Unibox](../unibox_core) layout primitives.

```dart
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_jaspr/unibox_jaspr.dart';

const card = Box(
  width: double.infinity,
  padding: BoxSpacing.all(16),
  backgroundColor: BoxColor.white,
  borderRadius: 12,
  children: [TextNode('Hello')],
);

void main() {
  runApp(renderJaspr(card)); // or, equivalently: card.toComponent()
}
```

Nodes without a web renderer yet throw an `UnsupportedError` instead of silently
rendering nothing.

## Box mapping

| Unibox                        | Jaspr / CSS                                            |
| ----------------------------- | ------------------------------------------------------ |
| always                        | `<div>` with `box-sizing: border-box`                  |
| `direction: Axis.horizontal`  | `display: flex` + `flex-direction: row`                |
| `direction: Axis.vertical`    | `display: flex` + `flex-direction: column`             |
| no `direction`                | `display: flex` + `flex-direction: column`, as above   |
| `mainAlign` / `crossAlign`    | `justify-content` / `align-items` (`start` by default)  |
| `gap`                         | `gap`                                                  |
| `width`, `height`, `min*`, `max*` | `width`, `height`, `min-width`, ...                |
| `padding` / `margin`          | `padding` / `margin` shorthands                        |
| `backgroundColor`             | `background-color`                                     |
| `borderRadius`                | `border-radius`                                        |
| `corners`                     | `border-radius` with the four values, in CSS's order   |
| `PositionedNode.alignment`    | `inset: 0` with a `justify-content`/`align-items` pair  |
| `border`                      | `border` (`none` when the width is zero)               |
| `shadow`                      | `box-shadow`                                           |
| `overflow`                    | `overflow` (`scroll` → `auto`)                         |
| `flex`                        | `flex-grow` / `flex-shrink: 1` / `flex-basis: 0`        |
| `onTap` / `onLongPress`       | `click` and pointer listeners plus `cursor: pointer`    |
| `onHover`                     | `mouseenter` / `mouseleave` listeners                   |
| `stateStyles`                 | scoped `.unibox-box-…` rules, one per state             |

`width`/`height: double.infinity` becomes `100%`, numbers become logical pixels
(`px`). Tokens that are left unset emit no CSS property at all, so browser
defaults and inherited typography keep applying — the same rule the Flutter
renderer follows with `DefaultTextStyle`.

Opaque colors render as `#rrggbb`, translucent colors as `rgba(…)`.

### State styles

A state is a pseudo class, and a pseudo class cannot reach an inline style, so a
box with states is rendered as a class:

```html
<style>
  .unibox-box-1f3c9a7b { … }
  @media all and (hover: hover) {
    .unibox-box-1f3c9a7b:hover { … }
  }
  .unibox-box-1f3c9a7b:focus-visible { … }
  .unibox-box-1f3c9a7b:active { … }
  .unibox-box-1f3c9a7b[aria-disabled="true"] { … }
</style>
<div class="unibox-box-1f3c9a7b">…</div>
```

| Unibox state        | CSS selector                                    |
| ------------------- | ----------------------------------------------- |
| `BoxState.hover`    | `:hover` inside `@media (hover: hover)`          |
| `BoxState.focus`    | `:focus-visible`                                |
| `BoxState.pressed`  | `:active`                                       |
| `BoxState.disabled` | `[aria-disabled="true"]`                        |

Every rule carries only the tokens of its state, so the browser layers them over
the resting rule the way CSS always does, and `hoverStyle` is nothing but the
`BoxState.hover` entry. That includes the flex layout: `flex-direction`,
`justify-content` and `align-items` stay with the resting rule, because a state
rule that restated them would reset the layout — hovering a row would turn it
into a column. Hover sits inside a media query so a touch screen cannot get
stuck in a hovered look, and focus uses `:focus-visible` so a mouse click never
paints a focus ring.

The class name is a hash of the resolved styles and of every state, which keeps
the output deterministic: server rendered markup and the hydrated client agree
without any extra state, and boxes that share a style share a class.

Sharing a *name* is not the same as writing the rules once, and that is what the
stylesheet settled: a state-styled box used to carry its own `<style>` element, so
six identical cards emitted six identical blocks. The example's listings page came
to twelve `<style>` elements for three distinct classes, one of them restated twelve
times. Every look in the tree is now written once; see
[The stylesheet](#the-stylesheet).

## The stylesheet

Nothing in the tree is written inline. Every distinct set of declarations becomes
one class rule — `unibox-box-…`, `unibox-text-…`, `unibox-image-…`, `unibox-field-…`,
`unibox-stack-…`, `unibox-link-…`, `unibox-overlay-…` — and the element carries
that class instead:

```html
<style>
  .unibox-box-1f3c9a7b { display: flex; … }
  .unibox-text-6c1d0e2f { color: #111827; font-size: 16px; font-weight: 600; }
</style>
<div class="unibox-box-1f3c9a7b">
  <span class="unibox-text-6c1d0e2f">€1850 / month</span>
  <span class="unibox-text-6c1d0e2f">€1240 / month</span>
</div>
```

Three things follow, and they are the reason it is done this way:

- **A look is written once.** Six listings with the same look declare it once and
  wear the same class, so the CSS grows with the number of *distinct* looks on a
  page rather than with the number of elements. On this repository's own site, 224
  elements share 73 rules.
- **A host can override anything.** An inline style beats every stylesheet, so a
  page that carried one per element could not be themed — not with a custom
  property, not with `@media (prefers-color-scheme: dark)`, not with a rule of its
  own. A class can be outranked by a stylesheet the host controls.
- **The markup says what an element is, not how it looks**, which keeps the
  response small once it is compressed and lets the CSS be cached next to the HTML
  instead of being rebuilt inside it.

A server writes the sheet as the `<style>` of the tree, at the end of the page. A
browser writes it into `<style id="unibox-styles">` in the head instead and keeps
it there: a state change redraws one subtree, so a look that subtree registers is
appended to the element already in the page rather than waiting for a second full
render. Those are the only two shapes — a sheet that is text in a response, and a
sheet that is an element in a document.

The consequence to know about is cost: a class is keyed by its declarations, so a
component that redraws every frame — a ripple — registers a look per frame and the
sheet grows as it runs. That is why `MaterialInkWell` moves its ink by `transform`
and keeps the node that positions it at a constant offset: one new rule a frame
rather than two, and a server page pays nothing at all.

### Roles and the theme

A colour role is written as a custom property, and the theme is written once, in
`:root`:

```html
<style>
  :root {
    --unibox-color-primary: #2d6cf3;
    --unibox-color-surface: #ffffff;
  }
  .unibox-box-1f3c9a7b { background-color: var(--unibox-color-primary); }
</style>
```

Every role the theme defines is emitted, whether or not a node names it: a host
stylesheet or an embed has to be able to read a role the tree happens to leave
alone, and a block that changed with the content would be a different document
every time the content did. The name is the enum member in kebab case.

```dart
renderJaspr(node, theme: myTheme);   // emits :root and points the rules at it
```

A host that composes the components itself — a page whose root is a
`JasprStateful`, say — installs `JasprThemeScope` around its tree instead, and the
stylesheet is written for it the same way. Overriding a role is then ordinary CSS:

```css
@media (prefers-color-scheme: dark) {
  :root { --unibox-color-canvas: #101216; }
}
```

The rules are emitted as a single `<style>` element after the tree, so a page has
that element once however many components registered a class; CSS applies wherever
that element sits. A component rendered on its own — `JasprBox(box: box)` in a
test, or `renderNode` called directly — finds no stylesheet in scope and writes its
declarations inline, which is what a single node can still do correctly.

### Semantics

| Unibox                                   | Attribute                        |
| ---------------------------------------- | -------------------------------- |
| `BoxRole.button` / `.link` / `.heading`  | `role="button"`, `link`, `heading` |
| `BoxRole.checkbox` / `.switch_`          | `role="checkbox"` / `switch`     |
| `semantics.label`                        | `aria-label`                     |
| `semantics.checked`                      | `aria-checked="true"` / `"false"` |
| `enabled: false`                         | `aria-disabled="true"`           |
| a role the user can act on               | `tabindex="0"` plus `keydown` / `keyup` |

A box with such a role enters the tab order and activates on Enter and Space,
with `preventDefault` so Space does not scroll the page. A disabled box carries
`aria-disabled`, keeps its layout, and gets no listener at all.

### Interaction

A box without callbacks renders no listeners, so static pages ship no
JavaScript for it. A tappable box also gets `cursor: pointer`. Long presses map
to pointer listeners with a 500 ms threshold and suppress the follow-up `click`,
mirroring Flutter.

## Developer labels

An element's `class` is a hash of its declarations — `unibox-box-1f3c9a7b` — which is
what makes two elements with the same look share one rule, and what makes a page of
them unreadable in an inspector. So every element a node draws also carries the name
of that node:

```html
<div class="unibox-box-1f3c9a7b" data-unibox-node="material-card">…</div>
```

| The element | `data-unibox-node` |
| --- | --- |
| drawn by a node | the name of that node |
| a wrapper the renderer invents — a stack's cell wrapper | absent: no node drew it |

The value is `UINode.debugName`, which is a **literal** the node states in
`debugLabel`: `Box` reads `box`, `TextNode` reads `text`, `LinkNode` reads `link`,
`GridNode` reads `grid`, `MaterialCard` reads `material-card`. The type is never
consulted — a compiled build mangles class names, and a page that shipped
`data-unibox-node="minified:-s"` would be worse than one that says nothing — so a
node of your own names itself with one override, and a subclass that says nothing
inherits the name of the node it extends.

It is written always, with no flag to turn it off. An attribute that carries no look
has nothing a switch could protect, and because there is no switch, a server render
and the client that hydrates it cannot disagree about it.

It is an attribute rather than a class because `class` is the stylesheet's namespace:
a second class there would either carry no rule — confusing every reader of the
output — or become a look a host can write and Flutter cannot. A name adds no class,
no rule and no element, and nothing reads it back, so it cannot change what a page
looks like: two node types with the same look share one class and one rule while
carrying different names.

## Element mapping

`BoxSemantics.element` decides the tag a box renders as. Everything the box
carries — styles, classes, attributes and listeners — goes on that element, so
`<main>` *is* the page box rather than a wrapper around it.

| `BoxElement` | Tag | Role it already implies |
| --- | --- | --- |
| `div` (default) | `<div>` | none |
| `main`, `nav`, `header`, `footer`, `aside` | `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>` | the matching landmark |
| `section` | `<section>` | `region` |
| `article`, `form`, `figure` | `<article>`, `<form>`, `<figure>` | `article`, `form`, `figure` |
| `ul`, `ol`, `li` | `<ul>`, `<ol>`, `<li>` | `list`, `list`, `listitem` |
| `figcaption` | `<figcaption>` | none: naming the figure is what the tag does |

`role` is only written when the box asks for one its element does not imply: a
`<nav>` carries no `role="navigation"` next to it, while a `<div>` with
`BoxRole.link` does carry `role="link"`. A list and a figure also get the space a
browser adds around them cancelled (`padding: 0` and `margin: 0`), because no
Flutter counterpart has it.

## Semantics attributes

| Token | Attribute |
| --- | --- |
| `BoxSemantics.role` | `role`, unless the element already implies it |
| `BoxSemantics.label` | `aria-label` |
| `BoxSemantics.checked` | `aria-checked` on a checkbox or a switch |
| `BoxSemantics.expanded` | `aria-expanded` |
| `BoxSemantics.selected` | `aria-selected` |
| `BoxSemantics.liveRegion` | `aria-live="polite"` |
| `BoxSemantics.hidden` | `aria-hidden="true"`, and no `tabindex` |
| `Box.enabled` | `aria-disabled="true"`, and no listeners |
| `BoxSemantics.current` | `aria-current="page"`, `"step"` or `"location"` |
| `TextInputNode.required` | `aria-required="true"` |
| `TextInputNode.invalid` | `aria-invalid="true"` |
| `TextInputNode.description` | `aria-description`, carrying the text itself so no element has to be referenced by an id |

## Text mapping

A `TextNode` becomes a `<span>`, so it flows inline like Flutter's `Text` does
inside a `Row`.

| Unibox          | Jaspr / CSS                                      |
| --------------- | ------------------------------------------------ |
| `fontSize`      | `font-size` in `px`                              |
| `fontWeight`    | `font-weight` (`normal` → `400`, `bold` → `700`) |
| `color`         | `color`                                          |
| `lineHeight`    | unitless `line-height`                           |
| `fontFamily`    | `font-family`                                    |
| `letterSpacing` | `letter-spacing` in `px`                         |
| `textAlign`     | `text-align`                                     |
| `headingLevel`  | `<h1>`–`<h6>`, with the user agent styles cancelled |
| `maxLines`      | `-webkit-line-clamp` box                         |
| `overflow`      | `text-overflow`                                  |

Typography that the node leaves unset emits nothing, so the text inherits the
font family, size, weight and color of the page — the same contract
`DefaultTextStyle` provides in Flutter.

What the page starts from is the model's, not the browser's: `renderJaspr` emits a
`:root` rule carrying `BoxTextStyle.defaults` (16 logical pixels, black, a 1.5 line
height, no letter spacing, `font-family: system-ui`), which is what the Flutter
renderer installs as a `DefaultTextStyle` around the tree. A host that renders other
content next to the tree can restyle its own, and a host that wants a font family
states one — the family is the one token the model leaves to the application.

`maxLines` needs the prefixed box layout, since that is the only portable way to
truncate after N lines:

```css
display: -webkit-box;
-webkit-box-orient: vertical;
-webkit-line-clamp: 2;
overflow: hidden;
```

An `ellipsis` without `maxLines` truncates the single line instead
(`white-space: nowrap; overflow: hidden; text-overflow: ellipsis`), while `clip`
only hides the overflow.

Inside a clamp, `clip` cannot be honoured: `-webkit-line-clamp` always ends the
last line with an ellipsis and `text-overflow: clip` does not remove it, so a
`maxLines` with `TextOverflow.clip` ellipsizes here and cuts off in Flutter. Use
`maxLines` with `TextOverflow.ellipsis` when the two have to agree.

A unitless `line-height` makes a line box `fontSize * lineHeight` tall, which is
exactly the box `TextStyle.height` produces in Flutter. Without a `lineHeight`
the browser uses the font's own metrics (`normal`), which is a length Skia does
not have to agree on — so declare it if a layout has to line up.

## Typography mapping

A `Box.textStyle` (or `BoxStyle.textStyle`) is emitted on the `<div>` as the font
properties CSS inherits by default, so every descendant picks it up without
repeating it:

| Unibox          | Jaspr / CSS                                      |
| --------------- | ------------------------------------------------ |
| `fontSize`      | `font-size` in `px`                              |
| `fontWeight`    | `font-weight`                                    |
| `color`         | `color`                                          |
| `lineHeight`    | unitless `line-height`, so descendants scale     |
| `fontFamily`    | `font-family`                                    |
| `letterSpacing` | `letter-spacing` in `px`                         |

The result matches the `DefaultTextStyle` the Flutter renderer installs, so the
same tree produces the same typography on both targets. A box without a
`textStyle` emits no font declaration at all and keeps inheriting from the page,
which is what `DefaultTextStyle` does in a Flutter application.

Text fields are replaced elements and do not inherit fonts on their own, so an
`<input>` and a `<textarea>` always emit `font: inherit`. That is the CSS
equivalent of the Flutter renderer letting a field adopt the ambient text style.

Precedence, from strongest to weakest: the tokens of the node, the tokens of its
`style`, the typography of the closest enclosing box, the page CSS, and finally
the browser default.

## Image mapping

An `ImageNode` becomes an `<img>` carrying its `src` and `alt` attributes, so
browsers can cache, lazy-load and describe the picture like any other image on
the page.

| Unibox           | Jaspr / CSS                                   |
| ---------------- | --------------------------------------------- |
| `src`, `alt`     | `src` and `alt` attributes                    |
| `width`/`height` | `width`/`height` (`double.infinity` → `100%`), and the same numbers as the element's `width`/`height` attributes |
| `fit`            | `object-fit` (`cover`, `contain`, `fill`, `scale-down`) |
| `borderRadius`   | `border-radius`                               |
| `corners`        | `border-radius` with four values (`8px 8px 0px 0px`) |
| `srcSet`         | `srcset`, one `url 200w` candidate per entry, narrowest first |
| `sizes`          | `sizes`                                       |
| `loading`        | `loading` (`eager`, `lazy`, `auto`)           |
| `fetchPriority`  | `fetchpriority` (`high`, `low`, `auto`)       |

A finite `width` or `height` is written twice: as CSS, which lays the picture out,
and as an attribute, which tells the browser the aspect ratio before the fetch, so
the page does not shift when the image arrives. A fractional size is rounded and
`double.infinity` has no attribute at all.

Images render as `display: block`, matching the leaf box they are in Flutter: no
line box, and therefore no baseline gap beneath the picture.

`object-fit` is always written, even when the node names no fit: the model's
answer is `ImageFit.scaleDown`, which CSS spells `scale-down`. Left out, the
browser would stretch the picture over its box (`object-fit: fill`) while Flutter
scales it down, so the same tree would look squashed on one target.

A single dimension keeps the natural aspect ratio, just like an `Image` that
only constrains one side. Relative sources need no rewriting: the browser
resolves them against the page while the Flutter renderer loads them as assets.

## Grid mapping

A `GridNode` is one `div` carrying the whole reflow as a single declaration:

```css
display: grid;
gap: 16px;
align-items: start;
grid-template-columns: repeat(auto-fill, minmax(min(100%, max(280px, (100% - 32px) / 3)), 1fr));
```

`auto-fill` creates the tracks from the width of the grid itself, so a narrow
container gets fewer columns with no media query, no script and no second payload:
the server render, the hydrated page and a resized window all resolve the same
declaration. The `min(100%, …)` clamp keeps a container narrower than the minimum
from overflowing, and the `max(…)` inside it is the column cap — once the width
fits three columns the minimum track grows, so the count stops at three and the
cards keep growing. Measured in Chromium and WebKit 18.2 at 250, 375, 600, 899,
900, 901, 1280 and 1440 pixels: the counts and gutters match
`GridNode.columnsFor` exactly, and the cards match it to the 1/64 pixel a browser
lays out with.

## Link mapping

A `LinkNode` becomes a real `<a>` element, so the link keeps working without
JavaScript: middle clicks, the context menu, prefetching and crawlers all behave
like they do on any other website.

| Unibox   | Jaspr / CSS                                          |
| -------- | ---------------------------------------------------- |
| `url`    | `href`                                               |
| `newTab` | `target="_blank"` plus `rel="noopener noreferrer"`   |
| `onTap`  | `click` listener that runs alongside the navigation  |

`onTap` is attached as a plain `click` listener rather than the component's
`onClick`, because `onClick` calls `preventDefault()` and would stop the browser
from following the link. A link without `onTap` renders no listeners at all.

The anchor also declares `color: inherit` and `text-decoration: none`, which
turns off the two things a browser adds to a link on its own. A link is not a
text node, so the typography of its box has to reach it explicitly, and the
Flutter renderer draws the child of a link exactly as it is — no link colour, no
underline — so leaving the user agent styles in place would make the same tree
look different on the two targets.

Relative destinations need no rewriting, and the Flutter renderer delegates the
actual navigation to the host through `FlutterLinkScope`.

## Stack mapping

A `StackNode` becomes a `<div>` with `position: relative` and `display: grid`.
Every child is placed in the same grid cell, so the children overlap and paint in
source order (last on top) while the container still sizes to its largest child —
a `Stack` with `Clip.none` in Flutter.

| Unibox                     | Jaspr / CSS                                          |
| -------------------------- | ---------------------------------------------------- |
| `StackNode`                | `position: relative` plus `display: grid`            |
| `StackNode.width`/`height` | `width`/`height` (`double.infinity` → `100%`)        |
| plain child                | `grid-area: 1 / 1` cell wrapper, content at the start |
| `PositionedNode`           | `position: absolute` plus `top`/`right`/`bottom`/`left` |

Each child is wrapped in a cell `<div>`: the overlap is a property of the
container, and the rendered child already carries its own inline styles.

The cell wrapper fills the grid area and lays its child out at the start of
both axes, which is what a `Stack` does with a child that is not positioned: the
cell is the constraint, the child is its own size. The wrapper is a flex container
rather than a content-sized grid item, because a child that asks to fill the cell —
`width: double.infinity`, rendered as `100%` — has to resolve that percentage
against the whole cell, and a wrapper without a width of its own would collapse it.

A `PositionedNode` without any offset keeps its natural place, exactly like the
`Positioned` widget Flutter never needed, and a `PositionedNode` rendered
outside a stack falls back to its child.

## Text input mapping

A `TextInputNode` becomes `<input type="text">`, `<input type="password">` when
`obscureText` is set, or a `<textarea>` when `multiline` is set. The field is
stretched over the available width with `box-sizing: border-box` — the layout a
Flutter `TextField` gets from the column it lives in — and it inherits the font,
the colour and the line height of its box, which is what sizes it.

A text area starts at one row and never shows the resize grip of a browser,
because a Flutter field starts at one line and has no grip: `rows` is written out
from `maxLines` and `resize: none` is part of the field styles.

Everything a browser draws around a form field by itself is stripped: no border,
no padding, no background, and no focus ring. A Flutter field carries no Material
decoration either, so the box around a field is the only thing that draws one, on
both targets.

The focus ring goes too, because a browser draws it around the field itself: the
field sits inside the padding and the border of the box that wraps it, so a
focused field would show a second frame inside the one the tree asked for, and
Flutter has no counterpart to it — a collapsed `TextField` only draws its caret.
The caret is what is left: the tree cannot draw a focus frame around a field
either, because a box raises its `focus` state by being focused itself rather than
by holding a focused child, and a browser matches `:focus-visible` on the focused
element only.

| Unibox        | Jaspr / HTML                                           |
| ------------- | ------------------------------------------------------ |
| `value`       | `value` attribute (input) or text content (text area)  |
| `placeholder` | `placeholder` attribute                                |
| `obscureText` | `type="password"`                                      |
| `multiline`   | `<textarea>` instead of `<input>`                      |
| `maxLines`    | `rows` of the text area                                |
| `onChanged`   | `input` listener                                       |
| `onSubmitted` | `keydown` listener: `Enter`, or `Ctrl`/`Cmd` + `Enter` |

A `value` makes the field controlled: rendering the node again with a new value
replaces what the user typed. Without a value the field keeps its own content and
only reports changes through `onChanged`.

`onSubmitted` fires on a bare `Enter` for a single line field and on
`Ctrl`/`Cmd` + `Enter` for a text area, because a plain `Enter` inserts a newline
there — the same split a Flutter `TextField` has with a multiline keyboard type.

Both listeners read the field through the `package:web` DOM types Jaspr itself
uses for `EventCallback`, which `universal_web` re-exports on every platform.

## Search engines and screen readers

What a crawler gets from this renderer is the page itself, not an empty shell that
needs JavaScript: text is text in the markup, an image is an `<img>` with its `src`
and `alt`, a link is a real `<a href>` that can be followed, and a semantics token
is a `role` plus its `aria-*` attributes. Nothing about the layout hides content
from a reader, and a static export is a plain document.

What the renderer does **not** do is document metadata, because metadata describes
a document while a node tree describes a region of one. The title, the language,
the description, a canonical url, Open Graph tags and structured data all belong to
the host, which in Jaspr means `Document`:

```dart
Document(
  lang: 'en',
  title: 'Apartments — Unibox',
  meta: <String, String>{'description': 'Six listings and a map.'},
  head: <Component>[
    link(attributes: {'rel': 'canonical', 'href': 'https://example.com/'}),
  ],
  body: renderJaspr(tree),
);
```

Two things are worth knowing before relying on this for search:

- **A heading is an element, and a landmark is a landmark.** `TextNode` with a
  `headingLevel` renders `<h1>`–`<h6>` (and Flutter announces the same level), and
  `BoxSemantics(element: BoxElement.main)` renders `<main>` — so the outline of the
  page is in the markup where a crawler reads it, without a look of its own:
  `role="heading"` on a `<div>` is what the model used to offer and is now the
  fallback for a heading that is not one run of text.
- **A box that navigates on tap is not a link.** `Box(onTap: ...)` with
  `BoxRole.link` is announced and keyboard operable, but it carries no `href`, so
  a crawler cannot follow it. A page that has to be found is reached by a
  `LinkNode`, which renders the anchor.

A sitemap is the third thing the renderer cannot write: it needs the url the pages
are served from, which only the deployment knows.

## Motion

A box with a `BoxTransition` writes a `transition` shorthand over the paint
properties it animates — `background-color`, `border-color`, `border-radius` and
`box-shadow` — with the curve spelled the CSS way (`linear`, `ease`, `ease-in`,
`ease-out`, `ease-in-out`, the five whose control points Flutter shares). The
browser interpolates whenever a `:hover`, `:focus-visible`, `:active` or
`[aria-disabled]` rule changes one of them, so nothing has to be scripted and a
static export animates without JavaScript.

`opacity` is the property of the same name and `transform` is CSS's own
`translate(x, y) rotate(deg) scale(s)`, in that order, with no `transform-origin`:
the browser centres a transform by default, which is where Flutter puts it too. Both
are in the transitioned list, so a state that introduces a scale or a fade is
interpolated by the browser — the lists match on both sides, which is what makes the
interpolation mean the same thing.

The shorthand only goes on the resting rule. A state rule restating the duration
would repeat a token the change owns, which is the same rule the flex layout
follows; layout never animates, and neither does the border width, because CSS
animates that as a layout change.

## Your own component

A component of your own is a function returning a node tree, or — when it needs
something the model does not have — an `EmbedNode` with one implementation per
renderer. This package is the web half:

```dart
final class InkRipple extends core.EmbedNode {
  const InkRipple({required super.child});

  @override
  List<Object> get implementations => <Object>[
    // This target draws a JasprComponentEmbedBuilder, which receives the child.
    (Component child) => div(<Component>[child], classes: 'ink-ripple'),
  ];
}
```

An implementation is either a `Component`, rendered as it is, or a
`JasprComponentEmbedBuilder` (`Component Function(Component child)`), which receives the
rendered child — that is what an effect that wraps content needs, and the class it
adds is where the CSS lives. `JasprComponentNode` is the convenience for a single
component payload with no child; a node carrying an implementation this target
cannot draw, or two of them, is reported by `renderJaspr` instead of being skipped.

## Stateful nodes

A `StatefulNode` is a **component wherever it sits in a tree**, so it has the same two
lives as a page: a server reads the state its store starts with, a browser subscribes
to that store. `JasprStatefulNode` is the component — `JasprStateful` with the node
handed in instead of built — and the renderer uses it for every stateful node it
meets, so a ripple in the middle of a page reacts exactly like the page around it.

On the server it creates the store, reads its state, draws `view(state, store)` and
releases the store. What it deliberately does not do: call `onMount`. A server render
must not start the work a page starts when it appears — the request, the timer — so a
node whose first state is *loading* produces a page that says it is loading. The
useful static shape is one whose store starts with data the server already has, or
one whose first state is the meaningful one.

In a browser the store is created once, subscribed, `onMount` is called at mount and
`onUnmount` and `dispose` at the end, and a notification redraws that node — and only
that node keeps its state; the page around it is not rebuilt.

`JasprStateful` is the page-level spelling of the same thing: a host subclasses it and
returns its node from `createNode`, which is what a page whose state is the whole
document wants (the example's `ExampleApp` is one). A node that already exists goes
through `JasprStatefulNode` and needs nothing from the host.

Neither needs `jaspr_builder` or a `@client` marker in this repository's setup: the
page is rendered by one hand-written entrypoint (`web/main.client.dart`, compiled by
`dart compile js` in `tool/site.sh`), which builds the same root the export did. A
node is a group of closures and is handed to the renderer in the same process, so
nothing has to be serialised across the wire.

## Overlays

An `OverlayNode` is drawn as a **fixed layer** over the page: the barrier in the
node's colour, the content aligned where the node asks, and `role="dialog"` with
`aria-modal="true"` on the layer. It is never drawn in the flow of its parent —
on the web an overlay is a layer or nothing.

What a server cannot do is interact: `Escape`, a press on the barrier and moving
focus need the client runtime (Task 104), so a static export shows the layer and
leaves it there. The layer is drawn exactly where the client will draw it, which is
what hydration needs.

In a browser the barrier carries the press and the `Escape` key is heard on the
**document** while the overlay is up, because nothing inside a freshly opened
overlay holds focus and a listener on the layer only sees a keystroke that starts
inside it. Two overlays open at once therefore both hear it; a stack with a
single top-most dismissal needs focus containment, which is still open.

## Testing

```sh
dart test
```

Component tests use `jaspr_test`; `test/support/harness.dart` exposes
`pumpNode`, `elementOf`, `stylesOf`, `classesOf`, `attributesOf` and `cssOf`
helpers to assert on the rendered DOM.

`test/conformance_test.dart` runs the renderer against
[`unibox_testing`](../unibox_testing) — the table of boxes both renderers
are checked against — through `test/support/appearance.dart`, which reads the
presentation of a box back out of the CSS this renderer emitted. The same table
is what the Flutter suite answers, which is how the two outputs are held to one
contract instead of to two opinions.
