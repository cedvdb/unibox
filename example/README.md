# Unibox examples

These packages render **the same node tree** with both renderers: one description,
two host applications. The description is a single page component —
`ExamplePageNode`, a `StatefulNode` — that draws a list of apartments behind a
navigation bar and a sign-up form the bar opens as a dialog over it: two
controlled text inputs, a hand drawn checkbox, a hover aware button, a link and a
status line, in a card that a barrier and `Escape` dismiss. The list scrolls under
the bar.

| Package | Role |
| --- | --- |
| `unibox_example_shared` | The page as one node (`ExamplePageNode`, with `ExampleState` and `ExampleStore`) and the parts it is built from (`buildExamplePage`, `buildApartmentsPage`, `buildSignupDialog`), the three site pages (`buildLanding`, `buildMaterialGallery`, `buildShowcase`), the site frame and its destinations, plus the palette. The listings are a `GridNode` of `MaterialCard`s, so the example also shows the design-system package. Pure Dart, no renderer. |
| `unibox_example_flutter` | Flutter host: one file (`lib/main.dart`) — the surface and the link policy. |
| `unibox_example_jaspr` | Jaspr host: the document, the shipped font faces, the one `<iframe>` node the showcase needs, and the build script — no page trees, which live in the shared package. |

Neither host holds state. The page owns it in `ExampleStore`; the host renders the
node through `FlutterStateful`, which creates the store, subscribes to it and
disposes it. What a host still supplies is what a node cannot know — the surface
the tree is drawn on and how a link opens — which is why each one is a single
small file.

## One component, two small hosts

`ExamplePageNode` is a `StatefulNode<ExampleState, ExampleStore>`. Its state is
the form and whether the dialog is open, and its view is the frame, the listings
and the dialog as one tree. A field reports a value, the bar reports a
destination, the dialog reports a dismissal; each publishes a new `ExampleState`
and the renderer draws the view again. No host wires a callback, so the whole
application moves between the two targets as one node.

Flutter renders it with `FlutterStateful(node: ExamplePageNode())` inside its
`MaterialApp`; Jaspr renders the same node through `JasprStateful` inside a
`Document`, which draws the first state on the server. The client build (Task 104)
is what makes a browser subscribe to the same store; until then the export is the
first frame, which is why a static document has to be told which state to start
in.

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

That is what the two documents are: `build/site/web/listings/index.html` is the
listings, and `build/site/web/signup/index.html` is the same page with the dialog over
it, written by `dart run bin/build_site.dart` (`tool/site.sh` puts the Flutter build
beside them). A browser without the client bundle can only be shown one of the two — so
the listings document is the one that can be read without dismissing anything, and the
form
is its own url.

## One seed, one palette

The example is branded with a single colour. `ExamplePalette.seed` is `#2D6CF3`, and
every other colour is read out of the palette Material grows from it
(`MaterialPalette.fromSeed`) — the accent, the tint behind the open navigation item,
the card, the page, the text, the muted text, the border and the error. Nothing else
in the example is a hex value, so a different brand is a different seed and no other
line changes.

Three things are worth knowing about the result:

- **The accent is quieter than the seed.** `tonalSpot` is Material You's own scheme,
  and it spends a saturated brand colour on a palette of low chroma: the vivid
  `#2D6CF3` becomes `#4A5C92`. That is the algorithm being faithful to Material
  rather than to the seed, and `MaterialSchemeVariant.fidelity` is the dial that keeps
  the brand's own chroma instead — a second palette is one argument away.
- **The two states of the accent are the palette's own layers.** Material paints a
  hover as 8% of `onSurface` over a fill; a box paints one opaque colour, so the
  example mixes that layer into the accent. The opacities stay in the palette rather
  than in the example.
- **The confirmation is a second seed.** Material's roles carry an error and no
  success, so `#15803D` seeds a small palette of its own and the message takes its
  green from that.

The values are `final` and not `const`, which is the one cost of the change: a
palette grown from a seed is computed when the page is built, so the styles that name
its colours are computed too, and a few `const` nodes became plain ones. What the tree
still does is name roles — `BoxColor.role(ExampleColor.canvas)` — and the theme, which
now carries both the example's vocabulary and Material's, answers them once for the
whole page.

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
| each card | a `MaterialCard` with a Pexels photo (`ImageNode`, `ImageFit.cover`), the name, the district, two words about the flat, the summary and the rent |
| the map | drawn from nodes: a surface, four parks, three rotated roads, the district names and three price pins placed with `PositionedNode` |
| the pill on a phone | the map column is `visibleFrom: 900`, so below it the page floats a `Map` pill over the bottom of the listing — placed, not measured, and it does nothing when pressed |

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

The two frames of the showcase are draggable: each is an `<iframe>` with CSS
`resize: horizontal`, so a reader narrows one and watches the page inside reflow —
the comparison the page exists for. The drag is host chrome, not a token.

## Keeping the two renderings alike

Both apps render the same page, so they have to *show* the same page. That is
pinned where a renderer lives, not here: `packages/unibox_testing` holds one
table of boxes and the appearance each of them has to produce, and both renderer
suites render that table and read the appearance back out of their own output —
the Flutter suite from the widget tree, the Jaspr suite from the emitted CSS.

A renderer that drops a token, or starts wrapping a node in something that paints
differently, therefore fails its own suite instead of making the two renderings drift
apart. The apps themselves only check that the page they draw is the page the
shared tree describes: the title, the two fields, the button, the link, the
confirmation, the listings, a page box that fills the surface the host gives it,
and a list that scrolls under the bar.

The rest of the parity lives in the hosts, because a host owns the surface a tree
is drawn on:

- The Flutter app inherits the platform font, the window size and a `Material`
  theme from `MaterialApp`; the Jaspr document declares `html, body { height:
  100%; margin: 0 }` so the page box has something to resolve its `100%` against,
  and asks CSS for the platform font with `font-family: system-ui, …`.
- Fields and links carry no platform chrome on either side (no Material
  underline, no user agent border, padding, focus ring or underline), so the node
  tree is the only thing that decides how they look.

What stays approximate on purpose: the exact font face, line breaking, shadow
blur, placeholder and focus colours, and hit testing. A browser and Flutter never
agree on those down to the pixel, and the goal is that the two renderings are
recognisably the same page.

## The static site

`tool/site.sh` builds the site into `build/site`, a directory any static host can
publish:

```shell
tool/site.sh --serve                        # http://localhost:8000/
tool/site.sh --base=/unibox/ --url=https://cedvdb.github.io/unibox/
```

| Path | What it is |
| --- | --- |
| `/` | What the library is, and the comparison |
| `/material/` | The Material library: the type scale, the colour roles and the components |
| `/showcase/` | The example drawn by both renderers, side by side in two frames |
| `/web/listings/` | The example's listings, rendered by Jaspr |
| `/web/signup/` | The same page with the sign-up dialog over it |
| `/web/pricing/` | The price page: what a home costs, and the questions people ask |
| `/main.client.js` | The browser runtime the two above load |
| `/flutter/listings/`, `/flutter/signup/`, `/flutter/pricing/` | The same pages, rendered by Flutter |

`build/site/version.txt` names the commit the site was built from. A deploy is not
instant and is not always the one it looks like — one publication here shipped the
previous build while its script was current — so `curl …/unibox/version.txt` answers
"am I looking at a stale page?" without reading CSS class hashes.

Every page carries the same fact as `<meta name="unibox-build" content="…">`, because
`version.txt` answers for the site while a tab answers for one document: a page opened
before a deploy keeps drawing the markup it arrived with, which is identical to the
deployed page down to a layout the new build has already fixed. `curl` the page itself
when what is on screen and what is in the repository disagree.

The pages link with paths relative to their own depth and the documents carry **no
`<base>` element**, so the same build works at `/` and at `/unibox/`: a base href of
`/` would send every relative link, and both frames, to the domain root.

The gallery and the showcase are node trees as well, so the site is built with the
library it documents. The gallery's dialog is the exception that proves the rule:
the button is a `MaterialInkWell` over a filled box — so a press leaves ink where it
landed — and the `MaterialDialog` is in the tree only while the demo's store says it
is open. The runtime is what makes the press do anything, and a document without
JavaScript shows the button, no ink and no dialog.

The one thing the model cannot describe is an `<iframe>`, and that is what `EmbedNode` is for: the showcase's two frames are the only non-node
content on the site, and the page around them is boxes and text.

Being open is state, and a static page cannot be clicked into existence, so the
export writes one document per destination and the Flutter app reads the path it was
served at (`signupOpenFromUrl`) to start in the matching state. A static host has no
rewrite rule either, which is why every Flutter route is a real `index.html`: the
build writes one entry document and the script copies it to each route, with the
absolute base href that lets the assets resolve from any depth.

The Jaspr pages arrive as HTML and CSS and then keep going: `web/main.client.dart`
is a browser entrypoint of three lines, `tool/site.sh` compiles it to
`/main.client.js`, and the document loads it with `defer`. It is written by hand
rather than generated by `jaspr_builder` because the page is one component — nothing
has to be matched against a server tree, and no code lives in the repository only
because a builder wrote it. Both sides build the same root (`buildExampleRoot`), and
the class names of the stylesheet are content hashes, so the markup the runtime
draws is the markup the server wrote: a page that survives its own hydration, and a
crawler that reads the same document either way. What reacts is the state — a press
on the barrier closes the dialog, the form edits its store — and a document without
JavaScript still shows the state it was exported in.

Which page it draws is the path it is on, read the way the export writes it:
`web/listings/`, `web/listings` and `web/listings/index.html` name one destination,
and a site served from a subdirectory prefixes all three with its base path.
`examplePageForPath` therefore matches the destination as a segment, the rule the
Flutter host applies to `Uri.base.pathSegments`. Suffixing the whole path once named
no destination for the `index.html` form, and the runtime drew the *front page* over
the listing the host had served — which looked like a different scroll model rather
than a different page, because a document scrolls and takes its bar with it while an
app keeps the bar and scrolls the list under it.

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

## Jaspr app

The host is two files: `lib/main.dart` holds `ExampleApp`, the same node in its
server form, and `lib/document.dart` puts it in a document (language, title,
description, the `html, body` height and the font stack). `bin/build_site.dart`
renders that document once per destination, next to the gallery and the showcase
the site also publishes:

```shell
cd example/unibox_example_jaspr
dart run bin/build_site.dart --out=build/site
open build/site/web/listings/index.html
```

There is one file per destination because being open is state, and a static
export cannot keep state — open the document you want. `web/listings/index.html` is
the listings; `web/signup/index.html` is the same page with the dialog already open.
The two destinations of the bar are real links, for the same two reasons: a crawler
follows the `href`, and a copy of the page with no client runtime follows it too,
landing on the document that draws the state it names. Where the runtime is there, the
same press is answered by the tree instead — the page switches in place and the
document is not loaded as well, so a visitor sees one page rather than a flash of the
next one.
The sign-up control in the bar is the exception, because an account is not a place to
go: it is a box with the button role and no `href`, it opens the form over whatever
page is being read, and nothing in the markup links to `web/signup/` — that document is
there for a reader who arrives at its address.
The whole site, with both renderings and the Flutter build beside them, is
`tool/site.sh` (see [the static site](#the-static-site)).

Each page is a document before it is a picture: the bar is a `<nav>` around the name
and the two destinations — with the sign-up button beside it rather than inside, since
a landmark is a list of places to go — the page box
is a `<main>`, the card an `<article>`, the listings a `<ul>` of `<li>`s, the page
title an `<h1>`, and the confirmation a live region. None of
that changed a pixel, which is what the semantics tokens are for; open the export
in a reader or a crawler and the outline is there.

Each page also arrives with what a search engine reads before any script runs:
`<html lang="en">`, its own `<title>` and description
(`buildExampleDocument(page:)`), the text and the `role` attributes as markup, and
a `robots.txt` next to the two documents. A sitemap would need the address the
pages are served from, so it is left to the deployment.

What a crawler sees is the documents and the links between them: the bar is a `<nav>`
of real `<a href>`s, and each one names the document that draws the state it asks for.
What it cannot see is the client answering a press in place — the tree switches the
page without touching the address bar, and moving the address is routing, which
`TASK_PLAN.md` lists as deferred.

The static export is a snapshot of the server render: the markup, the inline
styles, the scoped hover rules and the media query are all there, but the `click`
and `input` listeners become live only once the component runs on the client (the
Jaspr client build). The shared state logic they call into is covered by the tests
of `unibox_example_shared`.

```shell
cd example/unibox_example_jaspr
dart test
```

## Shared package

```shell
cd example/unibox_example_shared
dart test
```
