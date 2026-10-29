# Copilot instructions

The instructions for this repository live in [AGENTS.md](../AGENTS.md). Read it
before suggesting or editing code: it holds the architecture rules, the repository
map, the verification command and the touch points for a change that spans core and
both renderers.

In short:

- `packages/unibox_core` is pure Dart: no `dart:ui`, no Flutter, no web framework, no
  package dependencies.
- Every presentational change lands on both targets, pinned by a case in
  `packages/unibox_testing`. Neither renderer may fall back to its host's
  default for a token the model leaves unset.
- `tool/verify.sh` is the gate: format check, `dart analyze`, every test suite,
  and with `--docs` the API docs, which fail on a warning.
- Conventional Commits, one verified change per commit. No version bumps and no
  publishing unless asked.
