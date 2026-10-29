#!/usr/bin/env bash
#
# The monthly hour, in one command: the gate with the API docs, the performance budget, and
# the numbers the README quotes.
#
# Usage:
#   tool/maintenance.sh
#
# It is deliberately slower than `tool/verify.sh` — it starts a browser, builds Flutter for
# the web and writes the site — because it answers a different question: not "did this
# change break it" but "is the repository still what the documentation says it is".
set -euo pipefail

cd "$(dirname "$0")/.."

step() {
  printf '\n==> %s\n' "$1"
}

step 'The gate, with the API docs'
tool/verify.sh --docs

step 'The numbers: budgets, boot and bytes'
tool/performance.sh

step 'The site'
tool/site.sh

step 'What a crawler reads'
python3 tool/seo_report.py build/site

# The three numbers in the README's "Serving a tree" section are measurements, so they are
# printed where a maintainer will see them next to the build that produced them. A quoted
# number that no longer matches is a lie in the shop window.
step 'The numbers the README quotes'
client=build/site/web/main.client.js
engine=build/site/flutter/main.dart.js
for file in "$client" "$engine"; do
  if [ -f "$file" ]; then
    printf '  %-40s %8s gzipped\n' "$file" "$(gzip -c "$file" | wc -c | tr -d ' ')"
  else
    printf '  %-40s %s\n' "$file" 'missing'
  fi
done
printf '\n  README: the site client is 67 KB gzipped, the Flutter build 718 KB before Canvaskit.\n'
printf '  Update those two numbers in the same commit as anything that moves them.\n'
