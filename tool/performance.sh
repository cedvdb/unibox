#!/usr/bin/env bash
#
# Every number this repository quotes, from one command, against a baseline.
#
# Run it when something upstream moves — a Flutter version, a Dart SDK, a package — and compare: the
# budget says "inside the line", and the baseline says "better or worse than last time". Those are
# different questions, and only the second one catches a slow drift that stays inside the budget.
#
# Usage:
#   tool/performance.sh                build the site, measure it, compare with the baseline
#   tool/performance.sh --update       rewrite the baseline with what it measured
#   tool/performance.sh build/site     measure a site that is already built
#
# What it measures, and why each one:
#   the documents     Lighthouse, budgeted — the pages a crawler and a reader both use
#   the application   Lighthouse, floored — a page that becomes Flutter, which is what a Flutter
#                     version moves most and what a budget cannot judge like a document
#   boot to frame     the takeover's own cost, in real time (`tool/boot_time.dart`)
#   the bytes         document, client, fonts and photos, so a regression has a size as well as a score
set -euo pipefail

cd "$(dirname "$0")/.."

update=0
site=""
for argument in "$@"; do
  case "$argument" in
    --update) update=1 ;;
    -h | --help)
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) site="$argument" ;;
  esac
done

step() {
  printf '\n==> %s\n' "$1"
}

if [ -z "$site" ]; then
  step 'Building the site'
  tool/site.sh >/dev/null
  site=build/site
fi

reports="${REPORTS:-build/reports}"
rm -rf "$reports"

step 'Lighthouse: the documents and the application'
REPORTS="$reports" tool/lighthouse.sh "$site"

step 'The takeover: boot to first frame'
MEASURE=1 tool/boot_check.sh "$site" | tee /tmp/unibox-boot-check.log

step 'The bytes'
python3 tool/performance_report.py "$site" "$reports" $([ "$update" -eq 1 ] && echo --update)
