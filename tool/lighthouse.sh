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
#   tool/lighthouse.sh                 write the documents and measure them
#   tool/lighthouse.sh build/site      measure a site that is already built
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

# A directory given as the first argument is a site that is already built — in continuous
# integration that is the one the deploy will publish: the same files, the client included.
if [ -n "${1:-}" ]; then
  if [ ! -d "$1" ]; then
    printf 'Not a directory: %s\n' "$1" >&2
    exit 2
  fi

  printf '\n==> Measuring the site at %s\n' "$1"
  cp -R "$1"/. "$WORK"/
else
  printf '\n==> Writing the documents\n'
  dart run example/unibox_example_html/bin/build_site.dart --out="$WORK"
fi

# Each page with the kind of promise it makes: a document is held to what the plan states, and a page
# that becomes an application to a floor — see `tool/lighthouse_budget.py` for why there are two.
pages="web/listings:document :application"
printf '\n==> Serving %s on %s\n' "$WORK" "$PORT"
python3 -m http.server "$PORT" --directory "$WORK" >/dev/null 2>&1 &
SERVER=$!
sleep 1

status=0

# Warm `npx` once: it resolves the package on every call otherwise, which is seconds per measurement.
npx --yes lighthouse@12 --version >/dev/null 2>&1 || true

# Unquoted on purpose: the list is space separated, one page and its kind per item.
for entry in $pages; do
  page="${entry%%:*}"
  kind="${entry##*:}"
  # The route is a path; the files are named after it without the slash.
  name="${page//\//-}@${kind}"
  url="http://127.0.0.1:$PORT/${page:+$page/}"
  printf '\n==> Measuring %s as a %s\n' "${page:-the front page}" "$kind"

  # Three samples for a promise, one for a floor: the document has to land inside 95 every time, the
  # application page only has to stay off the floor, and run-to-run spread on this machine is a third
  # of the score.
  runs="$RUNS"
  [ "$kind" = application ] && runs=1

  for run in $(seq 1 "$runs"); do
    # A profile per run: Chrome attaches to a running instance without one, and then the second run
    # waits for a browser the first is still using — a gate that hangs is a gate somebody removes.
    # `--only-categories=performance` is not a shortcut: the accessibility and best-practice
    # audits walk the whole tree and turn a twenty second measurement into a minute and a half,
    # and a gate nobody waits for is a gate nobody runs.
    if ! npx --yes lighthouse@12 "$url" \
      --output json \
      --output-path "$WORK/$name-$run.json" \
      --only-categories=performance \
      --chrome-flags="--headless=new --no-sandbox --disable-gpu --user-data-dir=$WORK/chrome-$name-$run" \
      >/dev/null 2>&1; then
      printf 'lighthouse failed to measure the %s page\n' "$page" >&2
      exit 1
    fi
  done

  if ! python3 tool/lighthouse_budget.py "$page" "$kind" "$WORK"/"$name"-*.json; then
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  printf '\n==> FAILED: a page is outside its performance budget\n' >&2
  exit 1
fi

printf '\n==> OK: every page is inside its budget\n'
