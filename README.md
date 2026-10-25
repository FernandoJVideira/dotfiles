# dotfiles

My personal machine setup: shell, editor, window manager, and the scripts that lay all of it down on a fresh install. It covers the machines I actually use: a MacBook running Hyprspace as a tiling window manager, a CachyOS desktop running Omarchy (the Hyprland-based "quattro" layer), and a Nobara machine running Hyprland + Quickshell via my [Omadora](https://github.com/FernandoJVideira/omadora) fork. Everything else, this README included, assumes you're one of those.

If you found this by browsing GitHub: feel free to steal whatever's useful, but don't run it as-is. The package lists, keybindings, and window manager choices are tuned to how I work, not a general-purpose starting point.

## Layout

```
bootstrap.sh         entry point, dispatches by OS (and by distro, on Linux)
common/               dotfiles shared by all machines (zsh, nvim, tmux, ghostty, git)
macos/                Homebrew, Hyprspace, sketchybar, macOS defaults
linux/
  arch/                Arch + Omadora (arch branch) install flow, Hyprland config
  nobara/              Nobara + Omadora install flow
lib/                  shared bash helpers (symlinking, logging)
```

Every `.config` folder under `common/`, `macos/`, `linux/arch/`, or `linux/nobara/` mirrors `$HOME` exactly. A file at `common/.config/zsh/.zshrc` becomes a symlink at `~/.config/zsh/.zshrc`, pointing back into this repo. Edit the file here, and the change is live immediately, no reinstall step.

## Running it

```bash
./bootstrap.sh
```

It reads `uname -s` and hands off to `macos/install.sh` on macOS. On Linux it also checks `/etc/os-release` and routes Nobara (or anything else `ID_LIKE=fedora`) to `linux/nobara/install.sh`, everything else to `linux/arch/install.sh`. All three eventually call `common/install.sh`, which symlinks the shared dotfiles, bootstraps tmux's plugin manager, and installs Miniconda. Everything is idempotent: rerunning any of these scripts after the fact just reapplies the current state, it won't duplicate work or break anything already in place.

## macOS

`macos/install.sh` installs Xcode's command line tools, Homebrew, then everything in `Brewfile` (CLI tools, kitty (Ghostty too), sketchybar, and casks like Brave, Notion, Obsidian). Hyprspace, an AeroSpace fork used as the tiling window manager, gets initialized before the dotfile symlinks go down, so my own `hyprspace/config.toml` overwrites whatever default it generates rather than the other way around.

A few things only happen conditionally:

- AlDente installs only if `sysctl -n hw.model` reports a MacBook, since it's a laptop battery tool and pointless on a desktop.
- The Proton Pass SSH agent LaunchAgent is bootstrapped only if it isn't already running.

Once packages and symlinks are in place, `macos-defaults.sh` applies the actual macOS preferences I care about (Finder view style, Dock size and autohide, trackpad tap-to-click, dark mode) and restarts Finder and Dock so they take effect without a logout.

### Switching themes

`theme` (in `macos/.local/bin`, on the PATH through `~/.local/bin`) is the macOS stand-in for `omactl theme set`: run it for an fzf menu of the same 24 themes the Linux machines have, with a preview pane (the palette in true color, plus the theme's `preview.png` when the terminal is kitty or ghostty; each screenshot is fetched the first time it's shown), or `theme set <name>`, `theme preview <name>`, `theme list`, `theme bg` (next wallpaper), `theme update`. It keeps a sparse clone of my Omadora fork in `~/.local/share/omadora` (just the themes, the templates and the two scripts that resolve a palette and render the templates, a few hundred KB; a theme's wallpapers are only fetched the first time it's picked) and runs Omadora's own scripts from it, so palettes and derived colors are identical to Linux. Those scripts need bash 4+, hence Homebrew's `bash` in the Brewfile; `theme` itself runs on the system bash.

Applying a theme renders the templates into `~/.config/omadora/current/theme`, sets the wallpaper and flips macOS between light and dark to match the theme's mode, reloads the running kitty, ghostty and btop, and then runs the hooks in `~/.config/omadora/hooks/theme-set.d` (`macos/.config/omadora/hooks`), the same mechanism Linux uses: starship and Zed re-render, Neovim switches its NvChad theme, sketchybar and the window borders get new colors from `themed/macos-colors.sh.tpl`, btop is pointed at the rendered theme. tmux needs nothing: its colors are the terminal's. The installer applies `gruvbox-classic` the first time only (the classic Gruvbox Dark this Mac always had, kept as a user theme in `macos/.config/omadora/themes`; Omadora's own `gruvbox` is the softer gruvbox-material variant), so rerunning it never undoes a theme picked since.

## Linux (Arch + Omadora)

`linux/arch/install.sh` assumes a minimal Arch install (archinstall, no desktop environment or display manager, NetworkManager) with a user account already created. The desktop itself comes from my [Omadora](https://github.com/FernandoJVideira/omadora) fork (`arch` branch): Hyprland, the Quickshell shell, the SDDM login screen and their packages. Concretely, it:

1. Installs `gum` (for the prompts below), `zsh` (set as the default shell), `git` and `base-devel`.
2. Asks a few questions interactively via `gum`: whether to set up gaming tools, install Discord, and install OBS.
3. Clones Omadora into `~/.local/share/omadora` over HTTPS and runs its installer. On a first install that installer ends with a reboot, so run `./bootstrap.sh` again afterwards to finish. On a machine that already has the checkout it only fast-forwards it (use `omactl update` to apply updates).
4. Symlinks the Arch-specific dotfiles after Omadora is in place, so my configs win over its defaults, then installs the remaining packages: Zed, Go, the .NET SDK, Element, kitty, `gh`, the zsh config's tools, and from the AUR Brave Origin, Proton Pass CLI, OpenDeck and Spotify.
5. Enables the Proton Pass SSH agent. It only starts once your personal access token is in `~/.config/proton-pass-cli/pat`; until then the unit is skipped.
6. Runs the shared dotfiles installer, re-applies the current theme with `omactl theme set`, and renders the starship prompt and the Zed theme.

The previous Arch flow (CachyOS + Omarchy through omarshell) is preserved at the `arch-omarshell-final` tag. This flow has been tested in a VM only; Plymouth, NVIDIA driver packages and real-hardware features (Bluetooth, fingerprint, FIDO2) are not set up or verified yet. On Arch, monitors are set directly in `~/.config/hypr/monitors.lua`.

## Linux (Nobara + Omadora)

`linux/nobara/install.sh` assumes a Nobara (or other Fedora-family) install with a user account already created. The desktop itself comes from my [Omadora](https://github.com/FernandoJVideira/omadora) fork (`nobara` branch): Hyprland, the Quickshell shell, the login screen and their packages. Concretely, it:

1. Installs `zsh` and sets it as the default shell, same as the Arch flow, plus `git`.
2. Clones Omadora into `~/.local/share/omadora` over HTTPS and runs its installer. On a machine that already has the checkout it only fast-forwards it (use `omactl update` to apply updates).
3. Installs the remaining packages: Hyprland/Quickshell runtime dependencies, Zed, Go, the .NET SDK, Discord, Spotify, `gh`, the zsh config's tools, Proton Pass CLI, Brave Origin, and mise (neovim, tmux, node, Claude Code).
4. Symlinks the Nobara-specific dotfiles after Omadora is in place, so my configs win over its defaults, then enables the Proton Pass agent and the crash watcher.

## Common

All platforms end at `common/install.sh`: it symlinks the shared configs and, on first run, clones tmux's plugin manager into `~/.config/tmux/plugins/tpm` before installing tmux plugins. It also installs Miniconda to `~/miniconda3` with Anaconda's own installer (`lib/miniconda.sh`, SHA256-checked, never runs `conda init`) - the same prefix on every OS is what lets its shell setup live once in `common/.config/zsh/.zshenv`: `conda` is on `PATH` everywhere and the activation hook loads on first use, with `base` not auto-activated. A fresh install still needs Anaconda's Terms of Service accepted before conda can use its default channels; the installer prints the commands rather than accepting for you. Nothing here is platform-specific by design, if a tool or config only makes sense on one OS or distro, it lives under `macos/`, `linux/arch/`, or `linux/nobara/` instead.

### Zed

`common/.config/zed/` holds Zed's `settings.json`, `keymap.json` and the extension list (`auto_install_extensions`, installed on first launch, so a new extension added through Zed's UI has to be added there to reach the other machines). The theme is always called "Desktop Theme": `zed-theme-sync` renders `desktop-theme.json.tpl` from the current Omadora theme's `colors.toml`, at install time and from the `theme-set` hook (`omactl theme set` on Linux, the `theme` command on macOS), and Zed re-applies it live. The template is a conversion of Zed's own Gruvbox theme (MIT) with the palette swapped in, so it covers the whole UI, not just the editor. Zed's terminal font is Hack Nerd Font Mono, installed on every OS. `zed-extensions-check` compares what Zed has installed on the current machine with that list (missing ones, and ones installed here but not listed); Zed only installs the missing ones when it starts, so run it after the first launch on a new machine. Zed's prompt library (`~/.config/zed/prompts`) is a binary database Zed manages itself, so it isn't tracked.

### tmux

The status line in `tmux.conf` uses plain ANSI color names, so it follows whatever palette the terminal has: the current theme's, live, with no hook or reload (kitty is re-rendered on every theme change on both Linux and macOS).

## A note on safety

Some of what these scripts touch is not easily undone: NVIDIA driver setup, `mkinitcpio` regeneration, macOS system defaults. I've run each install path against my own hardware before trusting it, but "works on my machine" is doing a lot of lifting here. Read a script before you run it, especially on Linux.
