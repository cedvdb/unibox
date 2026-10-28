# Changelog

## Unreleased

- A new package, and the one place the web's CSS is written down. A token becomes a
  declaration here rather than in a renderer, so `unibox_html` and any renderer built
  on a web framework produce the same text for the same tree — which is what keeps a
  class name stable, since a class name is a hash of its declarations. It answers a
  colour (`#112233`, `rgba(17, 34, 51, 0.502)`, or `var(--unibox-color-primary)` for a
  role), a dimension (`8px`, `100%` for `double.infinity`), a padding or a margin in
  CSS's four-value order, and an image fit.

- `CssDeclarations` holds a list of declarations rather than a map: CSS allows a
  property to be written twice as a fallback, and `text` is the canonical spelling —
  sorted by property, insertion order within one property — that a class name is
  hashed from.
