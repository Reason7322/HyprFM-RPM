# HyprFM RPM — Fedora 45 (x86_64)

Personal, **unofficial RPM packaging** for [HyprFM](https://github.com/soyeb-jim285/hyprfm), a Qt 6/QML file manager for Hyprland and other Wayland desktops.

**Original project:** [soyeb-jim285/hyprfm](https://github.com/soyeb-jim285/hyprfm) — source code, upstream releases, documentation, and bug reports belong there. This repository is **not affiliated with or maintained by the HyprFM developer**.

> This packaging and its automation were AI-assisted. Use at your own discretion. This is a personal project, not an officially supported Fedora package.

## What this repository does

- Packages **stable upstream release tags** (such as `v0.7.0`), not arbitrary commits from `main`.
- Builds native **Fedora 45 x86_64 RPMs** in GitHub Actions using Fedora 45 dependencies.
- Preserves HyprFM's **built-in Ghostty terminal** and includes the file-picker portal binary.
- Uses **Zig 0.17.1** for the Ghostty component and `-Dcpu=baseline` for wider x86-64 CPU compatibility.
- Publishes successful builds as **private GitHub release assets** after verifying the RPM's contents.
- Provides a script and systemd user-service templates to download the latest private RPM, verify its SHA-256 checksum, and refresh a **local DNF repository**, allowing normal `dnf upgrade` transactions to pick up newer packages.

**This repository does not modify or redistribute HyprFM's upstream source as a separate product.** The packaging workflow fetches each exact upstream tag, including its Git submodules, and builds from that source.

## How updates work

1. A scheduled GitHub Actions workflow checks upstream for the newest stable `vX.Y.Z` tag.
2. If that tag and RPM packaging revision have not been built, the workflow creates a Fedora RPM.
3. A successful build is published as a private release (for example, `rpm-v0.7.0-2.fc45`).
4. On an authorized PC, `sync-private-rpm.sh` downloads that release via authenticated GitHub CLI, verifies its SHA-256 checksum, and runs `createrepo_c` on the local mirror.
5. DNF reads that local `file://` repository during normal upgrades.

The daily **sync timer only refreshes repository content**; it does **not** automatically install updates. The system only receives new HyprFM versions when you run `sudo dnf upgrade` (or another DNF upgrade operation).

## Files

| File | Purpose |
| --- | --- |
| `hyprfm.spec` | Fedora RPM build recipe |
| `prepare-sources.sh` | Retrieve an exact upstream tag and its submodules |
| `.github/workflows/stable-rpm.yml` | Check stable tags, build RPM, and publish private releases |
| `sync-private-rpm.sh` | Authenticated download, checksum verification, and local repo refresh |
| `hyprfm-private.repo.example` | Example local DNF repository configuration |
| `hyprfm-private-sync.service.example` | Example systemd user service for syncing |
| `hyprfm-private-sync.timer.example` | Example daily sync timer |

## Scope and limitations

- **Personal-use, private GitHub repository.** There is no public COPR or public RPM feed.
- Targets **Fedora 45 / x86_64** only. Future Fedora versions require adjustments and testing.
- The local DNF repository currently uses `gpgcheck=0`. The download script checks SHA-256 against a checksum published in the same private release, which is **not equivalent to independent RPM signature verification**.
- A future HyprFM release may change its build requirements and break automated packaging. A green workflow verifies that an RPM was built and inspected, **not** that every feature has been runtime-tested.
- HyprFM's file-picker portal is included, but selecting it as the active portal backend requires separate desktop configuration.

## Upstream

For the original application, documentation, release announcements, and application issues, see **[HyprFM by soyeb-jim285](https://github.com/soyeb-jim285/hyprfm)**.
