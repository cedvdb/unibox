#!/usr/bin/env bash
#
# Checks that the takeover page actually boots the application.
#
# Every other check in this repository reads the bytes a build produced. This one is the only
# one that asks a browser what happened: a document that serves correctly and then fails to
# boot is a page a crawler reads and a reader cannot use, and nothing in a Lighthouse score can
# see it, because Lighthouse never clicks.
#
# It writes a probe document beside the takeover pages — same depth, so the same relative path
# to the loader — loads it in headless Chrome, and looks for the element Flutter paints into.
# The probe exists for the length of the run and is deleted afterwards.
#
# Usage:
#   tool/boot_check.sh build/site
#   PORT=9100 tool/boot_check.sh build/site
set -euo pipefail

site="${1:-build/site}"
port="${PORT:-8765}"
probe="$site/web/boot-check/index.html"

if [ ! -d "$site/flutter" ]; then
  printf 'No build at %s: run tool/site.sh first.\n' "$site" >&2
  exit 1
fi

chrome=""
for candidate in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "google-chrome" \
  "chromium" \
  "chromium-browser"; do
  if command -v "$candidate" >/dev/null 2>&1; then
    chrome="$candidate"
    break
  fi
  if [ -x "$candidate" ]; then
    chrome="$candidate"
    break
  fi
done

if [ -z "$chrome" ]; then
  printf 'No Chrome or Chromium: the boot check needs a browser.\n' >&2
  exit 1
fi

mkdir -p "$(dirname "$probe")"
cat >"$probe" <<'PROBE'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <!-- The loader the takeover documents use, at the same depth, booted at once: a headless
       browser never moves a pointer, so intent-based booting cannot be tested this way. -->
  <script>
    (function () {
      var element = document.createElement('script');
      element.src = '../../flutter/app.js';
      document.head.appendChild(element);
    })();
  </script>
</head>
<body><p>A probe for the boot, not a page of the site.</p></body>
</html>
PROBE

cleanup() {
  rm -f "$probe"
  rmdir "$(dirname "$probe")" 2>/dev/null || true
  kill "${SERVER:-0}" 2>/dev/null || true
  # Reaped, so the shell does not report the job it just ended.
  wait "${SERVER:-0}" 2>/dev/null || true
  rm -rf "$work"
}
work="$(mktemp -d)"
trap cleanup EXIT

python3 -m http.server "$port" --directory "$site" >/dev/null 2>&1 &
SERVER=$!
sleep 1

printf '\n==> Booting the application in a headless browser\n'

if ! "$chrome" --headless=new --disable-gpu --no-sandbox \
  --virtual-time-budget=40000 \
  --dump-dom "http://127.0.0.1:$port/web/boot-check/" >"$work/dom.html" 2>"$work/chrome.log"; then
  printf 'Chrome could not load the probe:\n' >&2
  cat "$work/chrome.log" >&2
  exit 1
fi

if ! grep -q 'flt-glass-pane\|flutter-view' "$work/dom.html"; then
  printf '\nFAILED: the document did not become the application.\n' >&2
  printf 'The DOM the run ended with is in %s, and its head:\n' "$work/dom.html" >&2
  head -c 400 "$work/dom.html" >&2
  printf '\n' >&2
  exit 1
fi

printf '\n==> The document boots: Flutter painted into it.\n'
