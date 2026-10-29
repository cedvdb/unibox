#!/usr/bin/env bash
#
# What a page with thousands of nodes costs, against a baseline.
#
# `tool/performance.sh` measures the site we ship -- Lighthouse, boot to frame, bytes. This
# measures the pipeline underneath it, which Lighthouse cannot see: resolve a style, hash a
# class, plan an element, write text. The shapes, and what each one catches, are in
# PERFORMANCE.md.
#
# Usage:
#   tool/scale.sh              measure, then compare with the baseline
#   tool/scale.sh --update     measure, and accept it as the new baseline
#
# It runs in CI on every pull request: it is pure Dart, takes a few seconds, and it is the
# only check in the repository that fails when a big page gets slower.
set -euo pipefail

cd "$(dirname "$0")/.."

update=0
for argument in "$@"; do
  case "$argument" in
    --update) update=1 ;;
    -h | --help)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $argument" >&2
      exit 2
      ;;
  esac
done

report="$(mktemp -t unibox-scale.XXXXXX)"
trap 'rm -f "$report"' EXIT

printf '\n==> Measuring three shapes of tree\n'
(cd packages/unibox_html && dart run tool/bench.dart --json) >"$report"

if [ "$update" -eq 1 ]; then
  printf '\n==> Accepting the measurement as the baseline\n'
  python3 tool/scale_check.py "$report" --update
else
  printf '\n==> Against the baseline\n'
  python3 tool/scale_check.py "$report"
fi
