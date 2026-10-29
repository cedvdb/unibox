# Claude Code instructions

The instructions for this repository live in [AGENTS.md](AGENTS.md). Read it before
editing: it holds the architecture rules, the repository map, the verification
command and the touch points for a change that spans core and both renderers.

The three rules that are broken most often:

- `packages/unibox_core` never imports `dart:ui`, Flutter or a web framework, and has no
  package dependencies at all.
- A change lands on both targets. `packages/unibox_testing` is the single place
  where the expected appearance of a token is written down, and both renderer
  suites are checked against it.
- `tool/verify.sh` runs what CI runs: the format check, `dart analyze` and every suite.
  A `dart doc` warning also fails CI, so every public member keeps a doc comment.

Do not publish or bump a version unless asked.
