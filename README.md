# HyprFM RPM — Fedora 45 (x86_64)

Unofficial, personal-use Fedora RPM packaging for **[HyprFM](https://github.com/soyeb-jim285/hyprfm)**, a Qt 6/QML file manager for Hyprland and other Wayland desktops.

**Original project:** [soyeb-jim285/hyprfm](https://github.com/soyeb-jim285/hyprfm). HyprFM's source code, official releases, documentation, and application bug reports are maintained upstream. **This RPM repository is not affiliated with or maintained by the HyprFM developer.**

> ### This package have been 100% vibe coded by OpenAI Codex. Use it at your own discretion.

## Install on Fedora 45

**Requirements:** Fedora 45, x86_64. **No GitHub account or authentication is required.**

1. Open the **[latest RPM release](https://github.com/Reason7322/HyprFM-RPM/releases/latest)**.
2. Under **Assets**, download the main `hyprfm-<version>-<release>.fc45.x86_64.rpm` file (not the checksum or debug packages).
3. From a terminal, install the downloaded RPM. For example, for version 0.7.0-2:

   ```bash
   sudo dnf install "$HOME/Downloads/hyprfm-0.7.0-2.fc45.x86_64.rpm"
   ```

   Replace the filename if the published version is newer.

4. Verify and launch:

   ```bash
   rpm -q hyprfm
   /usr/bin/hyprfm
   ```

If `command -v hyprfm` resolves to an older executable or symlink in `~/.local/bin`, it will take precedence over `/usr/bin/hyprfm`. Check that older file before removing it.

**A one-time RPM installation does not set up automatic repository synchronization.** To make newer versions available in normal `sudo dnf upgrade` runs, use the optional instructions below.

## Optional: configure DNF updates

This repository publishes RPMs through **public GitHub Releases**, but it does **not** host a directly usable public DNF repository. The included script creates a small local DNF mirror and can refresh it daily. It downloads through HTTPS and does not require a GitHub account.

### 1. Prepare the local mirror

```bash
sudo dnf install git curl jq createrepo_c

mkdir -p "$HOME/Projects"
git clone https://github.com/Reason7322/HyprFM-RPM.git "$HOME/Projects/HyprFM-RPM"

bash "$HOME/Projects/HyprFM-RPM/sync-private-rpm.sh"
```

The sync script's filename is retained for compatibility with existing setups; **it now fetches public releases without authentication**. The download is verified against the release's SHA-256 checksum before it is added to `~/.local/share/hyprfm-rpm-repo`.

### 2. Register the local repository with DNF

The `.repo.example` template contains an `@HOME@` placeholder. The following command replaces it with your actual home-directory path:

```bash
sed "s|@HOME@|$HOME|g" "$HOME/Projects/HyprFM-RPM/hyprfm-private.repo.example" \
  | sudo tee /etc/yum.repos.d/hyprfm-private.repo >/dev/null

sudo dnf makecache --refresh
dnf repoquery --available --repo hyprfm-private hyprfm
```

You should see the latest mirrored `hyprfm` RPM listed as an available package.

### 3. Enable daily synchronization (optional)

The systemd service template contains an `@SYNC_SCRIPT@` placeholder. Substitute your own script location and install it alongside the timer:

```bash
mkdir -p "$HOME/.config/systemd/user"

sed "s|@SYNC_SCRIPT@|$HOME/Projects/HyprFM-RPM/sync-private-rpm.sh|g" \
  "$HOME/Projects/HyprFM-RPM/hyprfm-private-sync.service.example" \
  > "$HOME/.config/systemd/user/hyprfm-private-sync.service"

install -m 644 "$HOME/Projects/HyprFM-RPM/hyprfm-private-sync.timer.example" \
  "$HOME/.config/systemd/user/hyprfm-private-sync.timer"

systemctl --user daemon-reload
systemctl --user start hyprfm-private-sync.service
journalctl --user -u hyprfm-private-sync.service -n 30 --no-pager

# Enable only after verifying the sync service succeeds:
systemctl --user enable --now hyprfm-private-sync.timer
systemctl --user list-timers hyprfm-private-sync.timer
```

The timer runs the local sync **once daily**. The local Git checkout itself does not auto-update; if the packaging scripts change in this repository, run `git -C "$HOME/Projects/HyprFM-RPM" pull --ff-only` to receive those script updates.

Once a new RPM has synchronized, your normal command installs it:

```bash
sudo dnf upgrade
```

**The timer does not automatically install new software.** It only refreshes what DNF can see.

## What the packaging does

- Tracks upstream **stable `vX.Y.Z` release tags** instead of individual development commits.
- Builds **Fedora 45 x86_64** RPMs in GitHub Actions, with the embedded **Ghostty terminal** and file-picker portal included.
- Uses **Zig 0.17.1** and sets Ghostty's CPU target to `baseline`, to avoid the illegal-instruction crash observed with the initial RPM on an older Ryzen CPU.
- Publishes successful RPM builds as **public GitHub releases**, after package-content checks.
- Supplies a local mirroring script plus DNF and systemd templates so normal Fedora upgrades can install newer packages.

## How releases are produced

1. GitHub Actions checks for the latest stable upstream HyprFM release tag daily.
2. If that tag and RPM packaging revision have not been published, it prepares the tagged sources and submodules.
3. A Fedora 45 container compiles the RPM with the Ghostty terminal enabled.
4. Once the build and package checks pass, the RPM and its SHA-256 checksum are published as a public release, for example `rpm-v0.7.0-2.fc45`.
5. Computers using the optional local mirror fetch the latest published RPM and make it visible to DNF.

## Files

| File | Purpose |
| --- | --- |
| `hyprfm.spec` | Fedora RPM recipe |
| `prepare-sources.sh` | Fetches an exact upstream tag and its Git submodules |
| `.github/workflows/stable-rpm.yml` | Stable-tag checking, RPM build, and GitHub release publishing |
| `sync-private-rpm.sh` | Public RPM download, checksum verification, and local DNF mirror refresh (legacy filename) |
| `hyprfm-private.repo.example` | Local DNF repository template (legacy filename) |
| `hyprfm-private-sync.service.example` | systemd user service template (legacy filename) |
| `hyprfm-private-sync.timer.example` | Daily synchronization timer template (legacy filename) |

## Limitations and security

- **Unofficial, community-available packaging.** This is not an official Fedora RPM, COPR, or upstream HyprFM distribution.
- Currently built for **Fedora 45 x86_64 only**; other Fedora versions need separate builds and testing.
- The local DNF repo uses **`gpgcheck=0`**. RPMs are **not GPG-signed**. The sync script checks the package against a SHA-256 checksum published alongside it, but this does **not** provide independent publisher authentication. Use at your own discretion.
- New upstream releases may introduce build failures or runtime regressions. A successful automated build is not proof that all application features were tested.
- The file-picker portal binary is installed but does not automatically become the selected portal backend.

## Upstream project

Visit **[HyprFM by soyeb-jim285](https://github.com/soyeb-jim285/hyprfm)** for the original application, upstream releases, documentation, and support.
