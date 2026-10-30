## What this changes

<!-- One paragraph. What is different for someone using the library, not which files
moved. -->

## Where it lands

<!-- A change usually touches more than the package it starts in. Tick what applies and
say what you did on the other side. -->

- [ ] `packages/unibox_core` — a node, a token, a default or a validation rule
- [ ] `packages/unibox_testing` — the case that pins the appearance (a token without one
      is a token nobody checks)
- [ ] `packages/unibox_css` / `packages/unibox_element` — the web's mapping
- [ ] `packages/unibox_flutter` — the widgets
- [ ] `packages/unibox_html` / `packages/unibox_dom` — the document and the runtime
- [ ] `packages/unibox_material` — a role, a scale value or a component
- [ ] docs: `README.md`, the package README, `AGENTS.md`, `design.md`
- [ ] `CHANGELOG.md` under `## Unreleased` in every package touched

## Checks

- [ ] `tool/verify.sh` passes locally
- [ ] `tool/verify.sh --docs` if a public member or a README changed (a dartdoc warning
      fails CI)
- [ ] A new or changed token has a case in `unibox_testing` **and** a place in the
      "every token at once" case
- [ ] Both renderers draw it, and a test on each target says so
- [ ] No version bump and no `publish_to` change

## Notes for the reviewer

<!-- Anything that looks wrong until you know why: a browser quirk, a workaround, an
alternative you rejected. This is the most useful part of a PR description. -->
