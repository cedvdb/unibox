# Releasing Unibox

Six packages live in this workspace. Five are meant for pub.dev — `unibox_core`,
`unibox_material`, `unibox_html`, `unibox_flutter` and `unibox_material_flutter` — and
`unibox_testing` stays development only, because it is the test contract and nothing an
application needs.

Every package carries `publish_to: none` on purpose: it keeps an accidental
`dart pub publish` from leaving the workspace. `tool/publish.sh` lifts it for the run and
puts it back, so a release never leaves the guard off.

## Before cutting one

The gate is one command, and it has to pass before anything is published:

```shell
tool/verify.sh --docs
```

It runs the format check, `dart analyze`, the documentation index and the token surface
checks, every suite and `dart doc` for each package — the same steps CI runs on every push.

## Publishing from a tag

From 0.1.1 on, a tag publishes. Pub.dev accepts automated publishing only from a workflow
that a tag push triggered, and only for the version that tag names, so:

1. Bump the versions and move the changelogs (steps 1–3 below), and merge the result to
   `main`.
2. `git tag v0.1.1 && git push origin v0.1.1`.
3. `.github/workflows/publish.yml` runs the gate, then `tool/publish.sh`: every package
   whose version the tag names and pub.dev does not serve yet, in dependency order. A
   package still at an older version is skipped; one at any other version fails the run
   before anything is published.

Pub.dev is configured once per package: **Admin → Automated publishing → GitHub Actions**,
repository `cedvdb/unibox`, tag pattern `v{{version}}`. The first version of each package
was published by hand, because pub.dev cannot create a package from a workflow. A pull
request runs `tool/publish.sh --check` only: the archives are validated, nothing is sent.

## Releasing by hand

The first release — pub.dev cannot create a package from a workflow — and the fallback when
the workflow cannot run.

1. **Pick the version.** The five published packages move together: `unibox_material`,
   `unibox_html`, `unibox_flutter` and `unibox_material_flutter` depend on `unibox_core`
   (and `unibox_material_flutter` on both `unibox_material` and `unibox_flutter`), so
   their `^0.1.0` constraints have to admit the new number.
2. **Bump `version:`** in `packages/unibox_core/pubspec.yaml`,
   `packages/unibox_material/pubspec.yaml`, `packages/unibox_html/pubspec.yaml`,
   `packages/unibox_flutter/pubspec.yaml` and
   `packages/unibox_material_flutter/pubspec.yaml`, and the matching
   `unibox_core: ^x.y.z` constraints in the dependants.
3. **Move the changelogs.** Each published package carries a `CHANGELOG.md`; the first
   release folded its pre-release `## Unreleased` section into `## 0.1.0`, which is what
   `dart pub publish` checks for. From the second release on, add a new section above the
   released one, written as what changed for the user rather than which file changed.
4. **Validate, then publish**, in dependency order:

   ```shell
   tool/publish.sh --check
   tool/publish.sh v0.1.1
   ```

   `--check` runs `dart pub publish --dry-run` on each published package with the
   `publish_to: none` guard lifted. The publish run sends every package the tag names and
   pub.dev does not serve yet, waits for each version to be served before the next, and
   restores the guard whatever happens. A local publish asks for a one-time password on
   each package; the workflow does not, because it authenticates through OIDC. By hand it
   is the same list in the package directories: `unibox_core`, `unibox_material`,
   `unibox_html`, `unibox_flutter`, `unibox_material_flutter`. `resolution: workspace`
   needs no change: a member of this workspace is publishable as it stands.
5. **Tag** the repository with the version and push the tag.

## What this repository does not do

- **CI publishes only from a tag.** `.github/workflows/publish.yml` runs the gate and then
  `tool/publish.sh` when a `v*` tag is pushed; a pull request gets `tool/publish.sh --check`
  and nothing else. The version and the changelog prose stay manual, because they are the
  release notes.
- **`unibox_testing` is not released.** It is a dev dependency of the renderer packages and
  would only add a name to keep in step.
- **The example is not released.** It is a workspace application, not a package.

## Version policy

`design.md` §5.7 has the rules: additions are minor, and renames and removals are
breaking and made outright — the consumers today are Comover and this repository, and
both range `^0.x` deliberately, so there is no old spelling to keep. Every published
change is listed in the package `CHANGELOG.md`: the first release describes the package
as a whole, and after it each release gets its own section. A release is its tag: pub.dev
publishes only the version the tag names.
