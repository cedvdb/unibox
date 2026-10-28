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

## What is still to come

The emitter itself: the element plan (which element a node becomes, and in what order its
attributes are written), one function per node, the stylesheet that collects the rules
from `unibox_css`, and `toHtml()`/`toDocument()`. Then the conformance suite from
`unibox_testing`, which is what holds this renderer to the same appearance as the Flutter
one.
