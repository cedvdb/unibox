#!/usr/bin/env bash
#
# Verifies the workspace the way continuous integration does: the format check,
# the analysis of every package, and each test suite. One command, so a change is
# never described as done before it has been run.
#
# Usage:
#   tool/verify.sh            format check, analysis, the documentation check, every suite
#   tool/verify.sh --fast     format check and analysis only
#   tool/verify.sh --fix      format the tree, then verify
#   tool/verify.sh --docs     also build the API docs of every package
#
# The first failing step stops the script and names itself.
set -euo pipefail

cd "$(dirname "$0")/.."

run_tests=1
build_docs=0
fix_format=0

for argument in "$@"; do
  case "$argument" in
    --fast) run_tests=0 ;;
    --docs) build_docs=1 ;;
    --fix) fix_format=1 ;;
    -h | --help)
      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $argument" >&2
      exit 2
      ;;
  esac
done

step() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf '\n==> FAILED: %s\n' "$1" >&2
  exit 1
}

# The version is written in one file — `.flutter-version`, which the workflows read too — so a
# local run and a CI run cannot disagree about it. This is checked before anything else because of
# the failure it prevents: a tree that is green in CI and red on a laptop sends a reader after a
# bug that does not exist, and the cheapest wrong fix available to anyone, human or assistant, is
# to loosen `environment.sdk` until the red goes away.
#
# The version is read out of wherever it appears in the output rather than off the first line: the
# tool prints "Building flutter tool..." or a lock message first when it is busy, and a check that
# answered "no Flutter" for that would send the reader after the wrong thing entirely.
step 'Checking the Flutter version'
expected_flutter="$(tr -d '[:space:]' < .flutter-version)"
version_output="$(flutter --version 2>&1 || true)"
actual_flutter="$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<< "$version_output" | head -n 1 || true)"
if [ -z "$actual_flutter" ]; then
  printf '  `flutter --version` printed nothing this check could read:\n\n%s\n\n' "$version_output" >&2
  fail 'could not read a Flutter version — is the Flutter tool installed and on PATH?'
fi
if [ "$actual_flutter" != "$expected_flutter" ]; then
  printf '  .flutter-version says %s; this machine has %s\n' \
    "$expected_flutter" "$actual_flutter" >&2
  printf '  That is the environment, not your change. Install %s; do not edit the SDK constraint.\n' \
    "$expected_flutter" >&2
  fail "the Flutter version (expected $expected_flutter, from .flutter-version)"
fi
printf '  %s\n' "$actual_flutter"

step 'Resolving the workspace'
flutter pub get || fail 'flutter pub get'

if [ "$fix_format" -eq 1 ]; then
  step 'Formatting'
  dart format . || fail 'dart format'
else
  step 'Checking formatting'
  dart format --output=none --set-exit-if-changed . || fail 'dart format --set-exit-if-changed'
fi

step 'Analyzing'
dart analyze || fail 'dart analyze'

# Cheaper than the suites and worth more than most of them: an index that points at a
# renamed file sends a reader -- or an assistant, which believes indexes -- into a package
# that is gone.
step 'Checking the documentation'
python3 tool/check_docs.py || fail 'tool/check_docs.py'

# The table is checked from the inside by `test/cases_test.dart`; this checks it from the outside, and
# it is the check a reviewer used to supply. A token that reaches the source without a place in the
# table is a token neither renderer suite compares -- and an assistant adding one will not notice.
step 'Checking the surface'
python3 tool/surface_check.py || fail 'tool/surface_check.py'

# The checkers are code too, and were the only code here without tests: a gate that silently stops
# gating is worse than no gate, because the green tick is a lie.
step 'Checking the gates'
python3 tool/gate_tests.py || fail 'tool/gate_tests.py'

if [ "$run_tests" -eq 1 ]; then
  # `dart test` for the pure Dart packages, `flutter test` for the two that build
  # widgets. The order is the dependency order CI uses.
  while IFS='|' read -r directory command; do
    step "Testing $directory"
    # `$command` is split on spaces on purpose: a row is a whole command line, and the DOM suite
    # is the one that needs a platform flag.
    if ! (cd "$directory" && $command); then
      fail "$command in $directory"
    fi
  done <<'SUITES'
packages/unibox_core|dart test
packages/unibox_testing|dart test
packages/unibox_material|dart test
packages/unibox_css|dart test
packages/unibox_element|dart test
packages/unibox_html|dart test
packages/unibox_dom|dart test -p chrome
packages/unibox_flutter|flutter test
example/unibox_example_shared|dart test
example/unibox_example_html|dart test
example/unibox_example_flutter|flutter test
SUITES
fi

if [ "$build_docs" -eq 1 ]; then
  # dartdoc reports a problem as a warning and still exits 0, which is why CI
  # reads the log as well; a public member without a doc comment has to fail here.
  for package in unibox_core unibox_testing unibox_material unibox_css unibox_element unibox_html unibox_dom unibox_flutter; do
    step "Documenting $package"
    output="$(mktemp -d)/docs"
    log="$(mktemp)"

    if ! (cd "packages/$package" && dart doc --output "$output") >"$log" 2>&1; then
      cat "$log"
      fail "dart doc in packages/$package"
    fi

    if grep -q 'warning:' "$log"; then
      cat "$log"
      fail "dart doc reported warnings in packages/$package"
    fi

    cat "$log"
  done
fi

printf '\n==> OK: the workspace verifies\n'
