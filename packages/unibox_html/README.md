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

## What is still to come

Grid, stack and positioned nodes, the text input, the overlay (drawn open) and a
`StatefulNode` (its initial state); the container queries a width threshold needs;
`toDocument()` with a typed head; and the conformance suite from `unibox_testing`, which
is what holds this renderer to the same appearance as the Flutter one.
