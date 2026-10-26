# dotfiles

My personal machine setup: shell, editor, window manager, and the scripts that lay all of it down on a fresh install. It covers the machines I use: a MacBook running Hyprspace as a tiling window manager, a CachyOS desktop running Omarchy (the Hyprland-based "quattro" layer), and a Nobara machine running Hyprland + Quickshell via my [Omadora](https://github.com/FernandoJVideira/omadora) fork. Everything else assumes you're one of those.

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

It reads `uname -s` and hands off to `macos/install.sh` on macOS. On Linux it also checks `/etc/os-release`: Nobara (or anything else `ID_LIKE=fedora`) goes to `linux/nobara/install.sh`, everything else to `linux/arch/install.sh`. All three end by calling `common/install.sh` (see Common below). Every script is idempotent, so rerunning one just reapplies the current state.

## macOS

`macos/install.sh` installs Xcode's command line tools, Homebrew, then everything in `Brewfile` (shell utilities, kitty (Ghostty too), sketchybar, and casks like Brave, Notion, Obsidian). Dev tools come from mise instead (see Common). Hyprspace, an AeroSpace fork used as the tiling window manager, gets initialized before the dotfile symlinks go down, so my own `hyprspace/config.toml` overwrites whatever default it generates rather than the other way around.

A few things only happen conditionally:

- AlDente installs only if `sysctl -n hw.model` reports a MacBook, since it's a laptop battery tool and pointless on a desktop.
- The Proton Pass SSH agent LaunchAgent is bootstrapped only if it isn't already running.

Once packages and symlinks are in place, `macos-defaults.sh` applies the macOS preferences I care about (Finder view style, Dock size and autohide, trackpad tap-to-click, dark mode) and restarts Finder and Dock so they take effect without a logout.

### Switching themes

`theme` (in `macos/.local/bin`, on the PATH through `~/.local/bin`) is the macOS stand-in for `omactl theme set`. With no arguments it opens a main menu (Theme, Wallpaper, Next wallpaper, Update themes), and each entry opens its own fzf menu. The theme list has a preview pane: the palette in true color, plus the theme's `preview.png` when the terminal is kitty or ghostty (each screenshot is fetched the first time it's shown). The wallpaper menu previews each image of the current theme, and your own images in `~/.config/omadora/backgrounds/<theme>/` join a theme's wallpapers. The menus also have direct commands: `theme pick`, `theme bg`, `theme bg next` and `theme update`, plus `theme set <name>`, `theme preview <name>` and `theme list`.

`theme` keeps a sparse clone of my Omadora fork in `~/.local/share/omadora` (the themes, the templates and the two scripts that resolve a palette and render the templates: a few hundred KB, with a theme's wallpapers fetched only when it's first picked) and runs Omadora's own scripts from it, so palettes and derived colors are identical to Linux. Those scripts need bash 4+, hence Homebrew's `bash` in the Brewfile; `theme` itself runs on the system bash.

Applying a theme renders the templates into `~/.config/omadora/current/theme`, sets the wallpaper, flips macOS between light and dark to match the theme's mode, and reloads the running kitty, ghostty and btop. It also writes the palette straight into every terminal of yours with color escape sequences, so a window that misses the reload signal still updates. Then it runs the hooks in `~/.config/omadora/hooks/theme-set.d` (sources in `macos/.config/omadora/hooks`), the same mechanism Linux uses:

- starship and Zed re-render.
- Neovim gets an NvChad theme generated from the palette (the `nvchad-sync` hook, shared by every OS). The hook also recompiles NvChad's highlight cache, so even a Neovim started later is themed, and it reloads running ones. The background is transparent, so the terminal's opacity and blur show through.
- sketchybar and the window borders take new colors from `themed/macos-colors.sh.tpl`.
- btop is pointed at the rendered theme.
- macOS's own accent color and folder/icon tint move to the nearest of the eight colors macOS offers (`macos-accent` hook). Finder and the Dock are restarted when the folder color changes, since they don't reliably redraw it themselves, so a copy in progress at that moment is interrupted; `THEME_SKIP=finder` avoids that.

The installer applies `gruvbox-classic` the first time only, so rerunning it never undoes a theme picked since. It is the classic Gruvbox Dark this Mac always had, kept as a user theme in `macos/.config/omadora/themes`; Omadora's own `gruvbox` is the softer gruvbox-material variant.

## Linux (Arch + Omadora)

`linux/arch/install.sh` assumes a minimal Arch install (archinstall, no desktop environment or display manager, NetworkManager) with a user account already created. The desktop itself comes from my [Omadora](https://github.com/FernandoJVideira/omadora) fork (`arch` branch): Hyprland, the Quickshell shell, the SDDM login screen and their packages. Concretely, it:

1. Installs `gum` (for the prompts below), `zsh` (set as the default shell), `git` and `base-devel`.
2. Asks a few questions interactively via `gum`: whether to set up gaming tools, install Discord, and install OBS.
3. Clones Omadora into `~/.local/share/omadora` over HTTPS and runs its installer. On a first install that installer ends with a reboot, so run `./bootstrap.sh` again afterwards to finish. On a machine that already has the checkout it only fast-forwards it (use `omactl update` to apply updates).
4. Symlinks the Arch-specific dotfiles after Omadora is in place, so my configs win over its defaults, then installs the remaining packages: Zed, Element, kitty, the zsh config's tools, and from the AUR Brave Origin, Proton Pass CLI, OpenDeck and Spotify.
5. Enables the Proton Pass SSH agent. It only starts once your personal access token is in `~/.config/proton-pass-cli/pat`; until then the unit is skipped.
6. Runs the shared dotfiles installer, re-applies the current theme with `omactl theme set`, and renders the starship prompt and the Zed theme.

The previous Arch flow (CachyOS + Omarchy through omarshell) is preserved at the `arch-omarshell-final` tag. This flow has been tested in a VM only; Plymouth, NVIDIA driver packages and real-hardware features (Bluetooth, fingerprint, FIDO2) are not set up or verified yet. On Arch, monitors are set directly in `~/.config/hypr/monitors.lua`.

## Linux (Nobara + Omadora)

`linux/nobara/install.sh` assumes a Nobara (or other Fedora-family) install with a user account already created. The desktop itself comes from my [Omadora](https://github.com/FernandoJVideira/omadora) fork (`nobara` branch): Hyprland, the Quickshell shell, the login screen and their packages. Concretely, it:

1. Installs `zsh` and sets it as the default shell, same as the Arch flow, plus `git`.
2. Clones Omadora into `~/.local/share/omadora` over HTTPS and runs its installer. On a machine that already has the checkout it only fast-forwards it (use `omactl update` to apply updates).
3. Installs the remaining packages: Hyprland/Quickshell runtime dependencies, Zed, Discord, Spotify, the zsh config's tools, Proton Pass CLI, Brave Origin, and mise itself.
4. Symlinks the Nobara-specific dotfiles after Omadora is in place, so my configs win over its defaults, then enables the Proton Pass agent and the crash watcher.

## Common

All platforms end at `common/install.sh`. It symlinks the shared configs and, on first run, clones tmux's plugin manager into `~/.config/tmux/plugins/tpm` before installing the tmux plugins. It also installs Miniconda to `~/miniconda3` with Anaconda's own installer (`lib/miniconda.sh`, SHA256-checked, never runs `conda init`). The same prefix on every OS lets its shell setup live once in `common/.config/zsh/.zshenv`: `conda` is on `PATH` everywhere, and the activation hook loads on first use, with `base` not auto-activated. A fresh install still needs Anaconda's Terms of Service accepted before conda can use its default channels; the installer prints the commands rather than accepting for you.

Dev tools are installed with mise on every OS, from one tracked list, `common/.config/mise/conf.d/dotfiles.toml`: Go, Node, pnpm, Java (Temurin 27 and 17), .NET 10, Neovim, `gh`, `just`, `cloudflared`, golang-migrate, Herdr and Claude Code. `lib/mise.sh` runs `mise install` for it after the symlinks go down, so a new tool is one line in that file, and `mise upgrade` moves a machine forward. It lives in `conf.d` so it merges with a machine's own `~/.config/mise/config.toml` instead of replacing it. Package managers keep the GUI apps, the shell utilities the prompt runs on every command, hugo (mise's build lacks the extended SCSS support) and tmux (mise's build lags Homebrew's and Arch's, so only Nobara takes it from mise, through its own `conf.d` file).

It also installs the latest release of my `draft` scaffolding CLI from [git.fernandovideira.com](https://git.fernandovideira.com/FernandoJVideira/draft/releases) (`lib/draft.sh`, macOS arm64 and Linux amd64, the only builds published) to `~/.local/bin/draft`. It does so when draft is missing or older than the release, so rerunning `./bootstrap.sh` is how a machine updates. The releases publish no checksums, so the download is trusted over TLS and has to report the release's version when run; if a release ever ships a `checksums.txt` or `SHA256SUMS` asset it is verified, and a mismatch installs nothing.

### Claude Code skills

Skills in `common/.claude/skills/<name>/SKILL.md` are linked into `~/.claude/skills` on every OS by `common/install.sh`; OS-specific ones, like Nobara's, live under `linux/<distro>/.claude/skills`. Claude Code lists a new skill from the next session on. How to call each one, with example prompts, is in [docs/skills.md](docs/skills.md).

`coordinator` is the one for multi-file work, and a mode like caveman: `/coordinator` turns it on for the session and `stop coordinator` turns it off. It's an Opus coordinator that never writes production code. It first discovers whether the project is a monorepo, client-only or separate API/client repos (and where the Go code and the Vue or Nuxt app are), then runs a 5-step workflow (discover, plan, implement, verify, review) with Sonnet workers (`subagent_type: "worker"`, falling back to `general-purpose` if that agent type isn't defined) and Haiku leaf helpers for mechanical work. Every agent works in caveman mode, the coordinator included: sub-agents get a `COMMS:` line in each prompt, so replies are terse and carry only facts. The coordinator's instructions to them, its questions to you and its explanations stay in plain sentences, and code is never compressed. Workers are told to comment code only where extremely necessary.

The coordinator is also your architecture partner and teacher: before anything is built it discusses ideas, weighs options, evaluates your suggestions honestly and explains why. Once work starts it supervises the agents it spawned. Workers message it only when blocked or stuck, or with evidence-backed suggestions (its word is final for them, yours for it). A small watcher script (`references/watch-slices.py`) flags out-of-scope edits and idle workers, and the coordinator can guide, redirect, stop (`TaskStop`) or replace a worker, within hard caps so nothing loops. Its detail lives in `references/`, which is read only when needed. Frontend slices get a `DESIGN:` block with the resolved style brief, so every worker builds to `vue-ui-design`.

`vue-ui-design` builds Vue and Nuxt screens with my UI kit (`@fernandojvideira/vue-ui-kit`, shadcn-vue style) and keeps them minimal enough not to look generated. The look is set per prompt with knobs (`style: accent=teal radius=sm density=compact ...`) that map onto the kit's CSS tokens, and a project keeps its own brief as a comment in its main CSS. It adapts Anthropic's `frontend-design` skill (Apache-2.0) and s1gmamale1's [apple-design-skills](https://github.com/s1gmamale1/apple-design-skills) (MIT); `NOTICE.md` has the commits and what came from each.

`caveman` is installed alongside it: Julius Brussee's [Caveman](https://github.com/JuliusBrussee/caveman), release v4.0.1, vendored unchanged (with its Apache-2.0 and MIT texts and a `NOTICE.md` that says how to update it) so machines without my Claude account's skill sync have it. The same release's `ultracave` and `megacave` come with it, because `/caveman ultra` and `/caveman wenyan` hand over to them. Upstream's plugin, hooks and installer are not vendored, since they edit `~/.claude/settings.json`. `stop caveman` turns it off.

`humanizer` rewrites AI-sounding prose (Siqi Chen's [Humanizer](https://github.com/blader/humanizer), MIT) from my [fork](https://github.com/FernandoJVideira/humanizer), vendored at a pinned commit (`NOTICE.md` lists it and how to update). The fork adds one pattern, "The same point twice": it counts facts, not words, so a point that comes back reworded (a restated sentence, a preview plus an "In summary", a heading echoed by its first sentence, twin words) is kept once, in its best place. This machine's Claude account also syncs an older upstream `humanizer` under the `anthropic-skills:` prefix; the two don't replace each other.

### Zed

`common/.config/zed/` holds Zed's `settings.json`, `keymap.json` and the extension list (`auto_install_extensions`). A new extension added through Zed's UI has to be added to that list to reach the other machines. Zed installs the listed extensions on first launch, and `zed-extensions-check` compares what is installed on the current machine with the list (missing ones, and ones installed here but not listed), so run it after the first launch on a new machine.

The theme is always called "Desktop Theme". `zed-theme-sync` renders `desktop-theme.json.tpl` from the current Omadora theme's `colors.toml` at install time and from the `theme-set` hook (`omactl theme set` on Linux, the `theme` command on macOS), and Zed re-applies it live. The template is a conversion of Zed's own Gruvbox theme (MIT) with the palette swapped in, so it covers the whole UI. Zed's terminal font is Hack Nerd Font Mono, installed on every OS. Zed's prompt library (`~/.config/zed/prompts`) is a binary database Zed manages itself, so it isn't tracked.

### Spotify

Spicetify is installed on every OS by `lib/spicetify.sh`: the release tarball goes into `~/.spicetify`, checked against the SHA256 GitHub publishes. Arch's AUR has Spicetify and Fedora and Terra don't, so one installer covers all three.

It themes Spotify from the current OS theme with a colors-only theme, `omadora`, which keeps Spotify's own layout and swaps in the palette. Omadora's template engine renders `common/.config/omadora/themed/spicetify-color.ini.tpl` on every theme change, and the `spicetify-sync` hook runs `spicetify-theme-sync`, which copies the result into the theme and applies it (`backup apply` the first time, a quick `refresh` afterwards). A running Spotify is restarted afterwards so it shows the new colors (playback stops; `THEME_SKIP=spotify` leaves it running), and a closed one stays closed.

It needs Spotify started at least once, and a Spotify update undoes Spicetify's patch: run `spicetify-theme-sync --force` afterwards. On Arch the installer makes `/opt/spotify` writable for it; spotify-launcher (Nobara) installs into the home directory, so nothing is needed there.

### Herdr: Neovim with Claude Code below it

Keys, concepts, and how to restart from scratch: [docs/herdr.md](docs/herdr.md).

[Herdr](https://herdr.dev) is installed on every OS through mise, next to a standalone `claude`. `hdev [dir]` (`common/.local/bin`) opens a project in it: a workspace named after the directory, Neovim in the top pane, and Claude Code started in a pane docked below it (`herdr agent start`, so Herdr tracks it as an agent), with a plain shell split off to its right. Run it again for the same project and it goes back to the agent that is already there instead of making a new one. If the project's workspace already exists (a plain shell you were using, say), the layout is added to it as a `dev` tab and what is there is left alone. Outside Herdr it attaches to the persistent session; inside it just focuses the workspace. `HDEV_AGENT` (any agent kind Herdr knows, or `none`), `HDEV_EDITOR`, `HDEV_RATIO` (how much height the editor keeps, 0.6 by default), `HDEV_TERM` (`right`, `down` or `none` for the shell) and `HDEV_TERM_RATIO` change the layout. Only Herdr's own CLI is used, plus `jq`.

`Ctrl+h/j/k/l` move across Neovim splits and Herdr panes as one set of windows, so you can go from the editor straight down into the Claude pane: Herdr's `herdr-nvim-nav` plugin (installed by `lib/herdr.sh`) and its Neovim half (`lua/plugins/herdr.lua`, set up from `mappings.lua` after NvChad's own `<C-hjkl>` maps). It is third-party code that Herdr runs on every one of those keys, so it is pinned to the commit that was read in full before being adopted (about 200 lines of C that only read a marker file and talk to Herdr's local socket, plus one Lua module); to move to a newer version, read the diff and change the SHA in `lib/herdr.sh` and `lua/plugins/herdr.lua`. Herdr asks for confirmation before installing it when the installer runs in a terminal.

Neovim opens with the file tree showing and the cursor in the editor (not for headless runs, diffs or git's commit editor), and `:q`, `:wq` and `ZZ` in the last window close the tree too, so they quit Neovim; both are in `lua/autocmds.lua`.

Herdr follows every Omadora theme, user themes like `gruvbox-classic` included. Its base theme is the `terminal` one, which takes its colors from the host terminal's palette, and `herdr-theme-sync` (`common/.local/bin`) adds the colors that need care: the active row, the buttons, the active tab and the dim labels. The terminal's 16 ANSI colors only guarantee contrast between background and foreground, so these are built from the theme's own palette and each text/background pair is moved until it reaches 4.5:1 (checked against all 25 themes). The `herdr-sync` theme hook (`common/.config/omadora/hooks/theme-set.d`, run by `omactl` and the macOS `theme` command alike) runs it on every switch, reloads the server and nudges the attached client to redraw.

Because Herdr has no include or theme files, its tracked config is `common/.config/herdr/config.base.toml`; `herdr-theme-sync` writes the real `~/.config/herdr/config.toml` from it (the installer does too, replacing the old symlink). Edit the base file, not the generated one, which Herdr's own settings screen also writes to and the next theme change overwrites. Its keys need the plugin installed, or `Ctrl+h` does nothing in a pane, so the installer installs the plugin before it reloads the config.

### Learning Neovim

`:Tutor nvchad` (`<leader>lt`) is an interactive lesson about this config, in Neovim's own tutorial format: 14 exercises where you edit a line until it matches the target (a check mark appears), covering modes, operators and motions, counts and text objects, search/replace, and a tour of the NvChad keys, including this config's `;` for the command line and `jk` for Escape. `:Tutor` (`<leader>lT`) is the classic vimtutor. `<leader>lg` opens vim-be-good, a practice game for motions, and `<leader>lp` toggles precognition, which shows the motions available from the cursor (off until toggled). `<leader>l` is the "learn" group in which-key, `<leader>ch` is NvChad's cheat sheet and `<leader>wK` lists every mapping. NvChad's starter config disables Neovim's bundled `tutor` plugin, which provides `:Tutor`; it is enabled again in `lua/configs/lazy.lua`.

### tmux

The status line in `tmux.conf` uses plain ANSI color names, so it follows whatever palette the terminal has: the current theme's, live, with no hook or reload (kitty is re-rendered on every theme change on both Linux and macOS).

## A note on safety

Some of what these scripts touch is not easily undone: NVIDIA driver setup, `mkinitcpio` regeneration, macOS system defaults. I've run each install path against my own hardware before trusting it, but "works on my machine" is doing a lot of lifting here. Read a script before you run it, especially on Linux.
