---
name: nobara-desktop
description: >
  REQUIRED for end-user customization of this Nobara desktop. Use when editing
  ~/.config/hypr/, ~/.config/quickshell/, ~/.config/illogical-impulse/,
  ~/.config/matugen/, or the kitty/zsh setup. Triggers: Hyprland, keybindings,
  window rules, monitors, keyboard layout, default terminal/browser, end4-pC,
  illogical-impulse, Quickshell, bar, sidebar, wallpaper, theming, matugen,
  the AI sidebar model, install scripts, dotfiles.
---

# Customizing this Nobara desktop

The desktop is **Hyprland + Quickshell**, configured by *illogical-impulse*
(end-4/dots-hyprland, "ii") with the **end4-pC** shell (the user's fork
FernandoJVideira/end4-pC of pctrade/end4-pC) loaded on top. Everything is laid
down by the user's dotfiles repo (github FernandoJVideira/dotfiles, branch
`feature/nobara-end4pc`, `linux/nobara/install.sh`). This is the Nobara
counterpart of the `omarchy` skill on the Arch machine - Omarchy's commands
(`omarchy-*`, `omarchy theme set`) do NOT exist here.

## Where things live - edit the right layer

**Hyprland** - `~/.config/hypr/hyprland.lua` sources upstream files in
`~/.config/hypr/hyprland/` (env, execs, general, rules, colors, keybinds,
variables), then optional user overrides in `~/.config/hypr/custom/`:
`env.lua`, `execs.lua`, `general.lua`, `rules.lua`, `keybinds.lua`,
`variables.lua`. **Only edit `custom/`.** The upstream files get reset by
illogical-impulse's installer. Examples already in use:
- `custom/general.lua` - `hl.config({ input = { kb_layout = "pt" } })`
- `custom/variables.lua` - plain Lua globals overriding `terminal`,
  `fileManager`, `browser`, `codeEditor`, ... (defaults are in
  `hyprland/variables.lua`; SUPER+Return/T use `terminal`, SUPER+W `browser`,
  SUPER+E `fileManager`, SUPER+C `codeEditor`). The install script sets `browser` to
  Brave Origin (`brave-origin-stable`) when it's installed; the terminal is the
  upstream default, kitty.
Apply with `hyprctl reload`. The Lua API is `hl.bind`, `hl.config`,
`hl.dsp.*` - copy the style of `hyprland/keybinds.lua`.

**Shell (Quickshell)** - `qs -c end4-pC`, source in
`~/.config/quickshell/end4-pC` (a git clone of the user's fork). Restart it
with `killall qs; qs -c end4-pC &` (keybind Ctrl+Super+R). Run it in the
foreground to see real errors. QML changes belong in the fork as commits - tell
the user before editing them in place.

**Shell settings** - `~/.config/illogical-impulse/config.json`, shared by ii
and end4-pC (edit via the Settings app, SUPER+I, or `jq`). Keys used so far:
`apps.terminal` (launcher's run-in-terminal command), `appearance.
wallpaperTheming.enableTerminal` (live terminal theming), `policies.ai`
(0 off / 1 online / 2 local-only), `ai.*`.

**Theming** - matugen builds Material You colors from the wallpaper. Terminals
are themed live by pushing OSC color sequences to every open pty
(`scripts/colors/applycolor.sh`), which works for any terminal. Matugen
templates live in `~/.config/matugen/config.toml.orig` (the source of truth;
`config.toml` is regenerated from it).

**AI sidebar** - SUPER+A, `/model claude-code` selects the Claude Code backend
(`services/ai/ClaudeCodeApiStrategy.qml`, shells out to `claude -p` and resumes
sessions). `/model <name>` switches models; `/key` sets API keys for the others.

**Terminal/shell** - kitty (patched to `shell zsh`), zsh config from the
dotfiles repo (`common/.config/zsh`): aliases, starship, fzf-tab, zoxide.

**Crash watcher** - the `crash-watch` user service (`systemctl --user status crash-watch`)
follows systemd-coredump entries in the journal and notifies "Process crashed" with a
*Diagnose with Claude* action, which runs `nobara-crash-diagnose <pid>` (kitty + `claude`
+ the diagnose-crash skill). `nobara-crash-mute <program> [off]` silences one program
(list is `~/.config/nobara-crash/muted`); scripts are in `~/.local/bin`, sources in
`linux/nobara/.local/bin/` of the dotfiles repo. It needs journal read access
(wheel/adm/systemd-journal group).

## Useful default keybinds (ii)

SUPER+Return terminal, SUPER+W browser, SUPER+E files, SUPER+C editor,
SUPER+I settings, SUPER+A left sidebar, SUPER+/ cheatsheet, SUPER+Q close,
Ctrl+Super+T wallpaper picker, Ctrl+Super+Shift+D light/dark, Ctrl+Super+R
restart widgets. `hyprland/keybinds.lua` is the full list.

## Rules learned the hard way

- **Never re-run `~/.local/share/illogical-impulse/setup install`.** It reset
  `~/.config/hypr/hyprland/variables.lua` and wiped
  `~/.config/quickshell/end4-pC`; Quickshell then silently fell back to the
  default `ii` look with no error. The dotfiles script only runs it once; use
  `FORCE_II_REINSTALL=1` deliberately or `setup exp-update` for updates.
- **Never install Terra's `terra-release` and don't delete
  `/etc/yum.repos.d/terra.repo`.** That file belongs to Nobara's `nobara-repos`;
  if it goes missing restore it with `sudo dnf reinstall nobara-repos`.
- **dnf5 exits 0 even when a package name doesn't resolve** - it installs the
  rest and only warns. Verify installs with `rpm -q <pkg>`, never the exit code.
- Do not hand-edit anything in `~/.config` that is a symlink into the dotfiles
  repo without saying so - it edits the repo. Persistent changes go in
  `linux/nobara/` (or `common/` if shared with the other machines) and get
  committed; the install script must stay idempotent and safe to re-run.
- Distro detection: Nobara reports `ID_LIKE="rhel centos fedora"`, which
  illogical-impulse's exact-match check misses (it would fall back to a Nix
  install); the script writes an `os-release` override to force the Fedora path.
- The Proton Pass SSH agent needs a personal access token in
  `~/.config/proton-pass-cli/pat` (a secret - never print or commit it).

## Before changing things

Prefer the smallest reversible change, in the override layer, and tell the user
which file changed and how to undo it.
