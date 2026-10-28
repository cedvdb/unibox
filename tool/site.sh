#!/usr/bin/env bash
#
# Builds the static site: the documents `unibox_html` writes, the Flutter build of the same
# tree, and one landing page that shows them side by side.
#
# Usage:
#   tool/site.sh                          # for http://localhost:8000/
#   tool/site.sh --base=/unibox/          # the path GitHub Pages serves from
#   tool/site.sh --url=https://…/unibox/  # adds a sitemap for that address
#   tool/site.sh --serve                  # builds, then serves build/site
#
# Everything lands in build/site, which is the directory a static host publishes.
set -euo pipefail

cd "$(dirname "$0")/.."

base='/'
url=''
serve=0

for argument in "$@"; do
  case "$argument" in
    --base=*) base="${argument#--base=}" ;;
    --url=*) url="${argument#--url=}" ;;
    --serve) serve=1 ;;
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

# A base href has to start and end with a slash, the rule Flutter states too.
[[ "$base" == /* ]] || base="/$base"
[[ "$base" == */ ]] || base="$base/"

root="$(pwd)"
site="$root/build/site"

step() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf '\n==> FAILED: %s\n' "$1" >&2
  exit 1
}

step 'Resolving the workspace'
flutter pub get || fail 'flutter pub get'

step 'Rendering the pages'
# The site is one node tree and the example is another; one script writes all of
# their documents, so the site and the app cannot disagree about a path. The commit is
# asked for once and written into every document, so a stale tab can be told from a
# live page without reading CSS class hashes.
build="$(git -C "$root" rev-parse HEAD 2>/dev/null || true)"
rm -rf "$site"
(cd example/unibox_example_site &&
  dart run bin/build_site.dart --out="$site" ${build:+--build="$build"}) \
  || fail 'the site render'

step 'Building the Flutter web app'
# The service worker is off on purpose: a demo that caches its own old build is
# worse than one that downloads again.
(cd example/unibox_example_flutter && flutter build web \
  --base-href "${base}flutter/" \
  --pwa-strategy=none) || fail 'flutter build web'

step 'Assembling the site'
mkdir -p "$site/flutter" "$site/assets/fonts"
# The same four faces the Flutter app bundles, so a weight is drawn on both sides.
cp example/unibox_example_flutter/assets/fonts/*.ttf "$site/assets/fonts/"
cp -R example/unibox_example_flutter/build/web/. "$site/flutter/"

# A static host has no rewrite rule, so a Flutter route is a real file. The build's
# absolute base href is what lets the copied document resolve its assets from a
# deeper path. The two routes are the two states of the example: the page, and the
# page with the sign-up dialog open.
for route in listings signup; do
  mkdir -p "$site/flutter/$route"
  cp "$site/flutter/index.html" "$site/flutter/$route/index.html"
done

step 'Writing robots, sitemap and .nojekyll'
cat >"$site/robots.txt" <<'ROBOTS'
# The Flutter build is a canvas with no text of its own for a crawler to read; the
# web rendering carries the markup, so it is the one that gets indexed.
User-agent: *
Allow: /
Disallow: /flutter/
ROBOTS

if [[ -n "$url" ]]; then
  [[ "$url" == */ ]] || url="$url/"
  cat >"$site/sitemap.xml" <<SITEMAP
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>${url}</loc></url>
</urlset>
SITEMAP
  printf 'Sitemap: %ssitemap.xml\n' "$url" >>"$site/robots.txt"
fi

# GitHub Pages runs Jekyll over a published directory unless this file is there,
# and Jekyll drops paths it thinks are special.
: >"$site/.nojekyll"

# The commit the published site was built from. A deploy is not instant and not always
# the one we think it is — one publication in this repository shipped the previous
# build while its script was current — so "is the site stale?" should be answerable
# with one request rather than by reading CSS class hashes. Every document names the
# same commit in `<meta name="unibox-build">`, so the two cannot disagree.
if [[ -n "$build" ]]; then
  printf '%s\n' "$build" >"$site/version.txt"
  printf '%s\n' "$(git -C "$root" log -1 --format='%s' 2>/dev/null || echo 'unknown')" \
    >>"$site/version.txt"
else
  date -u +%Y-%m-%dT%H:%M:%SZ >"$site/version.txt"
fi

printf '\n==> Built %s (base %s)\n' "$site" "$base"

if [ "$serve" -eq 1 ]; then
  printf '==> Serving http://localhost:8000/ (Ctrl-C to stop)\n'
  exec python3 -m http.server --directory "$site" 8000
fi
