# Releasing Unibox

Five packages live in this workspace. Four are meant for pub.dev — `unibox_core`,
`unibox_flutter`, `unibox_html` and `unibox_material` — and `unibox_testing`
stays development only, because it is the test contract and nothing an application
needs.

Every package carries `publish_to: none` on purpose: it keeps an accidental
`dart pub publish` from leaving the workspace. Cutting a release therefore starts
by deleting that line, which is the one step that cannot be automated.

## Before cutting one

All of this has to be true, and it is what continuous integration checks on every
push:

```shell
flutter pub get
dart format --output=none --set-exit-if-changed .
dart analyze
(cd packages/unibox_core && dart test)
(cd packages/unibox_testing && dart test)
(cd packages/unibox_material && dart test)
(cd packages/unibox_html && dart test)
(cd packages/unibox_flutter && flutter test)
(cd example/unibox_example_shared && dart test)
(cd example/unibox_example_html && dart test)
(cd example/unibox_example_flutter && flutter test)
(cd packages/unibox_core && dart doc --output=/tmp/doc-core)
(cd packages/unibox_material && dart doc --output=/tmp/doc-material)
(cd packages/unibox_flutter && dart doc --output=/tmp/doc-flutter)
(cd packages/unibox_html && dart doc --output=/tmp/doc-html)
```

## The steps

1. **Pick the version.** The four packages move together: `unibox_flutter`,
   `unibox_html` and `unibox_material` depend on `unibox_core`, and their `^0.1.0`
   constraints have to admit the new number.
2. **Bump `version:`** in `packages/unibox_core/pubspec.yaml`,
   `packages/unibox_flutter/pubspec.yaml`, `packages/unibox_html/pubspec.yaml` and
   `packages/unibox_material/pubspec.yaml`, and the matching `unibox_core: ^x.y.z`
   constraints in the three dependants.
3. **Check the changelogs.** Each one describes the package as it stands under a
   single `## x.y.z` heading — `0.1.0` today — with no `## Unreleased` section to
   close, because nothing has been published yet. From the second release on, add a
   new section above the released one, written as what changed for the user rather
   than which file changed.
4. **Remove `publish_to: none`** from the four packages being published. Leave it
   in `unibox_testing`.
5. **Dry run each package**, in dependency order:

   ```shell
   (cd packages/unibox_core && dart pub publish --dry-run)
   (cd packages/unibox_flutter && dart pub publish --dry-run)
   (cd packages/unibox_html && dart pub publish --dry-run)
   (cd packages/unibox_material && dart pub publish --dry-run)
   ```

   The dry run is also the only check that the published archive holds what it
   should: `dart pub publish` refuses a package whose `README`, `CHANGELOG` or
   `LICENSE` is missing, and warns about files that should not ship.
6. **Publish in the same order**, so a renderer or the material package never
   depends on a core version that is not on pub.dev yet.
7. **Tag** the repository with the version and push the tag.

## What this repository does not do

- **CI never publishes.** The workflow checks formatting, analysis, the eight test
  suites and the documentation; publishing is a human running the steps above.
- **`unibox_testing` is not released.** It is a dev dependency of the two
  renderer packages and would only add a fifth name to keep in step.
- **The example is not released.** It is a workspace application, not a package.

## Version policy

`design.md` §5.7 has the rules: additions are minor, and renames and removals are
breaking and made outright — the one consumer is this repository, so there is no old
spelling to keep. Every published change is listed in the package `CHANGELOG.md`:
before the first release the section describes the package as a whole, and after it
each release gets its own section.
