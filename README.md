# Unibox

**Flutter UI. Searchable HTML.** Unibox makes a Flutter Web page indexable without a second
UI: build the screen once in Dart, draw it as Flutter widgets, and serve the same tree as
real HTML and CSS — the page a search engine reads.

A search engine, a link preview and a reader whose JavaScript failed all see the same
thing in a Flutter screen: nothing. Flutter draws into a canvas, so there is no text to
index and no link to follow. The usual fix is to write that page again in HTML, and then
to keep two designs in step — which, a week later, they are not.

Unibox removes the second design. A screen is one immutable Dart tree:
[`unibox_flutter`](packages/unibox_flutter) draws it as widgets,
[`unibox_html`](packages/unibox_html) renders it as a document a crawler reads, and one table of
expected appearance holds both renderers to the same answer.

<p align="center">
  <img src="docs/showcase.jpg" alt="The same apartment listings screen drawn twice, side by side: on the left the page built as HTML and CSS, on the right the same node tree built by Flutter. Both show the same search bar, the same filters, the same cards and the same prices." width="960">
</p>

<p align="center">
  <sub>One tree, drawn twice: <code>/web/listings/</code> on the left, <code>/flutter/listings/</code> on the right.</sub>
</p>

It is live at **[cedvdb.github.io/unibox](https://cedvdb.github.io/unibox/)** — the site is
built with the library it documents, so every band of it is a node tree, and the page you
read is the demo.

## Features

- 🔍 **Flutter SEO without a second UI** — a crawler, a link preview and a reader without JavaScript get the page itself: real text, headings, links, `alt`, landmarks and metadata, generated from the same Dart tree the app draws as widgets.
- 🧩 **One tree, two renderings** — the same nodes are Flutter widgets in the app and HTML with CSS in the browser, so the design is written once.
- 🖐 **Take the page over, and keep the reader's place** — Flutter boots into the document it was served, prefetched while they read and started at their first intent, and the scroll of every keyed region and the presses they made come back with it.
- ⚡ **Or let the page run on its own** — the same tree compiled to JavaScript renders into the page with `unibox_dom` and reacts through its store, so a page that should stay light needs no Flutter binary at all.
- 🟩 **Rendered from Node too** — pure Dart with no dependencies, so a document is produced in a server, a build step, a CLI, or compiled to JavaScript for a backend that is not Dart.
- 🧪 **Parity tested, not promised** — `unibox_testing` holds the renderers to one table of expected appearance, read back out of each one's own output.
- 🧱 **Material 3 as values** — the type scale, the colour roles and the components as an optional package, drawn by the renderers rather than by a third runtime.

## Contents

- [How it works](#how-it-works)
- [Flutter SEO: make Flutter Web pages indexable](#flutter-seo-make-flutter-web-pages-indexable)
- [Serving a tree](#serving-a-tree)
- [Quick start](#quick-start)
- [Flutter hydrates it](#flutter-hydrates-it--the-least-to-change)
- [The DOM hydrates itself](#the-dom-hydrates-itself--nothing-of-flutter)
- [In several languages](#in-several-languages--one-document-per-language)
- [The nodes](#the-nodes)
- [Material](#material)
- [Colours](#colours)
- [Typography](#typography)
- [Motion](#motion)
- [Semantics](#semantics)
- [What the host owns](#what-the-host-owns)
- [How the two renderers stay in step](#how-the-two-renderers-stay-in-step)
- [Packages](#packages)
- [Building with an AI assistant](#building-with-an-ai-assistant)
- [Development](#development)

## How it works

A screen is a `Box` with children. Each child is another node — a text, an image, a link, a grid,
a stack — and every node is an immutable Dart object. Nothing in the description mentions Flutter
or HTML: no widget, no tag, no stylesheet.

```dart
final page = Box(
  padding: BoxSpacing.all(16),
  gap: 12,
  children: <UINode>[
    TextNode('Apartments', fontSize: 24, fontWeight: FontWeight.bold),
    GridNode(minItemWidth: 380, children: listings),
  ],
);

runApp(MaterialApp(home: page.toWidget(theme: MaterialPalette.lightTheme)));
final html = toDocument(
  page,
  head: const DocumentHead(title: 'Apartments'),
  theme: MaterialPalette.lightTheme,
);
```

`toWidget(theme: …)` builds the widgets; `toDocument()` writes the page and its head. Which one
you call is the only decision, and both take the same `UniboxTheme`: a tree that names colour roles
has no colours without it (see [roles and theming](#roles-and-theming)), and a tree of literal
colours ignores it.

The two stay equal because the model states every default — an unset direction is a column, an
unset text size is 16 — so neither target answers with its own, and because a test compares what
each renderer produced. Neither wraps the other: on a phone the tree is Flutter widgets, in a
browser markup and CSS, with no WebView between them.

How wide the window is, what a tap does and what the document is called cannot come from the
tree: only the application knows them. See [what the host owns](#what-the-host-owns).

## Flutter SEO: make Flutter Web pages indexable

Flutter Web paints into a canvas. A search engine is served an empty page — no text to index,
no heading to rank, no link to follow — and a page a crawler cannot read is a page nobody
arrives on. The usual answer is to write that page a second time in HTML, and to keep the two
designs in step until they no longer are.

Unibox answers it with the page that is already there. The tree is the description;
`toDocument` writes it as a document:

```dart
final UINode page = Box(
  gap: 8,
  children: <UINode>[
    TextNode('Apartments in Amsterdam', headingLevel: 1),
    TextNode('Forty-one flats, from a studio to a family home.'),
    LinkNode('apartments/amsterdam', children: <UINode>[TextNode('See all')]),
  ],
);

final String document = toDocument(
  page,
  head: const DocumentHead(
    title: 'Apartments in Amsterdam',
    description: 'Forty-one flats to rent in Amsterdam.',
  ),
  takeover: const Takeover(boot: 'app.js'),
);
```

`toDocument` writes the head and the body, and nothing in the output needs a runtime to be
read. With the class hashes elided and the whitespace added by hand, this is the body it
writes:

```html
<body>
  <div class="unibox-box-…" data-unibox-node="box">
    <h1 class="unibox-text-…" data-unibox-node="text">Apartments in Amsterdam</h1>
    <span class="unibox-text-…" data-unibox-node="text">Forty-one flats, from a studio to a family home.</span>
    <a class="unibox-link-…" href="apartments/amsterdam" data-unibox-node="link">
      <span class="unibox-text-…" data-unibox-node="text">See all</span>
    </a>
  </div>
</body>
```

A real `h1`, real sentences and an `href` a crawler follows — and a title, a description and
the `og:` pair in the head, so a link preview reads the page too. That is what an indexable
Flutter page has to mean in practice: the document the crawler is given is the document the
reader lands on.

**The application is not replaced.** `takeover` names the Flutter build the document belongs
to: it is prefetched while the reader reads, started at their first intent, and boots into
the page it was served — the scroll of every keyed region and the presses already made come
back with it. From then on Flutter draws everything: the dialogs, the forms and the screens
behind the list, exactly as the application already writes them. See
[Serving a tree](#serving-a-tree).

**Adopt it one page at a time.** None of this asks for an application to be rewritten. The
pages that have to be found — the listing, the product, the article, a landing page — become
trees; the dashboard behind a login stays the Flutter it already is, because no crawler is
going to sign in. That is the difference between a migration and a page, and it is why this
can start with one screen.

**What it does not do.** Rendering is not the whole of search. Unibox does not choose a url,
write the copy, decide where a page is served from, produce `robots.txt`, or deploy the result —
the application still owns all of that, which is where it belongs. What it does with those
decisions once they are made is state them: a `canonical` address, a title and a description in
the head a crawler reads, and the markup a link preview shows. What Unibox removes is the canvas
between a crawler and the page, and the second UI that used to sit beside it.

## Serving a tree

Unibox renders the tree as a page first — real text, real links, real headings — so what a search
engine reads is the page a visitor lands on. What brings that page to life is the application's
decision.

| | **Flutter hydrates it** | **The DOM hydrates itself** |
| --- | --- | --- |
| The page becomes | the app, repainted into a canvas | the same elements, made live |
| What you write in Unibox | the screen a visitor lands on | every screen that must work without Flutter |
| What you ship | the Flutter build you already have | a folder of files — any static host serves it |
| What it costs | one repaint when the app arrives | every interaction is a node |

### Flutter hydrates it — the least to change

Reach for this when the application already exists. You describe **one screen**, the one that has to
be findable, and stop: Flutter boots into the page it was served and draws everything after it —
the dialogs, the forms, the list behind the list — as ordinary Flutter, exactly as you write it
today.

```dart
final String page = toDocument(
  ListingsPage(listings),
  head: const DocumentHead(title: 'Apartments in Amsterdam'),
  takeover: const Takeover(boot: '../../flutter/app.js'),
);
```

The visitor does not start again in the swap. The page records where they scrolled and what they
pressed; the app opens at that scroll and replays the press.

```dart
void main() => runApp(
  ExampleApp(
    offsets: scrollOffsetsFromPage(),
    presses: pressesFromPage(),
  ),
);
```

The app downloads while they read and starts at their first intent, so the page is finished before
the engine is asked for. The handover is one repaint, and a brief flash comes with it.

### The DOM hydrates itself — nothing of Flutter

Same tree, written by `unibox_html` and made live by `unibox_dom`: one small bundle, compiled from
Dart, that **adopts** the markup the server wrote — the same elements, the same classes — and keeps
it in step with the stores the tree created. A press runs the same Dart closure Flutter would run,
with no engine and no repaint.

This site's whole client — renderer, stores and trees — is 67 KB gzipped. Its Flutter build is
718 KB before Canvaskit.

The price is that an interaction has to exist as a node: a dialog is a node in the tree, not a
widget only the app can draw. A filter and a reorder are nodes too. What Flutter alone can draw
stays in the app, and the screens that do not have to be found stay ordinary Flutter.

### In several languages — one document per language

A localised site is the same builder called with the copy of each language, each written to its own
address, each document naming the whole set:

```dart
for (final SiteEdition edition in SiteEdition.all) {
  final String page = toDocument(
    buildListingsPage(edition.copy),
    lang: edition.tag,
    head: DocumentHead(
      title: edition.copy.title,
      canonical: edition.url('apartments'),
      alternates: SiteEdition.alternates('apartments'),
    ),
  );
  File('site/${edition.tag}/apartments/index.html').writeAsStringSync(page);
}
```

`lang` says which language the page is written in — an attribute of the root element, not a
head element, which is why it sits beside the head rather than in it. The head's `alternates`
says which other addresses carry the same page, so a search engine pairs the translations
instead of keeping one and hiding the rest. The
locale comes from the address rather than a cookie or `Accept-Language`, because a crawler sends
neither, and a language switch is a [link](docs/nodes/link.md) to the other address — followable by a reader
and by a crawler. Copy stays a value passed into the tree (`SiteCopy.de`), so a string a language is
missing is a compile error; an `.arb` catalogue, plurals and date formats live in the application's
own package, which the tree never sees.

## Quick start

The packages are not on pub.dev yet (`publish_to: none` keeps them off until a
release is cut), so point your pubspec at the checkout:

```yaml
dependencies:
  unibox_core:
    path: ../unibox/packages/unibox_core
  unibox_flutter:
    path: ../unibox/packages/unibox_flutter
  unibox_html:               # the web: a document a crawler can read
    path: ../unibox/packages/unibox_html
  unibox_material:           # optional: the Material 3 type scale
    path: ../unibox/packages/unibox_material
```

```dart
// Flutter
runApp(MaterialApp(home: tree.toWidget(theme: MaterialPalette.lightTheme)));

// the web: a page a crawler reads, and a reader acts on
final String page = toDocument(
  tree,
  head: const DocumentHead(title: 'My page'),
  theme: MaterialPalette.lightTheme,
);
```

Keep the tree in a package of its own that imports `unibox_core` and neither
renderer, so both hosts can use it and neither has to know which target draws it.
[`example/`](example/README.md) is that arrangement in full: one page node — a
listings page, a navigation bar and a sign-up dialog — shared by a Flutter app and
a static site, each host a single small file.

## The nodes

There are eleven node types. Each one is an immutable Dart object with a `const`
constructor, and each one describes *what* it is rather than which framework draws
it. Style values — colours, spacing, borders, typography — are separate objects
that a node takes as parameters, so a look can be reused as one `const BoxStyle`
instead of being repeated.

A layout the two targets do not draw with the container a box is becomes a node, not a
token on `Box`: a grid is `display: grid` with its own tracks, so it is `GridNode`, where
`Box.wrap` is a token because `flex-wrap` is the same container with another property.

Every node accepts a `key`. Renderers hand it to the target's own key mechanism, so
when a list is reordered each child keeps its state: typed text stays in the field
it was typed into.

The nodes are documented one page at a time — the parameters, the defaults the model
gives each one, and what each target does with it. That is ten pages for the eleven
nodes, because `PositionedNode` is documented beside the `StackNode` it places in. The
reference is [`docs/nodes`](docs/nodes/README.md).

| Node | What it is | Reference |
| --- | --- | --- |
| `Box` | The container: children in a row or a column, the space between them, the paint and the press. | [Box](docs/nodes/box.md) |
| `TextNode` | A run of text, and the heading level it may be. | [TextNode](docs/nodes/text.md) |
| `ImageNode` | A picture from a URL or from the assets the host ships. | [ImageNode](docs/nodes/image.md) |
| `LinkNode` | A `Box` that names a destination: the link a press follows. | [LinkNode](docs/nodes/link.md) |
| `StackNode`, `PositionedNode` | Layers painted on top of each other, and one child placed at an offset. | [StackNode](docs/nodes/stack.md) |
| `TextInputNode` | A single line field, a password field, or a text area. | [TextInputNode](docs/nodes/text-input.md) |
| `StatefulNode` | A subtree that owns a store and draws the tree of its state. | [StatefulNode](docs/nodes/stateful.md) |
| `GridNode` | Equal columns whose count follows the width of the box, or a row of stated factors. | [GridNode](docs/nodes/grid.md) |
| `OverlayNode` | Content drawn above the page: a dialog, a sheet, a menu. | [OverlayNode](docs/nodes/overlay.md) |
| `EmbedNode` | The escape hatch, for what the eleven nodes cannot describe. | [EmbedNode](docs/nodes/embed.md) |

The values a node takes are documented once, for both targets: [colours](#colours),
[roles and theming](#roles-and-theming), [typography](#typography), [motion](#motion)
and [semantics](#semantics).

## Material

`unibox_material` is an optional package of values and components for Material 3. A look
is a value — the fifteen roles of the type scale as `const BoxTextStyle` values, the
colour roles as a `MaterialPalette` — and a component is a node built from the ones
above, never a new node type. It is pure Dart, adds no renderer code, and neither target
knows it exists: a tree that uses it is drawn by the same two renderers as one that does
not.

| Component | What it is | Reference |
| --- | --- | --- |
| `MaterialTypography`, `MaterialTypeRole` | the fifteen type roles of Material 3, as `const BoxTextStyle` values | [The scale](packages/unibox_material/README.md#the-scale) |
| `MaterialPalette`, `MaterialColorRole` | the colour roles as a palette: the baseline `light` and `dark`, or one grown from a seed with `fromSeed` | [The palette and the theme](packages/unibox_material/README.md#the-palette-and-the-theme) |
| `MaterialScaffold` | a screen: an app bar that stays, and a body under it | [The scaffold](packages/unibox_material/README.md#the-scaffold) |
| `MaterialAppBar`, `MaterialLargeAppBar` | the top app bar, and the one with air above its headline that folds as it leaves | [The app bars](packages/unibox_material/README.md#the-app-bars) |
| `MaterialCard` | Material's elevated surface, padded and rounded | [The card](packages/unibox_material/README.md#the-card) |
| `MaterialListTile` | one row of a list: a leading node, a title, a subtitle and a trailing node | [The list tile](packages/unibox_material/README.md#the-list-tile) |
| `MaterialButton` | a label on a fill, in four shapes: `filled`, `tonal`, `outlined` and `text` | [The button](packages/unibox_material/README.md#the-button) |
| `MaterialIconButton` | one glyph in a square, with a count over its corner | [The icon button](packages/unibox_material/README.md#the-icon-button) |
| `MaterialInkWell` | the press itself: the tints, and the ink a press spreads | [The ink well](packages/unibox_material/README.md#the-ink-well) |
| `MaterialTabBar`, `MaterialTabs` | one row of tabs with an indicator, and that bar above the page of the chosen tab | [The tabs and the segmented button](packages/unibox_material/README.md#the-tabs-and-the-segmented-button) |
| `MaterialSegmentedButton` | two to five choices in one divided pill | [The tabs and the segmented button](packages/unibox_material/README.md#the-tabs-and-the-segmented-button) |
| `MaterialTextField` | a field that owns its text, its focus and whether it has been touched | [The text field](packages/unibox_material/README.md#the-text-field) |
| `MaterialChip` | a compact choice: a pill with a label, and a node on either side | [The chip](packages/unibox_material/README.md#the-chip) |
| `MaterialNavigationBar` | three to five destinations along the bottom edge, one of them current | [The navigation bar](packages/unibox_material/README.md#the-navigation-bar) |
| `MaterialDialog`, `MaterialBottomSheet` | the two surfaces an `OverlayNode` presents | [The dialog and the bottom sheet](packages/unibox_material/README.md#the-dialog-and-the-bottom-sheet) |
| `MaterialIcon` | one glyph of an icon font, centred in a 24 pixel square | [The icon](packages/unibox_material/README.md#the-icon) |
| `MaterialCheckMark` | Material's tick, drawn from boxes, for an application that ships no icon font | [The one glyph this package draws](packages/unibox_material/README.md#the-one-glyph-this-package-draws) |
| `MaterialProgressRing`, `MaterialSpinner` | a value as a ring of a shape, and the step that ring turns | [The circular progress indicator](packages/unibox_material/README.md#the-circular-progress-indicator) |
| `MaterialElevation` | Material's six heights as lists of `BoxShadow` | [Elevation](packages/unibox_material/README.md#elevation) |

The package README documents each component in full: the tokens it states, the ones it
leaves to the platform, and the parts that stay approximate. Everything in it is a value
or a node, so a dark theme restyles a whole screen without a parameter.

## Colours

A colour is a `BoxColor`: a 32-bit ARGB value, which both renderers paint the same
way. A tree either states one or names one from the palette:

```dart
BoxColor.rgb(0x2D, 0x6C, 0xF3)         // #2D6CF3, opaque
BoxColor.rgba(0x2D, 0x6C, 0xF3, 0x80)  // the same colour at half alpha
BoxColor(0xFF2D6CF3)                   // a raw 0xAARRGGBB value
BoxColors.blue.withOpacity(0.5)        // a palette name, faded
```

`BoxColors` holds the names an interface reaches for before it has a palette of its
own, and each carries the value Flutter's `Colors` gives the same name — so a tree
that names `BoxColors.grey` matches the `Colors.grey` of the widgets around it, and
the web renderer writes the same hex.

| Neutral | | Hue | |
| --- | --- | --- | --- |
| `white` | `#FFFFFF` | `red` | `#F44336` |
| `lightGrey` | `#E0E0E0` | `orange` | `#FF9800` |
| `grey` | `#9E9E9E` | `yellow` | `#FFEB3B` |
| `darkGrey` | `#616161` | `green` | `#4CAF50` |
| `blueGrey` | `#607D8B` | `teal` | `#009688` |
| `black` | `#000000` | `blue` | `#2196F3` |
| `transparent` | `#00000000` | `indigo` | `#3F51B5` |
| | | `purple` | `#9C27B0` |
| | | `pink` | `#E91E63` |
| | | `brown` | `#795548` |

`BoxColor` keeps `white`, `black` and `transparent` next to its constructors; the
other names live on `BoxColors`, because `red`, `green` and `blue` are the channel
getters of a `BoxColor` and a preset cannot take those names.

They are conveniences, not a design system. A screen with a palette of its own
states it in Dart and passes it around, the way
[`ExamplePalette`](example/unibox_example_shared/lib/src/theme.dart) does — grown
there from one seed with `MaterialPalette.fromSeed` — so the
same colours are used by both hosts. Typography carries colour as well: `color` on
a text, or `color` in a `BoxTextStyle` that a box passes down.

## Roles and theming

A colour can name a role the application owns instead of a value baked into the tree:

```dart
enum AppColor { primary, surface }

const theme = UniboxTheme(
  colors: <AppColor, BoxColor>{
    AppColor.primary: BoxColor(0xFF2D6CF3),
    AppColor.surface: BoxColor.white,
  },
);

const Box(backgroundColor: BoxColor.role(AppColor.primary));

renderFlutter(page, theme: theme);   // resolves each role while building
page.toWidget(theme: theme);         // the same call, as the extension
toDocument(page, theme: theme);      // writes :root and points the rules at it
page.toHtml(theme: theme);           // the fragment, as the extension
```

| | What it buys |
| --- | --- |
| the role is an enum member | a typo is a compile error, and the theme is keyed by the same value — no string is written by hand |
| one theme value | the tree, the host's CSS (`var(--unibox-color-primary)`) and the app's `ColorScheme` all read the same palette |
| the web writes `var()` | a host stylesheet or a `prefers-color-scheme: dark` block outranks the tree without touching it |
| literals still work | a page that needs no theme never needs one, and a role with no theme is reported by name |
| `colorScheme` | the theme says whether it is a light or a dark one, and a document states it as `color-scheme` — so the browser paints its scrollbars and its caret to match the page rather than the reader's system |

`validateTree(root, theme: theme)` reports a role the theme does not define, so a
missing colour is a message with a name in it rather than a blank box.

**Light unless stated.** `UniboxTheme.colorScheme` defaults to `light`, and
`MaterialPalette.theme` fills it in from the palette's own surface, so
`MaterialPalette.dark` writes `color-scheme: dark` without anyone saying it twice.
No renderer reads `prefers-color-scheme` or a platform's brightness on its own:
following the reader is a host's decision, made by installing the theme it chose.
A host that wants it writes one block, with every role rather than a handful:

```css
@media (prefers-color-scheme: dark) {
  :root { /* MaterialPalette.fromSeed(seed, isDark: true).theme */ }
}
```

and in Flutter, two lines where the theme is installed:

```dart
final bool dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
renderFlutter(page, theme: dark ? MaterialPalette.darkTheme : MaterialPalette.lightTheme);
```

## Typography

Typography is the one thing a box passes down to its children. It works like CSS
font properties and like Flutter's `DefaultTextStyle`: a box sets the font once, and
the texts inside only say what makes them different.

```dart
const Box(
  textStyle: BoxTextStyle(fontSize: 16, color: BoxColor.black, lineHeight: 1.5),
  children: <UINode>[
    TextNode('Inherits all three.'),
    TextNode('Bold only.', fontWeight: FontWeight.bold),
    TextNode('A caption.', style: BoxTextStyle(fontSize: 13)),
  ],
);
```

When two places set the same value, the more specific one wins:

| Order | Where the value comes from |
| --- | --- |
| 1 | the flat parameter of the node (`fontSize`, `padding`, ...) |
| 2 | the node's style object (`BoxStyle`, `BoxTextStyle`) |
| 3 | the typography of the closest box above it |
| 4 | the host's own default (Flutter's `DefaultTextStyle`, the page's CSS) |
| 5 | the default of the model |

The model has the last word, not the host: `BoxTextStyle.defaults` is 16 logical
pixels, normal weight, black, a line height of 1.5 and no letter spacing, and both
renderers install it at the root of the tree. That is why an unstyled text looks the
same in an app and on a page; Flutter would have used 14 pixels and a browser 16 of
`canvastext`.

The one value the model leaves to the host is the **font family**, because a font
file is an asset: unset means "the platform's UI font" on both targets, and an app
that wants its own ships the same file to both.

**A line through the text is typography, not a shape.** A price that is no longer
paid is struck through by a token, so the line follows the font size and the line
height instead of being a one pixel box positioned over the middle of a line:

```dart
Box(
  textStyle: BoxTextStyle(color: BoxColor.rgb(0x6B, 0x72, 0x80)),
  direction: Axis.horizontal,
  gap: 8,
  children: <UINode>[
    TextNode('€1 200', fontSize: 20, decoration: TextDecoration.lineThrough),
    TextNode('€940', fontSize: 20, color: BoxColor.black),
  ],
);
```

`decoration` is inherited like the rest of the typography, so a box can strike
through the texts it holds. A line is stated **once** — by the box or by the run,
never by both: a browser propagates the line of a box to every text inside it and
lets a descendant only add to it, where Flutter lets the inner style replace it, so
the overlap is one of the trees `validateTree` reports. The colour defaults to the
colour of the glyphs and the thickness to the one the font asks for (a thickness in
pixels is a web-only token: Flutter can only scale the thickness the font already
draws, so it draws the font's own).

A scale can be written by hand, as the example does, or taken ready made:
[`unibox_material`](packages/unibox_material/README.md) holds the Material 3 type
scale as `const BoxTextStyle` values (`MaterialTypography.titleLarge`,
`MaterialTypography.bodyMedium`, ...), the colour roles as a `MaterialPalette` value —
written down for the baseline scheme, or grown from one brand colour with
`MaterialPalette.fromSeed` — and fifteen components built from the same tokens: a card,
a list tile, a button, an icon button, a chip, a segmented button, an ink well, a text
field, an icon, Material's drawn tick, a navigation bar, a progress ring and its spinner,
a dialog and a bottom sheet. It is optional
and pure Dart, and the
renderers do not know it exists — a tree that uses it is drawn by the same two
renderers as one that does not.

## Motion

`BoxTransition` says how long a change of look takes and how it eases. A state style
names what changes; the resting style owns the duration, and the change is
interpolated instead of jumping:

```dart
Box(
  backgroundColor: BoxColor.white,
  transition: BoxTransition(duration: Duration(milliseconds: 150)),
  hoverStyle: BoxStyle(backgroundColor: BoxColor.rgb(0xF3, 0xF4, 0xF6)),
  children: <UINode>[TextNode('Hover me')],
)
```

It covers the paint — background, border colour, corner radius, shadows, opacity
and transform — and never the layout, and the curve is one of `linear`, `ease`,
`easeIn`, `easeOut` or `easeInOut`: the five curves CSS and Flutter define the same
way, so both targets ease identically. A state that *introduces* a scale or a fade
eases in from the resting look rather than appearing, which is what the CSS does
when the resting rule declares no transform. On the web all of it lives in the
CSS, so a static page animates with no JavaScript at all.

The whole look shares one timing unless a part says otherwise, which is how a
colour can settle before a scale starts:

```dart
transition: const BoxTransition(
  duration: Duration(milliseconds: 200),
  parts: <BoxTransitionPart>[
    // the paint first…
    BoxTransitionPart(
      properties: BoxProperty.paint,
      duration: Duration(milliseconds: 100),
    ),
    // …then the scale, once it has settled
    BoxTransitionPart(
      properties: <BoxProperty>{BoxProperty.transform},
      duration: Duration(milliseconds: 150),
      delay: Duration(milliseconds: 100),
    ),
  ],
),
```

The four paint properties share a timing, because a `BoxDecoration` interpolates as one
on Flutter; a box that needs two paint speeds nests a box, and `validateTree` says
so instead of the renderer approximating.

### A band that stays

Before the motion, the thing most pages need first: chrome that does not scroll
away. `pin` names the edge and `pinOffset` the room a bar above it takes.

```dart
Box(
  height: 480,
  overflow: Overflow.scroll,
  children: <UINode>[
    Box(height: 96, backgroundColor: BoxColor.role(MaterialColorRole.primaryContainer)),
    // Filters come to rest at the top of the box…
    Box(key: 'filters', height: 44, pin: BoxPin.start, backgroundColor: …),
    // …and the chip row stops underneath them: the inset is the height above it.
    Box(key: 'chips', height: 44, pin: BoxPin.start, pinOffset: 44, backgroundColor: …),
    for (final UINode row in rows) row,
  ],
)
```

A band at the other end is the same token with `BoxPin.end`: a “Continue” bar that
waits at the bottom of a long form until the reader reaches the end of it. Both
bands state a height — that number is the room the flow keeps for them — and both
paint a background, because each is drawn over the content that passes beneath it.

The box states a surface too, and it is the surface a pull past either end reveals: a host
lets a scroller be pulled, and the gap that opens is the box's own `backgroundColor`. State
the bar's colour there and the pull reads as the bar gaining room; leave it out and the pull
shows whatever is behind the box. `unibox_material` makes that one statement instead of two:
`MaterialAppBar.surface` is the colour the bar paints *and* the colour a list under it
states.

### A look that arrives as the reader scrolls

`BoxFold` is the second kind of motion, and the only one the *reader* drives: a box
paints the look it names the further it has travelled out of the viewport that scrolls
it. It is what a hero does as a toolbar comes up under it.

```dart
Box(
  height: 132,
  padding: const BoxSpacing.all(20),
  backgroundColor: BoxColor.role(MaterialColorRole.primaryContainer),
  fold: const BoxFold(
    // The look at the end of the travel: the hero fades and shrinks a little.
    to: BoxStyle(opacity: 0, transform: BoxTransform(scale: 0.75)),
    // …and it is gone by the time three quarters of it has left.
    over: 0.75,
    curve: BoxCurve.easeOut,
  ),
  children: <UINode>[TextNode('Six flats, one tree', headingLevel: 1)],
)
```

The travel is the box's own exit — its leading edge at the top of the viewport to its
trailing edge leaving it — so no number of pixels is stated, and a hero of 200 folds
over 200 without being edited. `over` is the only number there is: it is how much of
that exit the fold takes, which is how `1 - t * 1.5` is written down.

It is paint only, for the reason above: the background, the border colour, the corner
radius, the shadows, the opacity and the transform. Nothing below the box moves, and
nothing is laid out again while it runs — on the web the browser interpolates two
keyframes it was served, and in Flutter the layer repaints. A tree that names a layout
token in `fold.to`, folds a box that also pins, or eases one look with both a transition
and a fold is reported by `validateTree`.

A second fold, of a different paint and a shorter range — a title band that loses its tint
once half of it has left, which is `over: 0.5`:

```dart
Box(
  height: 120,
  padding: const BoxSpacing.all(20),
  backgroundColor: BoxColor.role(MaterialColorRole.secondaryContainer),
  borderRadius: 12,
  fold: BoxFold(
    to: BoxStyle(
      backgroundColor: BoxColor.role(MaterialColorRole.surface),
      borderRadius: 0,
    ),
    over: 0.5,
  ),
  children: <UINode>[TextNode('Two rooms by the park')],
)
```

A browser without scroll-driven animations ignores the animation and paints the resting
look, which is exactly what the tree shows before anything moves; a Flutter tree with no
scrollable above the box keeps its resting look for the same reason.

## Semantics

A node can say what it *is*, in the same tree: a role for a hand-drawn control, an
element for a box, a heading level for a text. None of it changes a pixel.

```dart
Box(
  onTap: toggle,
  semantics: BoxSemantics(
    role: BoxRole.checkbox,
    label: 'Release notes',
    checked: state.newsletter,
  ),
  children: <UINode>[TextNode('Release notes')],
)

Box(
  semantics: BoxSemantics(element: BoxElement.main),
  children: <UINode>[TextNode('Apartments', headingLevel: 1)],
)
```

| Part of `BoxSemantics` | What it becomes |
| --- | --- |
| `role` | `button`, `checkbox`, `switch`, `link` or `heading`: a `role` on the web, the matching flag in Flutter, and a keyboard entry point for the roles a user can act on. |
| `element` | `div`, `main`, `nav`, `header`, `footer`, `aside`, `section`, `article`, `form`, `figure`, `figcaption`, `ul`, `ol`, `li`: the element a box renders as on the web. |
| `label` | The name announced instead of the contents. |
| `checked`, `expanded`, `selected` | `aria-checked`, `aria-expanded`, `aria-selected`, and the same state in Flutter. |
| `pressed` | `aria-pressed` on a toggle button — a chip, a segment — and Flutter's `toggled`. It is not `selected`: a browser only honours `aria-selected` on an option, a tab, a row or a grid cell, so a button that carried it announced nothing. |
| `hidden` | `aria-hidden`: the box keeps its look but leaves the accessibility tree and the tab order. |
| `liveRegion` | `aria-live`: a change inside is announced, which is how a form reports a result without moving the focus. |
| `current` | `aria-current` (`page`, `step`, `location`): the item of a navigation the reader is on. Flutter has no counterpart, so it announces the box as the selected item of a set. |

`TextNode.headingLevel` is the heading spelling for text: `<h1>`–`<h6>` on the web,
the same level announced in Flutter. Landmarks (`main`, `nav`, ...) exist only on the
web; Flutter's accessibility tree has no landmarks, so there they stay ordinary
containers.

A control is **one node** for a reader: its role, its name and its action together, on
both targets — the button flag does not sit on a parent while the tap action sits on a
child, which is a shape a reader cannot use. A long press is the one action the two
trees do not share: Flutter offers it (`Semantics.onLongPress`, as a native `InkWell`
does) and a browser has no equivalent, so on the web a hold is a pointer gesture.

## What the host owns

The tree is a description, not a program: everything that changes over time belongs
to the host that draws it.

| The host decides | Why the tree cannot |
| --- | --- |
| **State**: the values of a form, which page is open, what a tap does | Nodes are immutable and hold no values. A callback is a `void Function()` the host implements, and the host re-renders with new nodes. |
| **The surface**: window size, safe areas, scroll position | A description does not know how large the window is. A responsive page takes the answer as a parameter, and each host produces it its own way. |
| **Where the scroll is**, but not what stays in it | A pin is a relation to the nearest box that scrolls, not an offset in the window: the band says *stay at this edge of whatever scrolls me*, and the reader's scroll position stays the host's. That is the line between `pin` and `onScroll` — one says what the tree looks like while it moves, the other reports where it got to. |
| **The document**: title, language, description, canonical url, structured data | Those describe a page, not a region of one. The Flutter host gives them to its `MaterialApp`, the web host to `toDocument`. |
| **The language**: which copy the page is written in, and the addresses of its translations | Copy is a string, so it is built into the tree as a value like a colour; the locale is the host's, because a crawler can only read it from the address. A tree that read `Localizations` could not be rendered as a document at all. |
| **The fonts** | A font file is an asset of the application, and it has to be the same file on both sides. |
| **Effects with no common description** | That is what [`EmbedNode`](docs/nodes/embed.md) is for. |

The one thing a host does not choose is the name on each element: the web renderer
always writes `data-unibox-node="…"` on the elements a node drew, because a name
carries no look and an inspector without it reads a page of hashes. The name is a
literal a node states (`box`, `text`, `material-card`), never its type — a compiled
build mangles class names, so a derived one reads `minified:-s`. Flutter has no DOM,
so there the name is not written at all.

The example shows the first two in practice: a `StatefulWidget` and a
`StatefulComponent` hold the same form state and pass it into the same tree.

## How the two renderers stay in step

Three mechanisms, all of them tested:

1. **Defaults belong to the model.** A box without a direction is a column, an
   undeclared text uses `BoxTextStyle.defaults`, an image without a fit scales down.
   Neither renderer may answer with its platform's default, because that is how the
   same tree starts looking like two different products.
2. **One table of expected results.** `unibox_testing` lists boxes and texts with
   the appearance each one must have. The Flutter suite reads that appearance back out
   of the widget tree it built, the HTML suite out of the CSS it emitted, and both
   compare it with the same entry — so a value one renderer stops drawing fails its
   own test.
3. **Trees no renderer can draw are reported.** `validateTree` catches a positioned
   node outside a stack, a link inside a link, a scrolling box that also distributes
   its children, a list item outside a list, an embed with nothing to draw, and a
   transition that changes nothing.

What is *not* promised is the pixels: glyph shapes, hinting and line breaking belong
to the text engine, and a browser is not Skia. What is promised is the layout, the
sizes, the spacing, the typography and a line box of exactly `fontSize * lineHeight`
on both sides.

A **weight is only as real as the family's faces**. Both renderers ask for the same
`font-weight`, but if the family has no face at that weight a browser synthesises one and
Skia snaps to the nearest it has — from a different family, if the two hosts were never
given the same files. `semiBold` is the one that shows it first. Ship the same font to
both, as the example does, and the weights agree.

Where the values go is shared on purpose. The web renderer writes every distinct look once,
as a class rule in a single `<style>`, and puts the class on the element — so six rows that
look alike cost one declaration, and a host can outrank any of it with its own stylesheet or
a custom property. Nothing in a tree is written inline.

## Packages

| Package | What it is |
| --- | --- |
| `packages/unibox_core` | The nodes, the style values and the validation. No dependencies outside the Dart SDK. |
| `packages/unibox_flutter` | The Flutter renderer: `renderFlutter(node)` and `node.toWidget()`. |
| `packages/unibox_css` | The token-to-CSS mapping and the class hash the web renders from. |
| `packages/unibox_element` | The element plan: what each node becomes. |
| `packages/unibox_html` | The web renderer: `toHtml(node)` (or `node.toHtml()`) and `toDocument(node)`. |
| `packages/unibox_dom` | The client renderer: `DomView.adopt(tree, root)` keeps the markup a server wrote and patches it as the stores publish. |
| `packages/unibox_testing` | The tables both renderers are tested against. Development only, not published. |
| `packages/unibox_material` | The Material 3 type scale, the colour roles as a theme — the baseline scheme written down, or a palette grown from one seed colour — and the components built from them (card, list tile, button, chip, segmented button, ink well, text field, icon, check mark, navigation bar, dialog, bottom sheet). Optional: no renderer depends on it. |
| `example/` | The example — a listings page and a sign-up dialog, one node tree — and the site: one page, the example drawn by both renderers beside the claim it makes. |

Dependencies point one way: both renderers depend on `unibox_core`, never the other
way around, which is what keeps the description available to a third renderer.
`unibox_material` depends on `unibox_core` and on Material's own colour algorithm — a pure
Dart package, with no widget layer — and sits beside the renderers rather than under them:
a tree imports it for its type, its palette and its components, and the renderers never see
it, so a tree that uses it is drawn by the same two renderers as one that does not.

**Imports.** `unibox_core` declares `Axis`, `BoxBorder`, `BoxShadow`, `TextOverflow`,
`TextAlign` and `FontWeight`, which Flutter also declares. Next to
`package:flutter/material.dart` the first four are a compile error and the last two
shadow Flutter's silently. So import the tree with a prefix (`as core`) in a file
that also imports Flutter, or keep the tree in a package that imports no renderer —
the arrangement the example uses, and the one to copy. Node names carry a `Node`
suffix (`TextNode`, `ImageNode`, `StackNode`) for the same reason: `Text`, `Image`
and `Stack` are Flutter widgets.

## Building with an AI assistant

Unibox is not on pub.dev yet, so no model has been trained on it: an assistant asked
for "a Unibox card" will write Flutter widgets and call them Unibox. Two files fix
that. [`AI_INSTRUCTIONS.md`](AI_INSTRUCTIONS.md) is the short one — the model's rules,
a translation table from the Flutter and CSS idioms an assistant already knows, and a
complete component — and it is written to be pasted into the context:

```text
Read AI_INSTRUCTIONS.md and README.md from the Unibox repository before writing any
code. Build <the component> as a Unibox node tree in a file that imports only
package:unibox_core, plus package:unibox_material when it uses the Material roles.
Do not use Flutter or HTML widgets. Return the tree, and separately the small
host that renders it.
```

This page is the second file: the parameter tables an assistant needs when the
instruction file is not enough. The two are the ground truth, together with
`packages/unibox_core/lib/src/`: a parameter that is in none of them does not exist.

## Development

This repository is a [Dart workspace](https://dart.dev/tools/pub/workspaces): every
package shares one resolution, so the commands run from the root.

```shell
flutter pub get                                  # resolve the workspace
dart analyze                                     # static analysis everywhere

(cd packages/unibox_core && dart test)
(cd packages/unibox_testing && dart test)
(cd packages/unibox_material && dart test)
(cd packages/unibox_css && dart test)
(cd packages/unibox_element && dart test)
(cd packages/unibox_html && dart test)
(cd packages/unibox_dom && dart test -p chrome)
(cd packages/unibox_flutter && flutter test)
(cd example/unibox_example_shared && dart test)
(cd example/unibox_example_html && dart test)
(cd example/unibox_example_flutter && flutter test)
```

`python3 tool/seo_report.py build/site` counts what a search engine reads in the site's
documents — words, headings, links, fields and bytes — so the claim can be re-run rather than
taken on trust.

`tool/verify.sh` runs the format check, the analysis and every suite in that
order, which is the command to reach for before a commit; `--fast` stops after the
analysis, `--fix` formats the tree first and `--docs` adds the API docs of every
package. `tool/maintenance.sh` is the slower, monthly pass: the same gate with the docs,
the performance budget, the site build and the numbers this page quotes.

`tool/site.sh` builds the site: one page at `/` — the claim, the example drawn by both
renderers side by side, the vocabulary that names the nodes the page had not drawn, and the
Material catalogue the page is built with, which closes it — plus the
example itself at `/web/`, and the Flutter build at `/flutter/`, whose root is that same
site page drawn by the other renderer and whose `/flutter/listings/` is the example on its
own. Every band of the page
is a node tree: the two frames of the comparison are the one thing the model cannot
describe, and they arrive through `EmbedNode`.
`--serve` previews the result locally. [`.github/workflows/pages.yml`](.github/workflows/pages.yml)
publishes it to GitHub Pages on every push to `main` — the published site is
<https://cedvdb.github.io/unibox/> — which needs one setting first: Settings → Pages →
Source: **GitHub Actions** (see
[`example/README.md`](example/README.md#the-site-is-one-page)).

The workspace targets Dart `^3.13.0`. Continuous integration runs the format check,
`dart analyze`, every suite, `dart doc` for each package, the performance budget and the
scale benchmark — the last one holds a synthetic page of thousands of nodes to a baseline,
so a change that makes a big page slower fails the build (see
[`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

Where to read more:

- [CONTRIBUTING.md](CONTRIBUTING.md) — setup, the verify loop, what "done" means for a
  token or a node, and the commit convention.
- [MAINTENANCE.md](MAINTENANCE.md) — the monthly pass: what runs on its own (CI, the
  weekly gate, Dependabot), what a human decides, and how to hand a task to an assistant.
- [AGENTS.md](AGENTS.md) — the working rules for a coding agent: the guardrails, the
  repository map, the verification command and the touch points for a change that
  spans core and both renderers.
- [llms.txt](llms.txt) — a plain text index of this documentation, for a tool that
  reads files rather than links.
- [design.md](design.md) — why the model looks like this: the rules behind the
  defaults, the naming, the non-goals, and what was deliberately left out.
- [PERFORMANCE.md](PERFORMANCE.md) — what a page with thousands of nodes costs, the three
  shapes `tool/scale.sh` measures, and the baseline CI holds them to.
- [RELEASE.md](RELEASE.md) — the checklist for cutting a release, including the one
  step that is a human decision (`publish_to: none` off).
- [example/README.md](example/README.md) — the page, the dialog, how they are
  hosted, and what the static export contains.
- The package READMEs hold the mapping tables, target by target:
  [core](packages/unibox_core/README.md),
  [material](packages/unibox_material/README.md),
  [flutter](packages/unibox_flutter/README.md),
  [css](packages/unibox_css/README.md), [element](packages/unibox_element/README.md),
  [html](packages/unibox_html/README.md),
  [conformance](packages/unibox_testing/README.md).

## License

MIT, see [LICENSE](LICENSE). Every package carries a copy so it can be published on
its own; `publish_to: none` keeps the workspace off pub.dev until a release is cut
deliberately.
