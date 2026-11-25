#!/usr/bin/env bash
#
# Publishes the packages a release tag names, in dependency order.
#
# Usage:
#   tool/publish.sh --check   validate every published package's archive
#   tool/publish.sh           publish the versions the tag names
#
# The tag is `GITHUB_REF_NAME` (`v0.1.1`) in the workflow, or the first argument
# elsewhere. A package is published only when the tag names its version and pub.dev
# does not have that version yet; a package sitting at another version fails the run
# before anything is published. `publish_to: none` is lifted for the run and restored
# afterwards, whatever happens, so the guard in the repository never leaves.
set -euo pipefail

cd "$(dirname "$0")/.."

# The packages on pub.dev, in the order their dependencies impose.
packages=(
  unibox_core
  unibox_material
  unibox_html
  unibox_flutter
  unibox_material_flutter
)

mode=publish
tag="${GITHUB_REF_NAME:-}"
for argument in "$@"; do
  case "$argument" in
    --check) mode=check ;;
    -h | --help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    v[0-9]*) tag="$argument" ;;
    *)
      echo "Unknown argument: $argument" >&2
      exit 2
      ;;
  esac
done

backup=$(mktemp -d)
restore() {
  for package in "${packages[@]}"; do
    cp "$backup/$package" "packages/$package/pubspec.yaml"
  done
  rm -rf "$backup"
}
trap restore EXIT
for package in "${packages[@]}"; do
  cp "packages/$package/pubspec.yaml" "$backup/$package"
  # The guard's removal is the release's own manual step; this run does it in place and
  # puts it back, so the archive is publishable and the repository still refuses one.
  sed -i.bak '/^publish_to: none$/d' "packages/$package/pubspec.yaml"
  rm -f "packages/$package/pubspec.yaml.bak"
done

local_version() {
  sed -n 's/^version: *//p' "packages/$1/pubspec.yaml" | head -1
}

# The latest version pub.dev serves for the package, or nothing when it has none.
published_version() {
  python3 - "$1" <<'PY'
import json
import sys
import urllib.request

try:
    with urllib.request.urlopen(
        f"https://pub.dev/api/packages/{sys.argv[1]}", timeout=10
    ) as response:
        print(json.load(response)["latest"]["version"])
except Exception:
    pass
PY
}

if [ "$mode" = check ]; then
  failed=0
  for package in "${packages[@]}"; do
    printf '\n==> %s\n' "$package"
    # `dart pub publish --dry-run` exits 65 for warnings too, including the "modified in
    # git" one the lifted guard causes, so the message decides: only a missing requirement
    # stops a release.
    output=$( (cd "packages/$package" && dart pub publish --dry-run) 2>&1 ) || true
    printf '%s\n' "$output"
    if grep -q "can't be published yet" <<<"$output"; then
      failed=1
    fi
  done
  exit "$failed"
fi

if [ -z "$tag" ]; then
  echo "Usage: tool/publish.sh <tag>, for example v0.1.1" >&2
  exit 2
fi
version=${tag#v}
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Not a release tag: $tag" >&2
  exit 2
fi

# Decide before publishing anything: a mismatch must never leave half a release on pub.dev.
pending=()
for package in "${packages[@]}"; do
  local=$(local_version "$package")
  on_pub=$(published_version "$package")
  if [ "$local" = "$on_pub" ]; then
    printf '%-26s %s is on pub.dev already, skipping\n' "$package" "$local"
    continue
  fi
  if [ "$local" != "$version" ]; then
    echo "$package is $local but $tag names $version; bump it or tag its version" >&2
    exit 1
  fi
  pending+=("$package")
done

if [ ${#pending[@]} -eq 0 ]; then
  echo "Nothing to publish for $tag."
  exit 0
fi

for package in "${pending[@]}"; do
  printf '\n==> %s %s\n' "$package" "$version"
  # A warning exits 65, and the lifted guard is one, so a non-zero code alone is not a
  # failure: the version pub.dev serves afterwards is what decides.
  status=0
  output=$( (cd "packages/$package" && dart pub publish --force) 2>&1 ) || status=$?
  printf '%s\n' "$output"
  if grep -q "can't be published yet" <<<"$output"; then
    echo "$package cannot be published" >&2
    exit 1
  fi
  if [ "$status" -ne 0 ] && [ "$status" -ne 65 ]; then
    echo "Publishing $package exited $status" >&2
    exit 1
  fi

  # A dependant is installed from pub.dev, so its dependency has to be served before the
  # next archive goes up: the index answers a moment after the upload.
  for _ in $(seq 1 30); do
    [ "$(published_version "$package")" = "$version" ] && break
    sleep 2
  done
  if [ "$(published_version "$package")" != "$version" ]; then
    echo "pub.dev does not serve $package $version yet" >&2
    exit 1
  fi
done
