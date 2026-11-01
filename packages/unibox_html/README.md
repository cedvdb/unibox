# unibox_html

The web renderer: a Unibox tree as HTML a search engine can read.

A Flutter screen is a canvas, which a crawler, a link preview and a reader without
JavaScript all see as nothing. This package renders the same tree as a document — real
text, real headings, real links, one stylesheet — with no framework and no runtime.

It holds the whole web target in one package, in the three layers a node passes through on
its way to a browser: the **CSS** a design token becomes (`lib/src/css/`), the **element
plan** a node becomes (`lib/src/element/`), and the document those are written into.
`unibox_dom` builds the same plan in a page, which is why the two web renderings cannot
drift. They are directories rather than packages because a package boundary is a version to
keep in step, and the third renderer they were split for was deleted.

Pure Dart, with the model as its only dependency. A document can be rendered in a server, in
a build step, in a command line tool, and, for a host whose backend is not Dart, compiled to
JavaScript.

## What it answers

| Question | Answer |
| --- | --- |
| a tree as a fragment | `toHtml(tree)`, or `tree.toHtml()`, with the one `<style>` element in front of it |
| a tree as a page | `toDocument(head: DocumentHead(title: …), scope: UniboxScope(lang: …))` — the fragment, a `<head>` and the stylesheet |
| a page as a value | `Document(node: …, head: …).write()` — the page, its language and its head, for a build that writes several |
| a page in one language of several | `toDocument(scope: UniboxScope(lang: …), head: DocumentHead(alternates: …))` — the language it is written in, and the `hreflang` links that pair it with its translations |
| a page an application takes over | `toDocument(takeover: Takeover(boot: …))` — the bundle prefetched, the recorders, the boot on a signal |
| what a document is | a snapshot of a state: initial state, overlays open, no listeners |

## The head

A tree describes a region of a page, so the page's own title, address and translations belong
to the host. They arrive as one value, `DocumentHead`, beside the tree:

```dart
final String page = toDocument(
  tree,
  scope: const UniboxScope(lang: 'de'),
  head: DocumentHead(
    title: 'Wohnungen in Amsterdam',
    description: 'Einundvierzig Wohnungen zur Miete.',
    image: 'https://example.com/cards/amsterdam.jpg',
    canonical: 'https://example.com/de/apartments/',
    links: const <DocumentLink>[
      DocumentLink.preload(
        'assets/fonts/roboto-400.woff2',
        as: 'font',
        type: 'font/woff2',
        crossorigin: true,
      ),
    ],
  ),
);
```

| The head carries | Written as | For |
| --- | --- | --- |
| `title` | `<title>`, then `og:title` | the result a reader clicks and the tab they see |
| `description` | `<meta name="description">`, then `og:description` | the sentence a result shows under the title |
| `image` | `og:image` | the picture a link preview is drawn around |
| `canonical` | `<link rel="canonical">` | the one address of two that serve the same page |
| `alternates` | `<link rel="alternate" hreflang>` | the same page in its other languages |
| `meta` | `<meta name="…" content="…">` | a tag this package does not know |
| `links` | `<link rel="…">`, from a `DocumentLink` | a font, an image or a bundle fetched before anything asks |
| `raw` | verbatim | markup this package does not describe |

`DocumentHead.raw([…])` is the shorthand for a host that only has the last one to say.

A link is a value rather than markup because the attribute that matters is the one a host leaves
out: a font preload with no `crossorigin` is fetched twice, once for the preload and once for the
`@font-face` that names it, which is worse than not preloading at all. `DocumentLink.preload`
requires `as` for the same reason — a browser sets a request's priority and headers from it, and a
guess is not a fetch.

Everything but `raw` is escaped, and every url goes through `safeUrl`, so a title or a canonical
address that came from data cannot end the element it is written into. `raw` is the door for the
`@font-face` rules of the font a host ships, a dark-mode block and structured data: it is written
verbatim, which is why it is the host's own text and never a string assembled from what a reader
supplied.

`lang` is not part of the value, because it is an attribute of the root element rather than a head
element. The renderer owns the order — the metadata and the links before the stylesheet, the
stylesheet before `raw` — so a fetch starts with the document, a host rule of equal specificity can
restate what the page starts with, and a font face still arrives before the text that uses it.

## A page as a value

`toDocument` is one call for one page, which is all a host with one page needs. A build that
writes several holds them as `Document` values beside the paths they are served at:

```dart
final List<({String path, Document document})> pages =
    <({String path, Document document})>[
      (path: 'index.html', document: home),
      (path: 'de/index.html', document: homeInGerman),
    ];

for (final ({String path, Document document}) page in pages) {
  File('site/${page.path}').writeAsStringSync(page.document.write());
}
```

The list is the site. Writing it is one loop, and anything else that has to know what the site
contains — a sitemap, a redirect table, a test that every page states its own `canonical` — reads
the same list instead of restating the paths, which is how a sitemap and the pages it lists drift
apart.

A page does not know the address it will be served at; a build does. `page.at(url)` is the same
page with that address as its canonical url, so the list can be built before the deployment
address is known, and each page still states one:

```dart
final Document served = home.at('https://example.com/unibox/');
```

## Escaping, which is the whole security surface

Everything a node carries is a `String` from the application, so one of them containing a
`<` ends an element and one containing a `"` ends an attribute. Three functions are the
gate, and they are tested adversarially rather than illustratively:

| Function | For | Escapes |
| --- | --- | --- |
| `escapeText` | content between two tags | `&`, `<`, `>` |
| `escapeAttribute` | a double-quoted attribute | `&`, `<`, `>`, `"` |
| `safeUrl` | an `href` or a `src` | the above, and `javascript:` becomes `#` |

Quotes are left alone in *content* because they mean nothing there, and escaped in an
attribute because an unescaped one is how a `class` becomes an `onload`.

`isRiskyUrl` is public so that a validator can report a tree carrying a script URL instead
of only patching it: a URL comes from data, and a `javascript:` href is a script that runs
when a reader clicks.

## A page in one language of several

A localised page is not a second tree. The copy is a `String` the way a colour is a `BoxColor`, so
it is an argument of the builder, and the document is written once per language:

```dart
UINode buildListingsPage(SiteCopy copy, SiteRoutes routes) => …;

final String page = toDocument(
  buildListingsPage(SiteCopy.de, SiteRoutes.de),
  scope: const UniboxScope(lang: 'de'),
  head: DocumentHead(
    title: SiteCopy.de.title,
    canonical: 'https://example.com/de/apartments/',
    alternates: <String, String>{
      'de': 'https://example.com/de/apartments/',
      'en': 'https://example.com/apartments/',
      'x-default': 'https://example.com/apartments/',
    },
  ),
);
```

| The document states | With |
| --- | --- |
| the language it is written in | `scope.lang` — one document per language, not one page that swaps its text |
| the direction it is written in | `scope.writingDirection` — the `dir` of the root element, which every box that states none inherits, so a region in another script states its own on the box |
| the other languages of the same page | `head.alternates` — the `hreflang` links, the whole set on every page of it |
| the address of this page | `head.canonical` — per language, or two translations compete as one |
| the language a reader gets | the address (`/de/…`): a crawler sends no `Accept-Language` and keeps no cookie |
| a language switch | a `LinkNode` to the other address, which is followable and crawlable like any other link |

`toDocument` translates nothing: it writes the strings it is given and states which language they
are written in. A catalogue — `.arb`, plurals, dates, numbers, collation — belongs to the
application, which may depend on `intl`; a tree that read the locale from its context could not be
a document at all, because a document is rendered with no context. That costs the copy nothing:
because it arrives as a value, a string the translation is missing is a compile error in every
language rather than a blank on one page.

The direction is a second attribute and not a reading of the first. `lang="ar"` does not by itself
say `dir="rtl"`, because a language is not a direction: a page in Arabic can hold a quotation, a
code block or a price that reads left to right, and Azerbaijani, Kurdish and Punjabi are written in
both scripts. A page that states no direction writes none, and the browser's own answer — left to
right — is what it reads in; nothing is inferred on the page's behalf.

## The CSS a token becomes

A token is a Dart value in `unibox_core`; CSS is text. `lib/src/css/` is the single place
where one becomes the other, so this renderer and `unibox_dom` produce the same declarations
for the same tree.

That is not tidiness. A class name is a hash of its declarations, which is what makes six
listings with one look cost one rule. Two mappings that disagreed would give one look two
class names, and a host stylesheet or a dark-mode block written against one page would stop
applying to the other — the drift this repository exists to prevent.

| Question | Answer |
| --- | --- |
| a dimension, a spacing | `cssLength(width)`, `cssSpacing(...)` — `8px`, `100%` for `double.infinity`, `8px 12px 16px 4px` in CSS's order |
| a colour, or a colour that names a role | `cssColor(...)`, `cssRoleReference(...)` → `#112233`, `rgba(17, 34, 51, 0.502)`, `var(--unibox-color-primary)` |
| a shadow | `cssBoxShadow(...)`, `cssBoxShadows(...)`, with the blur written in the unit a browser reads |
| a box, a text, an image, a grid | `boxDeclarations`, `textDeclarations`, `imageDeclarations`, `gridDeclarations` |
| the typography of a box, or the model's | `typographyDeclarations(style)`, `defaultTypographyDeclarations()` |
| a state, a theme | `stateRules(box, className)`, `themeDeclarations(theme)` — a rule is a value, `CssRule` |
| the class a look wears | `fnv1a` hashes its declarations into eight characters, so a look costs one rule wherever it is drawn |

`CssDeclarations` is a list and not a map because CSS allows a property to be written twice
— a fallback — and because its `text` is the text a class name is hashed from, which has to
be the same however the renderer built it.

## The element plan

`ElementPlan` is the whole decision of what a tree becomes, as a value: a tag, its
attributes in a fixed order, the class it wears, and the elements inside it. It carries no
markup, which is why `toHtml()` writes it to a string and `unibox_dom` builds nodes from the
same value instead of deciding again what a `Box` looks like — that is what lets a client
adopt a server's page rather than repaint it.

A node this renderer cannot draw throws rather than being skipped: a tree built for
another target fails loudly instead of shipping a page with a piece missing.

**A `LinkNode` is an `<a>`.** It is a box, so the tag, the `href` and the two declarations that
cancel a browser's link paint are the whole difference: the class stays the box's own look,
the children stay where they were, and the element takes the pointer even with nothing
inside it. There is no `role` and no `tabindex` on it — the tag is the role, and an anchor is
already in the tab order — so the markup a crawler reads is the control a reader presses.
`unibox_dom` binds the press: a plain click is cancelled and answered by the tree, and a
modifier, a middle click or a `newTab` stays the browser's.

**A box says whether the pointer may land on it.** Left unset, the class states what the box
is: `pointer-events: auto` for a box that holds children, answers a callback or paints a
state, and `none` for a painted leaf, so a decoration never stands in front of the control
it was drawn for. `capturesPointer: false` states `none` whatever the box holds — a badge
over a button's corner — and `true` states `auto` for a leaf that is a target of its own.
The flag is part of the class, so two boxes that differ only by it are two rules.

## Held to the same appearance

`test/conformance_test.dart` renders every case in `unibox_testing` and reads the
presentation back out of the output — the class the root element wears, and the
declarations that class is given — then compares it with the table the Flutter suite is
held to. That is the whole claim of the package: a document and a widget built from one
node look the same, and a token that drifted fails a test rather than a screenshot review.

## The scripts a page may carry

A document needs no JavaScript. The two scripts it may carry are for the handover — a page that
becomes an application — and each is a file a host includes, so a page that does not need one
pays for nothing:

| Script | What it does |
| --- | --- |
| `scrollScript` | records where each keyed region is scrolled to, and answers `window.unibox.takeScroll()` |
| `pressScript` | records the key and the position of a press, and answers `window.unibox.takePressed()` |
| `bootScript(url, policy:)` | loads the application on a signal, never before the first paint, and hands the page over |
| `uniboxClientScript` | both recorders, for a host that wants one file |

`Takeover` is how a page asks for all of it at once:

```dart
final String page = toDocument(
  ListingsPage(listings),
  head: const DocumentHead(title: 'Apartments'),
  takeover: const Takeover(
    boot: '/flutter/flutter_bootstrap.js',
    reveal: RevealPolicy.onReady,
  ),
);
```

It prefetches the loader at a low priority — deferring the download as well as the execution is
how a page gets a good score and a two-second dead click — and places the recorders before the
boot, because the application asks what the reader did. `record: false` is for a page that only
has to boot.

### The handover has three states, and it says so

Starting the engine and showing it are two different moments, and the second is the one a reader
feels. The boot writes `data-unibox-state` on the document element — `document`, `booting`,
`ready`, `app`, `failed` — and a host can style any of them:

| State | The document | The application |
| --- | --- | --- |
| `document` | the page | not started |
| `booting` | still the page: readable, pressable, scrollable, recording | loading, `opacity: 0`, unreachable by pointer or Tab |
| `ready` | about to go | announced, fading in if the host's CSS says so |
| `app` | `inert`, out of the tree a reader sees, then removed | the page |
| `failed` | the page, unharmed | gone |

Three things follow from it, and none of them is the host's to remember:

- **The engine is found, not named.** Everything that appears in the body after the boot is the
  application's, whatever this Flutter version calls it — `flutter-view` today, `flt-glass-pane`
  before it. It is marked `data-unibox-app` and given `tabindex="-1"`, which is what a host's CSS
  styles and what the reveal focuses.
- **The reveal is an accessibility event.** Focus moves into the application, one `role="status"`
  sentence (`Takeover.readyLabel`) is announced in the document's language, and only then does the
  document become `inert` and leave the page. It never happens while a reader is focused inside
  the document — on any policy, because the reveal is what takes the element away, not the boot.
- **Nothing moves for a reader who asked for less motion.** The library writes the state and a
  small rule; a host that wants a crossfade writes the transition in its own stylesheet, inside
  `@media (prefers-reduced-motion: no-preference)`.

`RevealPolicy` decides when the application is worth showing. `onFrame` (the default) shows the
engine's first frame; `onReady` waits for the application to say it has drawn the state it was
given — which `unibox_flutter` says without being asked, and which is the right answer for a page
whose scroll offset and press are being replayed. `readyTimeout` bounds either: a frame that is
available is revealed when it expires, and a page with no frame at all goes back to being a
document rather than staying blank.

### The address may narrow, and a debug build may inspect

| Parameter | Effect | Needs `Takeover(debug: true)` |
| --- | --- | --- |
| `?unibox=document` | never boot; the page stays the document | no — it can only take an application away |
| `?unibox=debug` | the marks and the two checks a host cannot see for itself | yes |
| `?unibox=profile` | the same marks as `unibox:*` performance measures and as `window.unibox.profile` | yes |
| `?unibox=compare` | keeps the document and draws the application at 50% over it | yes |

`?unibox=document` is the escape hatch an accessibility story needs: a reader who wants the text
can say so in a url they can bookmark, share or paste into a ticket, and it survives a reload.
`?unibox=compare` is the cheapest way to see whether the two renderings of one tree agree — the
takeover already *is* two renderings, so the comparison is free. `Takeover(query: false)` turns
the whole table off, including the escape hatch.

`BootPolicy` is the one choice left, and it is a choice about the page rather than about an event:
`immediately` for a screen nobody arrives at by accident, `onPointer` (the default) for an
application's front door, and `onIntent` for a page that is *shown* rather than arrived at — the
right-hand half of a comparison, a preview inside someone else's page. `onPointer`'s idle boot is
what a front door wants and the wrong thing for a frame: the frame is a window in a page the reader
came for, and the engine it starts competes with that page's own reading. `onIntent` never boots
unbidden, and it reads its signals from the top document when that is the same origin — a pointer
in the middle of the host page never reaches a frame's own window — and from the frame's own
window, so moving over the frame itself answers too.

Its signals are the ones that mean *looking*: `pointermove`, `pointerover`, `touchstart` and
`wheel`. A key, a focus move and a press are deliberately **not** signals, because the boot
replaces every element in the document: booting on a keystroke would take the page from a keyboard
reader mid-read, and a press is answered by the document, which is the accessible rendering. That
is only half a policy — a reader who never moves a pointer would be left with a document and no
application — so the frame carries **a way in**: a real `<button>`, first in its body, named by
`Takeover.openLabel` (`'Open the apartments in Flutter'`), Tab-reachable before anything else and
moved out of the page until it takes the focus, which is the skip control every reader already
knows. Pressing it boots the application and removes the control. So the application is never
unreachable, and it is never something that happens *to* a reader of the document.

The boot also waits while the frame holds the focus, and that waits for `onIntent` alone: a front
door's document is a first frame rather than the page, so its boot is not held back by a focus
someone put there while the application arrives. None of the policies boots before the first paint.

## A shaped box

`Box(shape: …)` is painted by a layer of its own: an `<svg>` over the box with one `<path>`, its
outline stretched with the box rather than fitted inside it. The fill and the stroke arrive as
custom properties (`--unibox-shape-fill`, …), because they belong to the path and not to the
element — which is what lets a hover of the box paint the shape. A box that also clips its content
carries the `clipPath` the layer writes, in bounding box units, so one outline fits whatever
element it is applied to.

The outline is not in `unibox_testing`: the table compares tokens a value can describe, and a path
is a list of commands. It is pinned by a renderer test instead.

## The takeover's own checks

`tool/lighthouse.sh` measures the exported pages against a budget, and `tool/boot_check.sh` asks a
browser whether the document becomes the application at all, serving the build under the path prefix
it was built for — the one question no byte-level check
can answer. `tool/boot_time.dart` says how long that took, in real time, because a one-shot dump
runs the page under virtual time and would report a number that means nothing.
