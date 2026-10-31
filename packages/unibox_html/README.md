# unibox_html

The web renderer: a Unibox tree as HTML a search engine can read.

A Flutter screen is a canvas, which a crawler, a link preview and a reader without
JavaScript all see as nothing. This package renders the same tree as a document — real
text, real headings, real links, one stylesheet — with no framework and no runtime.

Pure Dart, no dependencies. A document can be rendered in a server, in a build step, in a
command line tool, and, for a host whose backend is not Dart, compiled to JavaScript.

## What it answers

| Question | Answer |
| --- | --- |
| a tree as a fragment | `toHtml(tree)`, or `tree.toHtml()`, with the one `<style>` element in front of it |
| a tree as a page | `toDocument(head: DocumentHead(title: …), lang: …)` — the fragment, a `<head>` and the stylesheet |
| a page in one language of several | `toDocument(lang: …, head: DocumentHead(alternates: …))` — the language it is written in, and the `hreflang` links that pair it with its translations |
| a page an application takes over | `toDocument(takeover: Takeover(boot: …))` — the bundle prefetched, the recorders, the boot on a signal |
| what a document is | a snapshot of a state: initial state, overlays open, no listeners |

## The head

A tree describes a region of a page, so the page's own title, address and translations belong
to the host. They arrive as one value, `DocumentHead`, beside the tree:

```dart
final String page = toDocument(
  tree,
  lang: 'de',
  head: const DocumentHead(
    title: 'Wohnungen in Amsterdam',
    description: 'Einundvierzig Wohnungen zur Miete.',
    image: 'https://example.com/cards/amsterdam.jpg',
    canonical: 'https://example.com/de/apartments/',
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
| `prefetch` | `<link rel="prefetch" as="script">` | a bundle the page is likely to ask for |
| `raw` | verbatim | markup this package does not describe |

`DocumentHead.raw([…])` is the shorthand for a host that only has the last one to say.

Everything but `raw` is escaped, and every url goes through `safeUrl`, so a title or a canonical
address that came from data cannot end the element it is written into. `raw` is the door for the
`@font-face` rules of the font a host ships, a dark-mode block and structured data: it is written
verbatim, which is why it is the host's own text and never a string assembled from what a reader
supplied.

`lang` is not part of the value, because it is an attribute of the root element rather than a head
element. The renderer owns the order — the metadata and the prefetches before the stylesheet, the
stylesheet before `raw` — so a fetch starts with the document, a host rule of equal specificity
can restate what the page starts with, and a font face still arrives before the text that uses it.

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
  lang: 'de',
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
| the language it is written in | `lang:` — one document per language, not one page that swaps its text |
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

## The element plan

`ElementPlan` is the whole decision of what a tree becomes, as a value: a tag, its
attributes in a fixed order, the class it wears, and the elements inside it. It carries no
markup, so `toHtml()` writes it to a string and a DOM renderer could build nodes from the
same value — which is what would let a client renderer adopt a server's page instead of
repainting it. It is decided here, once, before a second renderer exists to disagree.

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
| `bootScript(url, policy:)` | loads the application on a signal, never before the first paint |
| `uniboxClientScript` | both recorders, for a host that wants one file |

`Takeover` is how a page asks for all of it at once:

```dart
final String page = toDocument(
  ListingsPage(listings),
  head: const DocumentHead(title: 'Apartments'),
  takeover: const Takeover(boot: '../../flutter/app.js'),
);
```

It prefetches the loader at a low priority — deferring the download as well as the execution is
how a page gets a good score and a two-second dead click — and places the recorders before the
boot, because the application asks what the reader did. `record: false` is for a page that only
has to boot.

`BootPolicy` is the one choice left, and it is a choice about the page rather than about an event:
`immediately` for a screen nobody arrives at by accident, `onPointer` (the default) for an
application's front door. Neither boots before the first paint.

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
