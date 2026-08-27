# dotfiles

My personal machine setup: shell, editor, window manager, and the scripts that lay all of it down on a fresh install. It covers two machines I actually use, a MacBook running Hyprspace as a tiling window manager and a CachyOS desktop running Omarchy (the Hyprland-based "quattro" layer). Everything else, this README included, assumes you're one of those two.

If you found this by browsing GitHub: feel free to steal whatever's useful, but don't run it as-is. The package lists, keybindings, and window manager choices are tuned to how I work, not a general-purpose starting point.

## Layout

```
bootstrap.sh        entry point, dispatches by OS
common/              dotfiles shared by both machines (zsh, nvim, tmux, ghostty, git)
macos/               Homebrew, Hyprspace, sketchybar, macOS defaults
linux/               CachyOS + Omarchy install flow, Hyprland config
lib/                 shared bash helpers (symlinking, logging)
```

Every `.config` folder under `common/`, `macos/`, or `linux/` mirrors `$HOME` exactly. A file at `common/.config/zsh/.zshrc` becomes a symlink at `~/.config/zsh/.zshrc`, pointing back into this repo. Edit the file here, and the change is live immediately, no reinstall step.

## Running it

```bash
./bootstrap.sh
```

It reads `uname -s` and hands off to `macos/install.sh` or `linux/install.sh`. Both eventually call `common/install.sh`, which symlinks the shared dotfiles and bootstraps tmux's plugin manager. Everything is idempotent: rerunning any of these scripts after the fact just reapplies the current state, it won't duplicate work or break anything already in place.

## macOS

`macos/install.sh` installs Xcode's command line tools, Homebrew, then everything in `Brewfile` (CLI tools, Ghostty, sketchybar, and casks like Brave, Notion, Obsidian). Hyprspace, an AeroSpace fork used as the tiling window manager, gets initialized before the dotfile symlinks go down, so my own `hyprspace/config.toml` overwrites whatever default it generates rather than the other way around.

A few things only happen conditionally:

- AlDente installs only if `sysctl -n hw.model` reports a MacBook, since it's a laptop battery tool and pointless on a desktop.
- The Proton Pass SSH agent LaunchAgent is bootstrapped only if it isn't already running.

Once packages and symlinks are in place, `macos-defaults.sh` applies the actual macOS preferences I care about (Finder view style, Dock size and autohide, trackpad tap-to-click, dark mode) and restarts Finder and Dock so they take effect without a logout.

## Linux (CachyOS + Omarchy)

`linux/install.sh` assumes you're starting from a CachyOS install with a user account already created, and layers Omarchy's stable channel on top of it. Concretely, it:

1. Adds Omarchy's pacman repo and installs the `omarchy` package family, while preserving CachyOS's own repos (they'd otherwise get dropped when Omarchy takes over `pacman.conf`).
2. Runs Omarchy's own setup commands (`omarchy-apply-system`, `omarchy-provision-user`) and clones the Omarchy repo into `~/.local/share/omarchy`, since the packaged install doesn't do that clone itself and several of Omarchy's own scripts assume it's there.
3. Asks a few questions interactively via `gum`: whether to set up gaming tools, which of Omarchy's bundled webapps to remove, whether to swap the Discord webapp for the native client, whether to keep OBS.
4. Symlinks the Linux-specific dotfiles and enables the Proton Pass SSH agent as a systemd user service.

One CachyOS installer gotcha worth knowing before you get there: leave "shell configuration" unticked in the CachyOS installer. It pulls in `tealdeer`, which conflicts with the `tldr` package Omarchy wants.

Separately, `linux/configure-monitors.sh` is a standalone script, not part of install, for picking which connected monitors to use and which one is primary. Rerun it whenever your monitor setup changes; it regenerates `hypr/monitors.lua` and, if you've got two or more screens, splits workspaces five-per-monitor and swaps in a custom bar widget that shows each monitor's own workspace range instead of the same global one on every screen.

## Common

Both platforms end at `common/install.sh`: it symlinks the shared configs and, on first run, clones tmux's plugin manager into `~/.config/tmux/plugins/tpm` before installing tmux plugins. Nothing here is platform-specific by design, if a tool or config only makes sense on one OS, it lives under `macos/` or `linux/` instead.

## A note on safety

Some of what these scripts touch is not easily undone: NVIDIA driver setup, `mkinitcpio` regeneration, macOS system defaults. I've run each install path against my own hardware before trusting it, but "works on my machine" is doing a lot of lifting here. Read a script before you run it, especially on Linux.
