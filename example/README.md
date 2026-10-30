# Unibox examples

These packages render **the same node tree** with both renderers: one description,
two host applications. The description is a single page component —
`ExamplePageNode`, a `StatefulNode` — that draws a list of apartments behind a
navigation bar and a sign-up form the bar opens as a dialog over it: two controlled
text inputs, a hand drawn checkbox, a hover aware button, a link and a status line, in
a card that a barrier and `Escape` dismiss. The list scrolls under the bar.

That page is the *example*. The **site** is one page of its own: the claim and the diagram
that answers it — one `Unibox` chip branching into HTML and Flutter, each branch carrying
the example drawn by that renderer — and the Material catalogue the whole thing is built
with.

| Package | Role |
| --- | --- |
| `unibox_example_shared` | The example as one node (`ExamplePageNode`, with `ExampleState` and `ExampleStore`) and the parts it is built from (`buildExamplePage`, `buildApartmentsPage`, `buildSignupDialog`); the site as one node (`buildSitePage`) and its four bands (`buildHeroSection` — the claim and the diagram under it — `buildIndexableSection` — what a search engine is served, and what Flutter does with the page afterwards — `buildVocabularySection` — the nodes the page had not drawn, beside the same card taken apart — and `buildMaterialSection` — the catalogue that closes it); plus the palette. The listings are a `GridNode` of `MaterialCard`s, so the example also shows the design-system package. Pure Dart, no renderer. |
| `unibox_example_flutter` | Flutter host: one file (`lib/main.dart`) — the surface and the link policy. |
| `unibox_example_html` | HTML host: the site's document, the example's document, the shipped font faces, the one `<iframe>` node the comparison needs, and the build script — no page trees, which live in the shared package. |

Neither host holds state. The page owns it in `ExampleStore`: the Flutter host renders
the node through `FlutterStateful`, which creates the store, subscribes to it and
disposes it, and the HTML host writes the state that store starts with, because a
document is a snapshot — `toDocument` calls `onMount` for nobody and there is no
second frame to redraw. What a host still supplies is what a node cannot know — the
surface the tree is drawn on and how a link opens — which is why each one is a single
small file.

## One component, two small hosts

`ExamplePageNode` is a `StatefulNode<ExampleState, ExampleStore>`. Its state is
the form and whether the dialog is open, and its view is the frame, the listings
and the dialog as one tree. A field reports a value, the bar reports a
destination, the dialog reports a dismissal; each publishes a new `ExampleState`
and the renderer draws the view again. No host wires a callback, so the whole
application moves between the two targets as one node.

Flutter renders it with `FlutterStateful(node: ExamplePageNode())` inside its
`MaterialApp`; the HTML host renders the same node with `toDocument`, which draws the
state the store starts with. A document is a snapshot, so the published page has to
be told which state to start in — `showOverlays: true` is the `/signup` page, whose
whole purpose is the open dialog. What makes a browser subscribe to the same store is
a client runtime (`unibox_dom`), which is a later phase; until then the export is the
first frame.

## The sign-up form is a dialog

`buildSignupDialog(...)` wraps the card in an `OverlayNode`: the node carries the
policy (`onDismiss`, the barrier, `Escape`) and sits in the tree where the view
says it belongs, above the page. Being open is therefore state of the page —
`ExampleState.signupOpen` — and `exampleView` includes the node while it is open
and leaves it out when it closes, so no view needs an overlay slot and the tree
stays immutable.

Each renderer presents it in its own idiom. Flutter puts the card in a modal on
the root overlay, with a scrim over the page, a barrier press and `Escape` both
calling `onDismiss`, and the focus it had before the dialog opened restored on
exit. The web renderer draws a fixed layer with `role="dialog"` and
`aria-modal="true"`; the barrier and `Escape` wait for the client build (Task
104), so the static export is a snapshot of the layer rather than an interactive
modal.

The fields are the form's, not the platform's: a `TextInputNode` in a box, with the
message under it drawn from the same state. Typing an address without an `@` turns that
box's border and the message red, and finishing the address takes both away, because
`buildSignupCard` reads `SignupFormState` and the store has already replaced it. The two
fields carry a key each, so an input keeps its state — and its caret — while a message
row comes and goes above or below it.

That is what the document is: `build/site/web/listings/index.html`, written by
`dart run bin/build_site.dart` (`tool/site.sh` puts the Flutter build beside it). The form
is in the tree only while the dialog is open, so the document is published with it closed —
the state the application starts in.

## One seed, six palettes

The example is branded with a single colour. `ExampleSeed.defaultSeed` is `rose`, a
pink at `#B3265E`, and
every colour of the page is read out of the palette Material grows from it
(`MaterialPalette.fromSeed`) — the accent, the tint behind the open navigation item,
the card, the page, the text, the muted text and the border. A tree holds no colour of
its own: it names roles, and the theme the host installs answers them.

That is what makes the picker possible. It is one builder — `seedPicker` — and it sits
beside the name in both headers: the example's navigation bar and the site's header. A
palette is the whole page, so it is chosen where the page begins — a row of dots next to
the wordmark — rather than above the catalogue that explains it further down.

Each swatch is a link to *the page it is on* with `?seed=<name>`, and every colour of the
page answers it, because the tree names roles and the host answers them with a theme.

| Host | What `?seed=rose` means |
| --- | --- |
| Flutter | its link policy reads the address, installs the rose palette and redraws. Nothing loads, and the page keeps its store: the dialog stays open, the filter stays chosen |
| The site | the browser follows the link, `main.client.js` reads the address and renders the root with that palette, because a static document was rendered before the reader clicked |

The catalogue's own page carries the seed one step further: each showcase frame is a
document of its own, so the seed travels into its address too
(`web/listings/?seed=rose`). A reseed therefore reaches the frames with the page
around them, and one page is never two palettes.

Three things are worth knowing about the result:

- **The accent is quieter than the seed.** `tonalSpot` is Material You's own scheme,
  and it spends a saturated brand colour on a palette of low chroma: the pink
  `#B3265E` becomes `#8C4A5D`, a dusty one. That is the algorithm being faithful to
  Material
  rather than to the seed, and `MaterialSchemeVariant.fidelity` is the dial that keeps
  the brand's own chroma instead. The swatches show the accent each seed *grows*, for
  the same reason: a picker painted with the seeds would promise colours the page does
  not use.
- **The two states of the accent are the palette's own layers.** Material paints a
  hover as 8% of `onSurface` over a fill; a box paints one opaque colour, so the
  example mixes that layer into the accent. The opacities stay in the palette rather
  than in the example.
- **The confirmation is a second seed.** Material's roles carry an error and no
  success, so `#15803D` seeds a small palette of its own and the message takes its
  green from that. It is the same green under all six brand seeds, because a
  confirmation is a convention and not a brand.

The one thing the picker cannot do is change a page that was written before the
reader clicked and is never redrawn: without the client runtime, a document keeps the
palette the build rendered it with, which is the default seed. Everything else — the
store that survives a reseed in Flutter, the frames that follow the page, the hexes
in the catalogue — is the address doing its job.

## One font, one set of weights

Both hosts ship the **same four font files**, 400/500/600/700 of one family:
`assets/fonts` in the Flutter app (declared with `flutter: fonts:` in its pubspec)
and the same files under `assets/fonts` of the site, declared with `@font-face` in
the documents.

It is not a detail. Without them the page asked for `system-ui` — SF Pro on a Mac,
which has a real semibold — while Flutter web ships no font at all and draws with
Roboto's 400/500/700, so a `FontWeight.semiBold` came out *visibly lighter* on the
Flutter side of the showcase than on the HTML side. The weight was the same in the
tree and in the CSS; what differed was whether the family had a face to draw it
with.

The family is still the host's decision, not the model's (`BoxTextStyle` names no
family): the app sets it on `ThemeData`, the documents set it on `body`, and both
point at files the example ships.

## The listings page

A search bar, a row of filters, a grid of listings and — on a wide surface — a map
beside them. It is the shape a real listing page has, drawn from the model:

| Part | What draws it |
| --- | --- |
| the search bar | a rounded `Box` with a border, and a magnifier of two boxes and a 45° transform — no icon font, no asset |
| the filters | pills of `MaterialInkWell`, one of them selected; `With a garden` is `visibleFrom: 900` |
| the cards | a `GridNode` of 240 pixel minimum, two columns at most, so the grid reflows from one column to two as its own width grows — not the window's |
| each card | a `MaterialCard` with a Pexels photo (`ImageNode`, `ImageFit.cover`), the name, where it is — a district and a capital — two words about the flat, the summary and the rent |
| the map | drawn from nodes: a surface, four parks, three rotated roads, the capital names and three price pins placed with `PositionedNode` |
| the pill on a phone | the map column is `visibleFrom: 900`, so below it the page floats a `Map` pill over the bottom of the listing — placed, not measured, and it does nothing when pressed |

The six listings stand in six capitals — Paris, Berlin, Lisbon, Vienna, Madrid and
Rome — one flat each, because a site that only ever shows one city is a site about that
city. Every capital is a euro country, so the one currency the card prints is honest, and
each street is named in the language of the city it is in. The two lines that describe the
list — the query in the search bar and `6 apartments in 6 capitals` above the cards —
count the capitals from the data rather than repeating a number.

The map is drawn rather than embedded on purpose: a real map is a third-party embed
with a key and a script, and this one shows the shape of a map without either. It is
also the one place the example uses `visibleFrom`/`visibleUntil`, the token a width
needs — `design.md` §5.15 records why a width is measured on the box and not on the
window.

**Why the floating pill is placed, and why it is inert.** A control pinned to the
bottom of a page has to stay put while the page scrolls, which `position: fixed` does
and a flow box cannot: the listing is the box that scrolls, so a `PositionedNode` in a
`StackNode` with the page as its cell is where the placement belongs, and the pill's
own `margin` is the 24 pixels between it and the edge. That is the pill's whole job —
it is the shape of a floating action at the bottom centre of a narrow page. Pressing it
does nothing: the map it would open is the column beside the cards, a wide page has
that column already, and a narrow one has nowhere to put a second view of it, so
nothing in the page opens an overlay.

The page scrolls, not the document. `Overflow.scroll` on the box below the
navigation is a `SingleChildScrollView` in Flutter and `overflow: auto` in CSS,
so the bar stays put and the listings move under it. The padding of the page sits
on a box *inside* the scrolling one, because Flutter puts the padding of a
scrolling box around its viewport while CSS puts it inside the scrollport; one
level in, both renderers scroll the same content.

The two branches are windows, not handles: each frame is an `<iframe>` filling the box the
tree drew for it, 540 pixels tall, so the two renderings are of one size. Narrow the *window* and both answer the same breakpoint. A grip on one frame
would make the two incomparable, which is why neither has one.

## Keeping the two renderings alike

Both apps render the same page, so they have to *show* the same page. That is
pinned where a renderer lives, not here: `packages/unibox_testing` holds one
table of boxes and the appearance each of them has to produce, and both renderer
suites render that table and read the appearance back out of their own output —
the Flutter suite from the widget tree, the HTML suite from the emitted CSS.

A renderer that drops a token, or starts wrapping a node in something that paints
differently, therefore fails its own suite instead of making the two renderings drift
apart. The apps themselves only check that the page they draw is the page the
shared tree describes: the title, the two fields, the button, the link, the
confirmation, the listings, a page box that fills the surface the host gives it,
and a list that scrolls under the bar.

The rest of the parity lives in the hosts, because a host owns the surface a tree
is drawn on:

- The Flutter app inherits the platform font, the window size and a `Material`
  theme from `MaterialApp`; the HTML document declares `html, body { height: 100%;
  margin: 0 }` so the page box has something to resolve its `100%` against,
  and asks CSS for the platform font with `font-family: system-ui, …`.
- Fields and links carry no platform chrome on either side (no Material
  underline, no user agent border, padding, focus ring or underline), so the node
  tree is the only thing that decides how they look.

What stays approximate on purpose: the exact font face, line breaking, shadow
blur, placeholder and focus colours, and hit testing. A browser and Flutter never
agree on those down to the pixel, and the goal is that the two renderings are
recognisably the same page.

## The site is one page

`buildSitePage` is the whole site: a header, four bands and a footer, in the order the
argument needs. It is published at <https://cedvdb.github.io/unibox/>.

| Band | What it says |
| --- | --- |
| the hero | the claim — *Flutter UI, searchable HTML* — and the diagram that answers it: one `Unibox` chip branching into **HTML and CSS** and **Flutter**, each branch carrying the live example it produces, so the page on the left and the Flutter build on the right are the two halves of the diagram rather than a comparison beside it |
| *Make Flutter Web pages indexable* | what a search engine is actually served: the same screen as a Dart tree and as the markup it becomes — a real `h1`, real text and a link with an `href` — then the two facts the cards cannot show: Flutter takes the page over once the build arrives, and only the pages that have to be found need a tree |
| *Just boxes* | what the whole vocabulary amounts to: a screen is containers, so the four nodes the page had not drawn yet — a picture, a stack, a child placed at an offset and a field with no chrome — sit as one listing card beside the same card taken apart node by node, under the two calls that tree is for, `node.toWidget()` and `node.toHtml()` |
| *Material 3, as values and nodes* | the catalogue: every component first, then the type scale and the colour roles those components name |

The frames are the claim's evidence, so they sit in the band that makes it: a reader
scrolls from the sentence to the two renderings it is about, and meets each rendering's
name once, and each name sits over the rendering it belongs to. Every band is a `section`
on the web, and so is every block of the catalogue under its `h3` — the page is a
document, and the elements say where one part of it ends. The indexable band comes
next, because the HTML branch is the reason most readers are there: it shows what a crawler
is served and how little of the application has to change for it. The vocabulary follows,
because a frame draws a whole tree and never the parts it is made of: the four nodes the
page had not drawn are the four a reader would otherwise never see named, and the card
beside the list is not a screenshot of one — it *is* the list. The band closes on what that
list is for: `node.toWidget()` and `node.toHtml()`, the two calls the rest of the page is an
example of. The catalogue closes the page, because the design system is how every band
above it is drawn, not what it says.
Every band is a node tree — the frames are the only thing the
model cannot describe, and they arrive through `ShowcaseFrame`/`EmbedNode`.

There is one `h1` (the claim), an `h2` for each branch of the diagram, for the catalogue
and for the vocabulary, and an `h3` per block of the catalogue, so the outline a crawler and
a screen reader build the page from is the outline a reader sees. The header and the
footer are landmarks, the links are real `LinkNode`s, and the page needs no route: a
reader scrolls from the claim to the evidence, which is a thing a static document can do
without a click.

The example itself is not a page of the site any more. Its one document —
`build/site/web/listings/index.html` — exists because the left frame has to load it. The
sign-up form is a dialog over that page and not an address of its own: nothing links to it,
and a browser without the client bundle shows the page with the form closed. The Flutter
build sits beside it at `build/site/flutter/`, with the same one route.

`tool/site.sh` builds the whole thing into `build/site`, a directory any static host
can publish:

```shell
tool/site.sh --serve                        # http://localhost:8000/
tool/site.sh --base=/unibox/ --url=https://cedvdb.github.io/unibox/
```

| Path | What it is |
| --- | --- |
| `/` | The site: the claim and the diagram, then the vocabulary, then the catalogue that closes it, as one page |
| `/web/listings/` | The example as a document that runs itself — the left frame, real HTML a reader can inspect and act on |
| `/flutter/listings/` | The same example, built by Flutter — the right frame |
| `/flutter/app.js` | The loader a document boots the application through, with the base path `flutter_bootstrap.js` cannot know |

### See the handover

`/web/listings/` is a document until a reader asks. Open it, scroll the list, and press a
listing: the ink shows the press, and the application boots on that signal — it then starts where
the page was scrolled, not at the top. `/flutter/listings/` is the same screen built by Flutter and
served as its own route, which is what the right frame shows.

Two commands prove it without a reader: `tool/dom_check.sh build/site` presses a control in the
client rendering and fails when the page does not answer, and `tool/boot_check.sh build/site` asks
the other question — whether a *takeover* document becomes the application, which is the library's
tool for a screen that must be found, not what this example's pages do.
The check serves the build under the prefix it was built for, which `tool/site.sh` records, so the
command that runs locally is the command that runs on a deploy.

`build/site/version.txt` names the commit the site was built from. A deploy is not
instant and is not always the one it looks like — one publication here shipped the
previous build while its script was current — so `curl …/unibox/version.txt` answers
"am I looking at a stale page?" without reading CSS class hashes.

Every document carries the same fact as `<meta name="unibox-build" content="…">`,
because `version.txt` answers for the site while a tab answers for one document: a
page opened before a deploy keeps drawing the markup it arrived with, which is
identical to the deployed page down to a layout the new build has already fixed.
`curl` the page itself when what is on screen and what is in the repository disagree.

The page links with relative paths and the documents carry **no `<base>` element**, so
the same build works at `/` and at `/unibox/`: a base href of `/` would send every
relative link, and both frames, to the domain root.

The site is a node tree as well, so it is built with the library it documents: its bands
are boxes and text, drawn by the same renderer that draws the example.

The catalogue's dialog is the exception that proves the rule: the button is a
`MaterialInkWell` over a filled box, so a press leaves ink where it landed, and the
`MaterialDialog` is in the tree only while the demo's store says it is open. A document has
no store, so it draws the resting well and no dialog until an application takes the page over.

The one thing the model cannot describe is an `<iframe>`, and that is what `EmbedNode` is for:
the comparison's two frames are the only non-node content on the site, and the page around
them is boxes and text.

The export writes one document, in the state the application starts in: the dialog is state,
and a dialog is not a route, so there is no second page to publish. A static host has no
rewrite rule either, which is why the Flutter route is a real `index.html`; the build writes
one entry document and the script copies it into `flutter/listings/`, with the absolute base
href that lets the assets resolve from the deeper path.

The deployment is `.github/workflows/pages.yml` — verify, build, publish. It needs
one setting a workflow cannot make: Settings → Pages → Source: **GitHub Actions**.
Until that is on, the job still verifies the workspace and builds the site, keeps it
as a downloadable artifact of the run, and skips the deploy with a notice; turning
Pages on and re-running the workflow publishes the same build.

## Flutter app

The host is `lib/main.dart`: a `MaterialApp` for the surface, a
`FlutterLinkScope` for what following a link means, and a `FlutterStateful` for
the page. The web runner is checked in (`web/index.html`), so a browser build
needs no scaffolding step:

```shell
cd example/unibox_example_flutter
flutter run -d chrome
```

The widget tests need no runner:

```shell
cd example/unibox_example_flutter
flutter test
```

## The HTML host

The host is a handful of files: `lib/document.dart` puts `ExamplePageNode` in a document (language, title, description,
the `html, body` height and the font stack), and `lib/site/` holds the site's own
document and its root — the page, its `<iframe>` frame, and the palette the page's
roles resolve against. `bin/build_site.dart` writes the site page and the two states
of the example:

```shell
cd example/unibox_example_html
dart run bin/build_site.dart --out=build/site
open build/site/index.html
```

`web/listings/index.html` is the one document: the page, with the dialog closed, which is
the state the application starts in. The destination of the bar is a real link, so a crawler
follows the `href` and a copy of the page with no client runtime follows it too. Where the
runtime is there, the same press is answered by the tree instead — the page switches in place
and the document is not loaded as well.

The sign-up control in the bar is a button and not a link, because an account is not a place
to go: it opens the form over the page being read, and no address leads to it.
The whole site, with both renderings and the Flutter build beside them, is
`tool/site.sh` (see [the site is one page](#the-site-is-one-page)).

The page is a document before it is a picture: the header is a `<header>`, the hero's
claim an `<h1>`, each band an `<h2>`, each block of the catalogue an `<h3>`, the
example's bar a `<nav>` around the name and its destination — with the sign-up button
beside it rather than inside, since a landmark is a list of places to go — its page box
a `<main>`, the card an `<article>`, the listings a `<ul>` of `<li>`s, and the
confirmation a live region. None of that changed a pixel, which is what the semantics
tokens are for; open the export in a reader or a crawler and the outline is there.

The document also arrives with what a search engine reads before any script runs:
`<html lang="en">`, one `<title>` and one description
(`buildSiteDocument()`, `buildExampleDocument(page:)`), the text and the `role`
attributes as markup, and a `robots.txt` next to it. A sitemap would need the address
the page is served from, so `tool/site.sh --url=…` writes one when it is given it.

The page's links are real: the header and the footer are `LinkNode`s and the frames are
`<iframe>`s, so a crawler follows all of them without JavaScript. Nothing links to the
example itself — it is drawn in the frames, and it is not a destination of this page.
Inside the frame the example carries one more: its bar is a `<nav>` whose destination is
an `<a href>` naming the document that draws it. The sign-up control is not a link — it
opens a dialog over the page — so a crawler sees one document of the example and the one
link into it. A page that has to be found makes sense as a `LinkNode` with a real url,
which is the router work this project has deliberately not built.

The static export is the document on its own: the markup, the stylesheet with its state rules
and its container queries, and nothing that answers a press. What answers them is the client
rendering — `web/main.client.dart`, compiled by `tool/site.sh` into `web/main.client.js` and
fetched by the document — which adopts that markup and keeps it, so the elements a reader acts
on are the elements the crawler read. That is why the left frame of the comparison can be
inspected: there is no canvas in it, before or after a press. The library's `takeover` is the
other way to make a page interactive — it starts the application instead — and it is what
`tool/boot_check.sh` measures; this example's pages do not need it.

```shell
cd example/unibox_example_html
dart test
```

## Shared package

```shell
cd example/unibox_example_shared
dart test
```
