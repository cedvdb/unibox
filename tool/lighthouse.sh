#!/usr/bin/env bash
#
# Measures the exported pages the way a reader on a slow phone meets them.
#
# The claim this repository makes is that a Flutter screen can be a page a crawler reads and a
# reader can use. A claim about how fast that page arrives has to be a number, and a number
# that is not checked is a number nobody trusts -- so this runs Lighthouse against the real
# export and fails a budget rather than printing a report.
#
# Usage:
#   tool/lighthouse.sh                 measure the exported pages
#   PORT=9000 tool/lighthouse.sh       serve on another port
#
# Needs `dart`, `python3` and `node` (Lighthouse runs through `npx`). It is not part of
# `tool/verify.sh` because it starts a browser: it belongs to a slower job, not to the fast
# loop a change is committed in.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT="${PORT:-8123}"
WORK="$(mktemp -d)"

# Three runs, and the median of each metric. One run on a busy machine spread from 72 to 100
# on the same page; the median is the page's capability, the spread is the machine's, and a
# budget that fails a build at random is a budget somebody switches off.
RUNS=3

cleanup() {
  kill "${SERVER:-0}" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT

printf '\n==> Writing the documents\n'
dart run example/unibox_example_site/bin/build_site.dart --out="$WORK"

# The site's routes, which is where the example lives: `web/listings/` and `web/signup/`.
printf '\n==> Serving %s on %s\n' "$WORK" "$PORT"
python3 -m http.server "$PORT" --directory "$WORK" >/dev/null 2>&1 &
SERVER=$!
sleep 1

status=0

for page in web/listings web/signup; do
  # The route is a path; the files are named after it without the slash.
  name="${page//\//-}"
  printf '\n==> Measuring %s\n' "$page"

  for run in $(seq 1 "$RUNS"); do
    # `--only-categories=performance` is not a shortcut: the accessibility and best-practice
    # audits walk the whole tree and turn a twenty second measurement into a minute and a half,
    # and a gate nobody waits for is a gate nobody runs.
    if ! npx --yes lighthouse@12 "http://127.0.0.1:$PORT/$page/" \
      --output json \
      --output-path "$WORK/$name-$run.json" \
      --only-categories=performance \
      --chrome-flags="--headless=new --no-sandbox --disable-gpu" >/dev/null 2>&1; then
      printf 'lighthouse failed to measure the %s page\n' "$page" >&2
      exit 1
    fi
  done

  if ! python3 tool/lighthouse_budget.py "$page" "$WORK"/"$name"-*.json; then
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  printf '\n==> FAILED: a page is outside its performance budget\n' >&2
  exit 1
fi

printf '\n==> OK: every page is inside its budget\n'
