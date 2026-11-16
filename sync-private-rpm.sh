#!/usr/bin/env bash
set -euo pipefail
# Private GitHub RPM releases -> unprivileged local DNF mirror.
# Safe to run repeatedly; requires authenticated gh + createrepo_c + rpm.
repo="Reason7322/HyprFM-RPM"
dest="${HYPRFM_RPM_REPO:-$HOME/.local/share/hyprfm-rpm-repo}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for bin in gh rpm createrepo_c sha256sum jq; do
  command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 1; }
done
tag="$(gh release list --repo "$repo" --limit 100 --json tagName,isLatest |
   jq -r 'map(select(.isLatest == true)) | first | .tagName // empty')"
[[ "$tag" =~ ^rpm-v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.fc45$ ]] || { echo "No stable private RPM release available" >&2; exit 2; }
gh release download "$tag" --repo "$repo" --pattern 'hyprfm-*.x86_64.rpm' --dir "$tmp"
gh release download "$tag" --repo "$repo" --pattern 'hyprfm-*.rpm.sha256' --dir "$tmp"
rpmfile="$(find "$tmp" -maxdepth 1 -name 'hyprfm-*.x86_64.rpm' -print -quit)"
test -n "$rpmfile"
# The sha file records a path from the CI builder; use only its checksum value.
expected="$(awk 'NR==1 {print $1}' "$rpmfile.sha256")"
printf '%s  %s\n' "$expected" "$rpmfile" | sha256sum -c -
rpm -qp --qf '%{NAME} %{ARCH}\n' "$rpmfile" | grep -Fx 'hyprfm x86_64'
mkdir -p "$dest"
cp -n "$rpmfile" "$dest/"
createrepo_c --update "$dest"
echo "Mirrored $tag to $dest"
echo "Next step: configure a local file:// DNF repository (not done by this script)."
