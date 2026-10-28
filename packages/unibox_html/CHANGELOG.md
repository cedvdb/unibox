# Changelog

## Unreleased

- A new package: the web renderer, pure Dart with no dependencies, so a document can be
  produced in a server, in a build step, in a CLI, or compiled to JavaScript for a host
  whose backend is not Dart.

- Escaping first, because it is the only place a string renderer can be unsafe:
  `escapeText` for content, `escapeAttribute` for a double-quoted attribute, and `safeUrl`
  for an `href` or a `src`, which turns a `javascript:` or `vbscript:` URL into `#` — the
  scheme arrives from data, never from the tree. `isRiskyUrl` is public so a validator can
  report such a tree rather than only patching what it renders.
