# unibox_css

The CSS the web renders from.

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
| a shadow, or a list of them | `cssBoxShadow(...)`, `cssBoxShadows(...)` → `0 2px 3.31px -1px #2c2c2c`, the blur written in the unit a browser reads |
| an image fit | `cssObjectFit(...)` → `cover`, `contain`, `fill`, `scale-down` |
| a set of declarations | `CssDeclarations` — an ordered list, and its canonical `text` |
| a state, a theme | `stateRules(box, className)`, `themeDeclarations(theme)` — rules as values, `CssRule` |
| a text input | `textInputDeclarations({padding})` |
| a stack, its cell | `stackDeclarations`, `stackCellDeclarations` |
| a placed child | `positionedDeclarations`, `alignedDeclarations` |
| a text, an image, a grid | `textDeclarations`, `imageDeclarations`, `gridDeclarations` |
| a box | `boxDeclarations(style)` — the flex container, its paint, its typography |
| the typography of a box | `typographyDeclarations(style)`, and `defaultTypographyDeclarations()` |
| what a page starts from | `rootDeclarations()` — the typography of the model, and the tap highlight a touch browser would paint |
| a transform, a transition | `cssTransform`, `cssTransition` |
| a pin's edge | `cssPinEdge(...)` → `top` for `BoxPin.start`, `bottom` for `BoxPin.end` |
| a fold | `foldKeyframes(style)` → a `CssKeyframes` value, and `foldDeclarations(style)` → the `animation-*` that runs it on `view()` |

`CssDeclarations` is a list and not a map because CSS allows a property to be written
twice — a fallback — and because `text` is the text a class name is hashed from, which
has to be the same however the renderer built it.

## The class a look wears

`fnv1a` hashes a set of declarations into the eight characters of a class name, so two
boxes with the same look share one rule and six listings cost one class. The stylesheet
that collects those rules is `unibox_html`'s job, not this package's: a rule is a value
here (`CssRule`), and writing it into a `<style>` block or into a stylesheet is a
renderer's decision.
