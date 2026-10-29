#!/usr/bin/env bash
#
# Asks whether the built site's client rendering works: serves `build/site`, presses a control with
# a real browser, and fails when the page does not answer.
#
# `tool/boot_check.sh` covers the other half — a document that becomes Flutter. Neither check can see
# the other's failure: a page whose client script throws still serves, still scores well, and still
# passes every suite, because the suites start their own browser rather than reading what a build
# produced.
#
# Usage:
#   tool/dom_check.sh build/site
#   PORT=9100 tool/dom_check.sh build/site
set -euo pipefail

site="${1:-build/site}"
port="${PORT:-8766}"
# The prefix the site was built for, recorded by `tool/site.sh`: a build for /unibox/ answers under
# that path and nowhere else.
base="${2:-}"
if [ -z "$base" ] && [ -f "$(dirname "$site")/.unibox-site-base" ]; then
  base="$(cat "$(dirname "$site")/.unibox-site-base")"
fi
base="${base:-/}"
url="http://127.0.0.1:$port${base}"

if [ ! -f "$site/web/main.client.js" ]; then
  printf 'No client rendering at %s: run tool/site.sh first.\n' "$site" >&2
  exit 1
fi

work="$(mktemp -d)"
cleanup() {
  kill "${SERVER:-0}" 2>/dev/null || true
  wait "${SERVER:-0}" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

# The layout the deploy uses, not the folder at a bare root, for the reason `tool/boot_check.sh`
# gives: a site built for /unibox/ answers /unibox/web/main.client.js.
root="$site"
case "$base" in
  /) ;;
  *)
    first="${base#/}"
    first="${first%%/*}"
    root="$work/serve"
    mkdir -p "$root"
    ln -s "$(cd "$site" && pwd)" "$root/$first"
    ;;
esac

python3 tool/serve.py "$root" "$port" >/dev/null 2>&1 &
SERVER=$!
sleep 1

printf '\n==> Pressing a control in the client rendering\n'
dart run tool/dom_check.dart "$url"
