#!/usr/bin/env bash
set -euo pipefail

# Public GitHub RPM release -> unprivileged local DNF mirror.
# Kept under its original filename for compatibility with existing user timers.
repo="Reason7322/HyprFM-RPM"
dest="${HYPRFM_RPM_REPO:-$HOME/.local/share/hyprfm-rpm-repo}"
api="https://api.github.com/repos/$repo/releases/latest"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for bin in curl jq rpm createrepo_c sha256sum; do
  command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 1; }
done

curl -fsSL --retry 3 -H 'Accept: application/vnd.github+json' "$api" -o "$tmp/release.json"
tag="$(jq -er '.tag_name | select(test("^rpm-v[0-9]+[.][0-9]+[.][0-9]+-[0-9]+[.]fc45$"))' "$tmp/release.json")" || {
  echo "Latest public release is not a Fedora 45 stable RPM release" >&2
  exit 2
}

version_and_release="${tag#rpm-v}"
version="${version_and_release%-*}"
release="${version_and_release##*-}"
name="hyprfm-$version-$release.x86_64.rpm"

get_asset_url() {
  jq -er --arg name "$1" '.assets[] | select(.name == $name) | .browser_download_url' "$tmp/release.json"
}
rpm_url="$(get_asset_url "$name")"
hash_url="$(get_asset_url "$name.sha256")"

curl -fsSL --retry 3 "$rpm_url" -o "$tmp/$name"
curl -fsSL --retry 3 "$hash_url" -o "$tmp/$name.sha256"

expected="$(awk 'NR == 1 { print $1 }' "$tmp/$name.sha256")"
[[ "$expected" =~ ^[a-fA-F0-9]{64}$ ]] || { echo "Invalid SHA-256 checksum file" >&2; exit 3; }
printf '%s  %s\n' "$expected" "$tmp/$name" | sha256sum -c -
rpm -qp --qf '%{NAME} %{VERSION} %{RELEASE} %{ARCH}\n' "$tmp/$name" |
  grep -Fx "hyprfm $version $release x86_64"

mkdir -p "$dest"
cp -n "$tmp/$name" "$dest/"
createrepo_c --update "$dest"
echo "Mirrored $tag to $dest"
echo "DNF upgrades are available once a local file:// repository is configured."
