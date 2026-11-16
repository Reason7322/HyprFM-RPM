# HyprFM RPM — Fedora 45 (x86_64)

Personal, **unofficial RPM packaging** for [HyprFM](https://github.com/soyeb-jim285/hyprfm), a Qt 6/QML file manager for Hyprland and other Wayland desktops.

**Original project:** [soyeb-jim285/hyprfm](https://github.com/soyeb-jim285/hyprfm) — source code, upstream releases, documentation, and bug reports belong there. This repository is **not affiliated with or maintained by the HyprFM developer**.

> ### This package have been 100% vibe coded by OpenAI Codex. Use it at your own discretion.

## What this repository does

- Packages **stable upstream release tags** (such as `v0.7.0`), not arbitrary commits from `main`.
- Builds native **Fedora 45 x86_64 RPMs** in GitHub Actions using Fedora 45 dependencies.
- Preserves HyprFM's **built-in Ghostty terminal** and includes the file-picker portal binary.
- Uses **Zig 0.17.1** for the Ghostty component and `-Dcpu=baseline` for wider x86-64 CPU compatibility.
- Publishes successful builds as **private GitHub release assets** after verifying the RPM's contents.
- Provides a script and systemd user-service templates to download the latest private RPM, verify its SHA-256 checksum, and refresh a **local DNF repository**, allowing normal `dnf upgrade` transactions to pick up newer packages.

**This repository does not modify or redistribute HyprFM's upstream source as a separate product.** The packaging workflow fetches each exact upstream tag, including its Git submodules, and builds from that source.

## Install on Fedora 45

**Requirements:** Fedora 45 x86_64 and access to this **private** GitHub repository. The RPM is not on Fedora's public repositories, so `sudo dnf install hyprfm` alone will not work until you configure the local DNF repository below.

### One-time installation (RPM download)

1. Install the GitHub CLI if needed and authenticate with a GitHub account that has access to this repository:

   ```bash
   sudo dnf install gh
   gh auth login
   ```

2. Download the **latest private RPM release** into an empty directory and install it:

   ```bash
   mkdir -p "$HOME/Downloads/hyprfm-rpm"
   gh release download --repo Reason7322/HyprFM-RPM \
     --pattern 'hyprfm-[0-9]*.x86_64.rpm' \
     --dir "$HOME/Downloads/hyprfm-rpm"

   sudo dnf install "$HOME"/Downloads/hyprfm-rpm/hyprfm-*.x86_64.rpm
   ```

3. Verify the installed package and launch it:

   ```bash
   rpm -q hyprfm
   /usr/bin/hyprfm
   ```

If `command -v hyprfm` points to an older build in `~/.local/bin`, that earlier executable or symlink is taking precedence. Verify which file it refers to before removing it. The RPM's executable is `/usr/bin/hyprfm`.

**Installing a downloaded RPM does not configure future DNF updates.** To receive new versions through your normal `sudo dnf upgrade`, enable the private local mirror as described next.

### Optional: receive updates through DNF

The repository includes a synchronization script and example systemd units. This is a **personal setup**: the examples currently use `/home/reason` and the private repository `Reason7322/HyprFM-RPM`. Adjust those paths and account details for another machine/user.

```bash
sudo dnf install gh jq createrepo_c
gh auth status
gh repo clone Reason7322/HyprFM-RPM "$HOME/Projects/HyprFM-RPM"

# Create a local repository from the latest authenticated private release.
bash "$HOME/Projects/HyprFM-RPM/sync-private-rpm.sh"
```

The example `hyprfm-private.repo.example` must reference the actual user's local mirror directory (normally `$HOME/.local/share/hyprfm-rpm-repo`; DNF repository files require an **absolute path**, not an unexpanded shell variable). After reviewing it, copy it to `/etc/yum.repos.d/hyprfm-private.repo` with root privileges:

```bash
sudo install -m 644 "$HOME/Projects/HyprFM-RPM/hyprfm-private.repo.example" \
  /etc/yum.repos.d/hyprfm-private.repo

sudo dnf makecache --refresh
dnf repoquery --available --repo hyprfm-private hyprfm
```

For daily automatic synchronization, review `hyprfm-private-sync.service.example` and update its `ExecStart` path to your clone location. Then install the service and timer:

```bash
mkdir -p "$HOME/.config/systemd/user"
install -m 644 "$HOME/Projects/HyprFM-RPM/hyprfm-private-sync.service.example" \
  "$HOME/.config/systemd/user/hyprfm-private-sync.service"
install -m 644 "$HOME/Projects/HyprFM-RPM/hyprfm-private-sync.timer.example" \
  "$HOME/.config/systemd/user/hyprfm-private-sync.timer"

systemctl --user daemon-reload
systemctl --user start hyprfm-private-sync.service
journalctl --user -u hyprfm-private-sync.service -n 30 --no-pager
# Enable the timer only after the one-shot sync succeeds:
systemctl --user enable --now hyprfm-private-sync.timer
```

Once the mirror is synchronized, newer tagged-release RPMs are available during regular `sudo dnf upgrade` runs. The sync timer **does not install upgrades by itself**. GitHub CLI authentication must remain available to the user service.

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
