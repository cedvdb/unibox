# unibox_css

The CSS that two web renderers share.

A token is a Dart value in `unibox_core`; CSS is text. This package is the single
place where one becomes the other, so `unibox_html` and any renderer built on a web
framework produce the same declarations for the same tree.

That is not tidiness. A class name is a hash of its declarations, which is what makes
six listings with one look cost one rule. Two mappings that disagreed would give one
look two class names, and a host stylesheet or a dark-mode block written against one
page would stop applying to the other — the exact drift this repository exists to
prevent.

Pure Dart, no dependencies, no `dart:ui`. It can run in a server, in a build step, in
a CLI, and — for a host whose backend is not Dart — compiled to JavaScript beside the
renderer that consumes it.

## What it answers

| Question | Answer |
| --- | --- |
| a dimension | `cssLength(width)` → `8px`, `100%` for `double.infinity`, `null` when unset |
| a padding or a margin | `cssSpacing(...)` → `8px`, or `8px 12px 16px 4px` in CSS's order |
| a colour | `cssColor(...)` → `#112233`, `rgba(17, 34, 51, 0.502)` |
| a colour that names a role | `cssRoleReference(...)` → `var(--unibox-color-primary)` |
| an image fit | `cssObjectFit(...)` → `cover`, `contain`, `fill`, `scale-down` |
| a set of declarations | `CssDeclarations` — an ordered list, and its canonical `text` |

`CssDeclarations` is a list and not a map because CSS allows a property to be written
twice — a fallback — and because `text` is the text a class name is hashed from, which
has to be the same however the renderer built it.

## What is still to come

The package grows family by family: the box's layout and paint declarations, the
typography, the four state rules (`:hover`, `:focus-visible`, `:active`,
`[aria-disabled="true"]`), and the `:root` block of the model's defaults. Until a
family is here, the renderer that needs it is not finished either — which is on
purpose: half a mapping is how two renderings start to differ.
