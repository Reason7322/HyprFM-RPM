# Private HyprFM Fedora 45 RPM

> ### This package have been 100% vibe coded by OpenAI Codex. Use it at your own discretion.

Scope: Personal-use packaging of stable upstream `vX.Y.Z` tags. The embedded
Ghostty terminal must be included. No public COPR or public package release.

## Design
- Private GitHub repository `Reason7322/HyprFM-RPM` holds source recipe and
  private GitHub release RPM assets.
- Daily GitHub Actions poll checks upstream *stable tags* (not every main commit)
  and builds the newest as-yet-unpublished stable version in a Fedora 45 container.
- An authenticated local sync script downloads the private RPM and generates
  RPM metadata in an unprivileged user-owned local mirror.
- After separate authorization, DNF can use a local `file://` repo configuration
  and a user timer can run the authenticated sync before regular upgrades.

GitHub's private release asset URLs are not a native authenticated DNF repo.
This local mirror is deliberate: avoid putting a GitHub token in dnf.conf or
running an HTTP token proxy on M A C H I N E.

## Source / build
- `prepare-sources.sh v0.7.0 /tmp/sources` fetches the exact tag and
  recursive submodules and makes the RPM source tarball.
- `hyprfm.spec` includes `HYPRFM_TERMINAL=ON`. Fedora 45 ships
  Zig 0.16, but Ghostty needs Zig 0.17. The remote workflow installs Zig 0.17.1
  in its *own container* (not onto M A C H I N E).
- The workflow runs rpmbuild and package inventory checks; no successful
  build or runtime result is established until its workflow completes.

## Sync (requires private release, gh authentication, createrepo_c, jq)
`bash sync-private-rpm.sh`

## Status / safety
- The native user's existing `/home/reason/hyprfm` checkout is untouched.
- No live package installed and no system-wide repo configuration modified.
- The portal binary is packaged, but *does not become active* without portal
  preference configuration; those preferences must not be silently changed.
- Do not replace the existing keyboard shortcut until the RPM actually runs.
- Future Fedora version support requires its own build matrix/verification.
