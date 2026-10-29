# Maintaining Unibox

The repository is built to be maintained by one person with a spare hour a month, and by
an assistant working inside the same rules. This page is that hour: what runs on its own,
what a human decides, and what to do when something is red.

If you are an assistant asked to do maintenance work, read [`AGENTS.md`](AGENTS.md) first
— it holds the architecture rules and the file-by-file recipes — then work from the
routine below, and stop where it says a human decides.

## What runs without anyone

| | |
| --- | --- |
| `ci.yml` | format, analysis, every suite, the API docs, the performance budget and the scale benchmark, on every push and pull request |
| `weekly.yml` | the same gate on a cold cache, every Monday — because a dependency, Chrome or a cached artefact can break a green branch with no commit behind it |
| `pages.yml` | rebuilds and publishes the site on every push to `main` |
| `dependabot.yml` | one grouped pull request a week for dependencies, one a month for actions; each runs the full gate like any other change |
| `tool/check_docs.py` | runs in the fast loop, so a renamed file cannot leave an index pointing at nothing |

Nothing merges itself. A dependency bump is a change: `packages/unibox_testing` compares
the two renderings, so a version that changes what a box looks like fails the gate before
anyone ships it.

## The monthly hour

```shell
git switch main && git pull
tool/maintenance.sh          # the gate, the budget, and the numbers the README quotes
```

Then, from what it printed:

1. **A red gate.** Fix it in its own commit, with the reason in the message. If a check is
   genuinely expected to fail — a flaky budget, a browser that moved — say so in the same
   commit rather than loosening the budget silently. A gate somebody switches off is worse
   than no gate.
2. **The weekly issue.** If `maintenance: the weekly gate is red` is open, it is the same
   job as above; close it with the commit that fixed it.
3. **Dependabot.** Read the diff, not the CI badge: a `pubspec.lock` diff is the whole
   change, and the interesting part is a major version. Merge when green; if a major needs
   code changes, do it in a commit of its own.
4. **The numbers in the README.** The client's size (`67 KB`), the Flutter build's
   (`718 KB`) and the page budgets are measurements, and `tool/maintenance.sh` prints the
   current ones. A quoted number that no longer matches is a lie in the shop window —
   update the README in the same commit as the change that moved it.
5. **Issues.** A parity report with a tree in it is usually a case missing from
   `packages/unibox_testing`: write the case there first, watch both suites, and fix the
   renderer that disagrees. That order is in
   [`AGENTS.md`](AGENTS.md#d-a-difference-between-the-two-renderers).
6. **The `Deferred` list** in [`TASK_PLAN.md`](TASK_PLAN.md). Nothing on it is a bug; it is
   work deliberately not done. Do not start one because it is the oldest item.

## What a human decides

These are not automatable, and an assistant should stop and ask rather than decide:

- **Releasing** — a version bump, `publish_to: none` off, closing a changelog. See
  [`RELEASE.md`](RELEASE.md).
- **A new dependency**, anywhere. `unibox_core` has none and keeps none; a renderer takes
  one only when its host cannot do the job otherwise, and never on the other renderer.
- **A new workspace package**, which also means the root `pubspec.yaml` workspace list,
  `tool/verify.sh`, `ci.yml` and `llms.txt`.
- **Removing something a user can see** — a node, a token, a public spelling. While the
  library is unreleased a rename is allowed; say so in the changelog, and say what
  replaced it.
- **The `Deferred` list**, unless a human asks for an item by name.

## Handing a task to an assistant

The prompt that works is specific about the gate, because the gate is what makes an
automated change reviewable:

```text
Read AGENTS.md, CONTRIBUTING.md and the README section for <the node or token> before
editing. Make one change: <what>. It lands on both targets — the Flutter widget and the
web mapping — with a case in packages/unibox_testing, a doc comment on every public
member, and a bullet under "## Unreleased" in each CHANGELOG.md touched. Run
tool/verify.sh (add --docs if a public member or a README changed) and do not commit
until it passes. Conventional Commits, one verified change per commit. Do not bump a
version, do not publish, and do not implement anything from the Deferred section of
TASK_PLAN.md.
```

Two habits that keep its output reviewable: **one change per commit**, and **the failing
test first** — a parity fix written from the table outwards is a fix; a renderer patched
until the suite goes green is a coincidence.

## Where the knowledge is

| Question | Read |
| --- | --- |
| Why is the model shaped this way? | [`design.md`](design.md) |
| What has to be touched for a change? | [`AGENTS.md`](AGENTS.md) — one recipe per kind of change |
| What is built, and what was left out? | [`TASK_PLAN.md`](TASK_PLAN.md) |
| How is a release cut? | [`RELEASE.md`](RELEASE.md) |
| What does a token look like on each target? | the package READMEs, and `packages/unibox_testing/lib/src/` |
