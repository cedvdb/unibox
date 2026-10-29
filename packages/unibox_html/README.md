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
| a tree as a fragment | `toHtml()` |
| a tree as a page | `toDocument(title: …, lang: …)` — the fragment, a `<head>` and the stylesheet |
| a page an application takes over | `toDocument(takeover: Takeover(boot: …))` — the bundle prefetched, the recorders, the boot on a signal |
| what a document is | a snapshot of a state: initial state, overlays open, no listeners |

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

## The element plan

`ElementPlan` is the whole decision of what a tree becomes, as a value: a tag, its
attributes in a fixed order, the class it wears, and the elements inside it. It carries no
markup, so `toHtml()` writes it to a string and a DOM renderer could build nodes from the
same value — which is what would let a client renderer adopt a server's page instead of
repainting it. It is decided here, once, before a second renderer exists to disagree.

A node this renderer cannot draw throws rather than being skipped: a tree built for
another target fails loudly instead of shipping a page with a piece missing.

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
  title: 'Apartments',
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
