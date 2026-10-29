# Contributing to Unibox

Thanks for wanting to help. Unibox is a small repository with a narrow promise — one
Dart tree, drawn by Flutter and rendered as a page a crawler can read — and most of what
follows exists to keep that promise worth something: **the two renderings agree, and a
test says so.**

If you only read two documents, read this one and
[`AGENTS.md`](AGENTS.md). The second is written for coding agents, and it is the most
precise description of the repository that exists; humans read it too.

## What is welcome

| | |
| --- | --- |
| **A bug report** | a tree and what each target did with it. The smaller the repro, the faster it lands. |
| **A parity fix** | Flutter and HTML disagree about a token. Start at the table, not at the renderer. |
| **A new token or node** | open an issue first: the cost is on both renderers, the contract and the docs, and it is worth agreeing on the shape before it is written twice. |
| **The example** | the site is the argument for the library, so a clearer demonstration is a real contribution. |
| **Docs** | a paragraph that made you understand something is a paragraph worth having. |
| **Performance** | the measure is `tool/lighthouse.sh`, and a page outside its budget fails CI. |

Not in scope, at least not without a human asking: releasing (version bumps, publishing,
closing a changelog — see [`RELEASE.md`](RELEASE.md)) and new dependencies in
`unibox_core`, which has none deliberately.

## Get set up

```shell
git clone https://github.com/cedvdb/unibox
cd unibox
flutter pub get          # one resolution: it is a Dart workspace
tool/verify.sh           # format, analysis, every suite
```

CI uses Flutter 3.47.5 stable; an older `dart` will fail on the language version in
`pubspec.yaml`. Nothing else is required — no code generation, no build step, no
services.

## The loop

```shell
(cd packages/unibox_html && dart test)   # one suite, while you work
tool/verify.sh --fast                    # format and analysis, seconds
tool/verify.sh                           # the gate, before a commit
```

`tool/verify.sh --docs` adds `dart doc`, and it is not optional when you touched a
public member or a README: a `dart doc` warning fails CI, and prose like `[Box]` instead
of `` `Box` `` is the usual cause.

The fast loop also runs `python3 tool/check_docs.py`, which fails when a document links to
a file that is not there or a package is missing its README or changelog. If you moved a
file, that check tells you what still says the old name.

## What "done" means

A change is finished when all of these are true. Half of a change is not a smaller
change, it is a broken one — the tests will tell you, which is the point.

- **A token** has a case in [`packages/unibox_testing`](packages/unibox_testing) that
  isolates it, and a place in the "every token at once" case. Both renderer suites read
  that table, so a token without one is a token nobody checks.
- **A node** has a test on both targets, and a validation rule when it only makes sense
  in one place.
- **Both renderers** draw it. A look that exists on one target is the drift this
  repository exists to prevent.
- **Every public member has a doc comment**, and the docs that describe the behaviour you
  changed are updated in the same commit: the `README.md` tables, the package README, and
  a bullet under `## Unreleased` in each `CHANGELOG.md` you touched.
- **`tool/verify.sh` passes.**

`AGENTS.md` has the file-by-file recipe for each kind of change (a `Box` token, a
typography token, a node type, a renderer difference, a stateful node, an overlay). It is
longer than this page because it is the complete list, and it is the fastest path from
"I want to add X" to a green branch.

## Style

- `tool/verify.sh --fix` formats; never hand-format.
- Prose is British English (`colour`, `behaviour`); identifiers are American
  (`BoxColor`, `backgroundColor`) because they are the API.
- A comment explains *why* — a constraint, a browser quirk, a decision that looks wrong
  until you know the reason. A comment that narrates the code is noise, and a comment
  about the author rather than the code does not belong in the repository at all.
- A test reads as a sentence about behaviour — `'keeps a gap between two children'` —
  and pins a decision. A test that restates the implementation is not worth adding.
- The example is written with the library, not around it: if a layout is easier in a
  host, the host is doing something the tree should do.

## Commits and pull requests

[Conventional Commits](https://www.conventionalcommits.org), one verified change per
commit, scoped by package:

```text
feat(core): let a box wear several style bags
fix(html): clip a rounded box to its radius
test(conformance): hold both renderers to the transform
docs: describe the style bags
```

The scope is the package that owns the change — `core`, `flutter`, `css`, `element`,
`html`, `dom`, `conformance`, `material`, `example` — or none for docs. The subject is a
lowercase phrase about what changed for the user, without a full stop.

In a pull request, the checklist in the template is the definition of done above. What a
reviewer looks for, in order: **does it land on both targets**, is there a case in the
table, does the diff contain anything the change did not need. Unrelated reformatting or
renaming hides the real diff and will be asked to move to its own commit.

While the library is unreleased, a rename or a removal is allowed — say so in the
changelog, and say what replaced it.

## Getting unstuck

- A parameter that is not in `README.md` and not in
  `packages/unibox_core/lib/src/` does not exist. That single fact resolves most
  confusion about this library, for people and for assistants.
- `example/unibox_example_shared/lib/` is a complete application in plain Dart: a
  navigation bar, a list, a form and a dialog. Reading one real tree beats reading about
  trees.
- Open an issue with the tree you tried and what each target did. On a parity question,
  paste the two outputs; the difference is usually one declaration.
