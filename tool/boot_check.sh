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
#   tool/boot_check.sh build/site                  (the base tool/site.sh recorded)
#   tool/boot_check.sh build/site /unibox/         (stated explicitly)
#   PORT=9100 tool/boot_check.sh build/site
set -euo pipefail

site="${1:-build/site}"
port="${PORT:-8765}"
# The prefix the site was built for. Its loader and its preload are written with that prefix, so a
# directory served at / would fetch paths that do not exist there — which is what a deploy build does
# when a check assumes the default base. `tool/site.sh` records it beside the files it wrote.
base="${2:-}"
if [ -z "$base" ] && [ -f "$(dirname "$site")/.unibox-site-base" ]; then
  base="$(cat "$(dirname "$site")/.unibox-site-base")"
fi
base="${base:-/}"
url="http://127.0.0.1:$port${base}web/boot-check/"
# No milliseconds are claimed. The dump is taken under `--virtual-time-budget`, which runs the
# page's clock faster than the wall clock, so any `performance.now()` delta it produced would be
# virtual and would read as a number that looks precise and means nothing. A real duration needs a
# browser driven in real time — a driver rather than a one-shot dump — and the number that matters
# is what a reader on a phone pays, which is a question for real-user monitoring.
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
      // Boot at once: a headless browser never moves a pointer, so a page that waits for intent
      // cannot be tested this way. What is being tested is the loader's paths, not the policy.
      //
      // The mark is what `tool/boot_time.dart` reads, in real time: this page is the only place
      // that knows both the navigation and the first frame.
      var start = performance.now();

      window.addEventListener('flutter-first-frame', function () {
        document.documentElement.setAttribute(
          'data-unibox-boot-ms',
          String(Math.round(performance.now() - start))
        );
      });

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

# Serve the layout the deploy will use, not the folder at a bare root: a site built for /unibox/
# answers /unibox/flutter/main.dart.js, and a server that mounts everything at / would 404 every
# one of those fetches — a check that passes locally and fails on a deploy for the same files.
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

printf '\n==> Booting the application in a headless browser\n'

if ! "$chrome" --headless=new --disable-gpu --no-sandbox \
  --virtual-time-budget=40000 \
  --dump-dom "$url" >"$work/dom.html" 2>"$work/chrome.log"; then
  printf 'Chrome could not load the probe:\n' >&2
  cat "$work/chrome.log" >&2
  exit 1
fi

if ! grep -q 'flt-glass-pane\|flutter-view' "$work/dom.html"; then
  printf '\nFAILED: the document did not become the application.\n' >&2
  # The two things that go wrong first, named before the DOM: where the page was served from, and
  # whether the bundle it asks for answers there at all.
  printf 'Served at %s (base %s).\n' "$url" "$base" >&2
  for file in "flutter/app.js" "flutter/main.dart.js"; do
    if [ -f "$site/$file" ]; then
      code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port${base}$file" || true)"
      printf '  %s%s -> %s\n' "$base" "$file" "${code:-no answer}" >&2
    else
      printf '  %s%s -> not in the build\n' "$base" "$file" >&2
    fi
  done
  printf 'The DOM the run ended with is in %s, and its head:\n' "$work/dom.html" >&2
  head -c 400 "$work/dom.html" >&2
  printf '\n' >&2
  exit 1
fi

printf '\n==> The document boots: Flutter painted into it.\n'

# The dump above cannot time it — virtual time moves faster than the clock — so the number comes
# from a second browser driven over the DevTools protocol, in real time.
if [ "${MEASURE:-1}" = "1" ]; then
  measured="$(dart run tool/boot_time.dart "$url" 2>&1)" || measured="unavailable: $measured"
  printf '\n==> %s\n' "$measured"
fi
