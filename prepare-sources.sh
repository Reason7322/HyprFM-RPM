#!/usr/bin/env bash
set -euo pipefail
# Prepares an RPM source archive from an upstream *tag*, including submodules.
# Run in a clean work directory. No changes to the installed application.
tag="${1:-v0.7.0}"
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Expected stable tag vX.Y.Z" >&2; exit 2; }
version="${tag#v}"
dest="${2:-.}"
mkdir -p "$dest"
dest="$(realpath "$dest")"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT
git clone --quiet --depth 1 --branch "$tag" --recurse-submodules \
  https://github.com/soyeb-jim285/hyprfm.git "$temp/hyprfm"
test -f "$temp/hyprfm/src/qml/Quill/Theme.qml"
test -d "$temp/hyprfm/src/qml/icons"
grep -Eq "^project\\(hyprfm VERSION ${version//./\.} LANGUAGES CXX\\)" "$temp/hyprfm/CMakeLists.txt" || {
  echo "Tag and CMake project version differ; refusing to package" >&2; exit 3;
}
mv "$temp/hyprfm" "$temp/hyprfm-$version"
tar -C "$temp" --exclude-vcs -czf "$dest/hyprfm-$version.tar.gz" "hyprfm-$version"
printf 'Created: %s\n' "$dest/hyprfm-$version.tar.gz"
