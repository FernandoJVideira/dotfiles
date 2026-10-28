# Using this setup

The README explains how the repo is built. This guide is for living in what it installs: how a working
day goes, which keys do what, how to change things, and what to check when something looks wrong. The
deeper references are [herdr.md](herdr.md) (multiplexer), [claude-review.md](claude-review.md)
(reviewing Claude's edits in Neovim) and [skills.md](skills.md) (Claude Code skills).

## Contents

1. [Setting up a machine](#setting-up-a-machine)
2. [A working day](#a-working-day)
3. [The shell](#the-shell)
4. [Neovim](#neovim)
5. [Claude Code](#claude-code)
6. [Themes](#themes)
7. [The desktop](#the-desktop)
8. [Dev tools and the draft CLI](#dev-tools-and-the-draft-cli)
9. [Keeping it up to date](#keeping-it-up-to-date)
10. [When something looks wrong](#when-something-looks-wrong)
11. [Where things live](#where-things-live)

## Setting up a machine

Clone the repo and run the entry point. It picks the macOS, Arch or Nobara installer by itself, and every
script is safe to run again.

```bash
git clone https://github.com/FernandoJVideira/dotfiles.git ~/Developer/Personal/dotfiles
cd ~/Developer/Personal/dotfiles
./bootstrap.sh
```

On a first Arch install, the Skein installer ends with a reboot, so run `./bootstrap.sh` once more
afterwards. The last lines of the output list anything that still needs you:

- `~/.npmrc` and, on Linux, `~/.config/proton-pass-cli/pat` are created with a `REPLACE_WITH_...`
  placeholder where a token goes. Replace it with a Gitea token that has the `package` scope for the
  first file, and a Proton Pass personal access token for the second. A file that already exists is
  never touched. Once `pat` holds a real token, run `systemctl --user restart proton-pass-agent.service`.
- Conda needs Anaconda's Terms of Service accepted before it can use its default channels. The installer
  prints the commands and leaves the decision to you.
- Register Cloudflare WARP: `warp-cli registration new` (it asks you to accept Cloudflare's terms), then
  `warp-cli connect`. On macOS, open the WARP app from the menu bar instead.
- Start Spotify once, so Spicetify has something to theme.
- Open Zed once, then run `zed-extensions-check` to compare its extensions with the tracked list.
- Reboot once after the installer. The login screen is now the Quickshell greeter (greetd), and on Nobara
  the KDE removal runs at that boot, before it (`journalctl -u skein-remove-kde` shows how it went). If the
  login screen doesn't appear, Ctrl+Alt+F3, log in and run `skein-greeter rollback`.

Edit files in the repo, not in your home folder. Every file under `common/`, `macos/` and `linux/<distro>/`
is symlinked to the same path under `$HOME`, so a change is live as soon as you save it. A file you add
to the repo only gets its link the next time the installer runs, or when you create it yourself with
`ln -sf`.

## A working day

Open kitty in a project folder and run `hdev`, or `h` for short.

```
┌──────────────────────────────┐
│ Neovim (file tree open)      │
├──────────────┬───────────────┤
│ Claude Code  │ plain shell   │
└──────────────┴───────────────┘
```

Each project gets one Herdr workspace named after its folder, with that layout in a `dev` tab. Run `hdev`
again in the same folder and it takes you back to the Claude that is already running. The workspaces and
the agents' states (working, blocked, done) are in the sidebar, so you can start a task, switch to
another project, and come back when a workspace shows blocked or done.

| Keys | What it does |
|---|---|
| `Ctrl+h/j/k/l` | move between Neovim splits and Herdr panes as one set of windows. On Linux `Super+h/j/k/l` does the same from a terminal, and moves between Hyprland windows from any other app |
| `Ctrl+B` then `z` | zoom the current pane, again to undo |
| `Ctrl+B` then `g` | picker of every agent, by workspace |
| `Ctrl+B` then `w` | switch workspace |
| `Ctrl+B` then `c` / `v` / `-` | new tab / split right / split down |
| `Ctrl+B` then `q` | detach; everything keeps running |

`herdr` reattaches. `hs` (`herdr server stop`) ends the session and every process in it, Neovim and Claude
included, so save first. Run Herdr straight in kitty, not inside tmux: both use `Ctrl+B`. The complete key
list, the `hdev` options and the way to start from scratch are in [herdr.md](herdr.md).

## The shell

The shell is zsh with vi mode, starship for the prompt, fzf and zoxide for moving around, and fastfetch on
startup. Syntax highlighting, autosuggestions and substring history search are on.

| Key | What it does |
|---|---|
| `Ctrl+F` | fzf file picker (no hidden files) |
| `Ctrl+T` | fzf file picker with a preview |
| `Tab` | fzf-tab completion |
| `Up` / `Down` | history search by what you have typed so far |
| `Ctrl+Left` / `Ctrl+Right` | move by word |
| `Ctrl+\` | toggle autosuggestions (handy when recording the screen) |
| `Esc` | vi normal mode; the cursor changes shape |

| Alias | Runs |
|---|---|
| `ls`, `ll`, `la`, `tree` | eza, with icons and git status |
| `cat`, `grep` | bat, ripgrep |
| `j` | zoxide jump to a folder you have used before |
| `lf` | file manager that leaves your shell in the folder you ended in |
| `-` | `cd -` |
| `vim` | nvim |
| `zd` | `zed .` |
| `glog`, `gadog` | git log, and the all-branches decorated graph |
| `sz` | reload `.zshrc` |
| `c`, `ip`, `myip` | clear, local addresses, public address |
| `h`, `hs` | `hdev`, `herdr server stop` |
| `upd` | macOS only: `brew update && brew upgrade` |

`nexus` and `atlas` are ssh shortcuts to two servers, and `ssh` itself runs with `TERM=xterm-256color`.

tmux still exists for plain terminals and remote machines. Its prefix is `Ctrl+Space` (`Ctrl+B` also
works). After the prefix: `v` splits side by side, `h` splits stacked, `c` opens a window, `x` closes
a pane, `r` renames, `q` reloads the config and `?` shows every binding. `Alt+1` to `Alt+9` jump to a
window and the mouse is on. Its colors follow the terminal's palette, so it changes with the theme
without a reload.

## Neovim

Neovim is NvChad with this repo's changes on top. The leader key is `Space`; pressing it and waiting
shows which-key's menu of what comes next.

It opens with the file tree on the left and the cursor in the editor. `:q`, `:wq` and `ZZ` in the last
window close the tree too, so they quit Neovim. Line numbers are relative, with the current line's
number bold and its line tinted so you can find the cursor at a glance. Open files reload within a
second when something else writes them, which is how Claude's edits appear.

| Keys | What it does |
|---|---|
| `;` | command line (same as `:`) |
| `jk` | leave insert mode |
| `<leader>ff` | find files |
| `<leader>fa` | find files, hidden ones included |
| `<leader>fw` | live grep |
| `<leader>fb` / `fo` / `fz` | buffers / recent files / search in this buffer |
| `<leader>fA` / `fW` | the same two searches with `node_modules`, `vendor`, `dist` and other generated folders included |
| `<leader>gt` | changed files, with a diff preview |
| `<leader>ch` | NvChad cheat sheet |
| `<leader>wK` | every mapping |

Telescope leaves out `node_modules`, `vendor`, `dist`, `build`, `.next`, `.nuxt`, `.git` and a few more
folders at any depth. The list is at the top of `lua/plugins/init.lua`.

To learn Neovim in place, `<leader>lt` opens a 14-exercise interactive tutorial about this exact config,
`<leader>lT` the classic vimtutor, `<leader>lg` a motion practice game and `<leader>lp` toggles hints
for the motions available from the cursor.

## Claude Code

Claude runs in its own pane, so Neovim and Claude stay separate. Two things connect them.

Run `/ide` in Claude once per session and pick Neovim. After that, an edit Claude proposes opens as a
diff in Neovim: `<leader>aa` accepts it, `<leader>ad` rejects it, and `do` on a change drops just that
part. For edits Claude has already made in auto mode, `]h` and `[h` walk the hunks, `<leader>ha` accepts
one and `<leader>hd` puts the old lines back. To ask for a change, select lines, press `<leader>as` to
send them to Claude, then `Ctrl+j` down to its pane and type. Everything is laid out in
[claude-review.md](claude-review.md).

`Shift+Tab` in Claude cycles its modes: asking before every edit, applying them directly (auto mode), and
planning. Paste an image with `Ctrl+V`, not `Cmd+V`.

The skills are slash commands. The first two are modes that stay on for the session:

| Command | What it does |
|---|---|
| `/coordinator` | an Opus coordinator splits the task, sends Sonnet workers to implement it, checks their work and talks design with you before anything is built. `stop coordinator` ends it |
| `/caveman` | terse replies with every technical fact kept. `stop caveman` ends it |
| `/vue-ui-design` | builds Vue and Nuxt screens with the UI kit, in a minimal style. The look is set per prompt, for example `style: accent=teal radius=sm density=compact` |
| `/humanizer` | rewrites AI-sounding prose, and cuts repeats. Give it a file name to edit that file |

Example prompts and the full list of `style:` options are in [skills.md](skills.md).

## Themes

One theme drives the terminals, Neovim, Zed, the prompt, Spotify, btop, tmux, Herdr, and on macOS the
menu bar, the window borders and the system accent color.

- macOS: `Alt+Shift+T` opens a popup to pick a theme. `theme` in a terminal opens a fuller menu (theme,
  wallpaper, next wallpaper, update) with previews. `theme set <name>`,
  `theme list` and `theme preview <name>` skip the menu.
- Linux: `skeinctl theme set <name>`.

Applying a theme re-renders each app's colors from one palette and reloads what is running. The default
on a new Mac is `gruvbox-classic`, a user theme kept in `macos/.config/skein/themes`. Your own wallpapers
go in `~/.config/skein/backgrounds/<theme>/` and join that theme's set.

A switch restarts Spotify so it shows the new colors, which stops playback, and restarts Finder and the
Dock when macOS's folder color changes. `THEME_SKIP=spotify`, `THEME_SKIP=finder` or both
(`THEME_SKIP=spotify,finder`) leave them alone.

## The desktop

On macOS, Hyprspace tiles windows, with sketchybar as the bar and `borders` outlining the focused window.
The bar follows Skein's: flat, in the theme's colors, icon-only, with a module's value showing while the pointer is over it. Workspaces are numbers with a dot for the one in use (1-5 always, 6-10 while they have windows), and the clock splits around the notch: the day on its left, the time on its right. Three popups mimic Skein's menus: the Skein glyph opens a menu (theme, next wallpaper, update themes, lock, sleep, restart, shut down), the clock opens a calendar and the volume icon opens a slider. The old bar is tagged `backup/sketchybar-2026-10-28`; `git checkout backup/sketchybar-2026-10-28 -- macos/.config/sketchybar` brings it back, then `sketchybar --reload`.
`alt` is the window modifier:

| Keys | What it does |
|---|---|
| `Cmd+Enter` | new kitty window |
| `Alt+h/j/k/l` | focus left, down, up, right |
| `Alt+Shift+h/j/k/l` | move the window |
| `Alt+Tab` | back to the previous window |
| `Ctrl+1` to `Ctrl+9`, `Ctrl+0` | workspaces 1 to 10 |
| `Ctrl+Shift+1` to `0` | send the window to that workspace |
| `Alt+f` | fullscreen |
| `Alt+Shift+Space` | toggle floating |
| `Alt+Shift+/` and `Alt+Shift+,` | tiles layout, accordion layout |
| `Alt+-` / `Alt+=` | shrink / grow |
| `Alt+Shift+;` | service mode: `Esc` reloads the config, `r` flattens the workspace, `f` floats |
| `Cmd+Shift+W`, `Cmd+Shift+E`, `Alt+M`, `Alt+Shift+P` | Safari, Zed, Spotify, btop |
| `Alt+Shift+T` | theme picker popup with a thumbnail per theme (fuzzy search, Enter applies) |

Apps open on fixed workspaces: editors on 1, terminals on 2, browsers on 3, Claude's desktop app on 4,
Finder on 5, TablePlus on 6, Bruno on 7, Discord on 8, Obsidian and Notion on 9, music on 10. Workspaces
are pinned to monitors by name in `macos/.config/hyprspace/config.toml`.

On Linux the desktop is Hyprland and Quickshell from the Skein fork, and Skein supplies the key
bindings, so use its own cheat sheet for those. One thing this repo changes: Caps Lock is a second Super
key, and it is Caps Lock again while a game has focus, whether it came from Steam, Lutris or Heroic.
`Super+Ctrl+F12` forces real Caps Lock for a game that isn't recognised, and again to undo it.
`capslock-mode status` shows what the script sees in the focused window. `Super+h/j/k/l` moves between
panes when a terminal has focus and between windows in every other app; from a terminal, use
`Super+arrows` to change window. This repo only adds `hyprland.lua`, `monitors.lua`
and a few related files under `linux/<distro>/.config/hypr`. Monitors are set in
`~/.config/hypr/monitors.lua`.

## Dev tools and the draft CLI

mise installs the dev tools on every OS from one tracked list, `common/.config/mise/conf.d/dotfiles.toml`:
Go, Node, pnpm, Java (Temurin 27 and 17), .NET 10, Neovim, gh, just, cloudflared, golang-migrate, Herdr
and Claude Code. tmux and hugo stay with the system package manager (Nobara takes tmux from mise).

```bash
mise ls                       # what is installed and where it is set
mise use --global <tool>      # adds a tool for this machine only
mise use <tool>@<version>     # pins one for the current project (writes .mise.toml)
mise upgrade                  # moves everything forward
```

A tool every machine should have is one line in `conf.d/dotfiles.toml`. `./bootstrap.sh` only installs what
is missing, so versions don't move until you run `mise upgrade`. Go is pinned to `1.27.3`.

`draft` scaffolds projects:

```bash
draft new api         # a Go API
draft new client      # a Nuxt or Vue client
draft new monorepo    # both in one repo
draft new handler     # a handler
draft new service     # a service
draft key             # a new cryptographic key
draft version
```

`./bootstrap.sh` installs the latest release when `draft` is missing or older, so rerunning it updates draft.
Generated clients use `@fernandojvideira/vue-ui-kit`, which npm and pnpm fetch from the Gitea registry
using the token in `~/.npmrc`.

## Keeping it up to date

| To update | Run |
|---|---|
| this repo's config on a machine | `git pull`, then `./bootstrap.sh` |
| Homebrew packages (macOS) | `upd` |
| Skein and the Linux desktop | `skeinctl update` |
| dev tools | `mise upgrade` |
| Spotify's theming after a Spotify update | `spicetify-theme-sync --force` |

To change something, edit the file under `common/`, `macos/` or `linux/<distro>/`, commit it, and
`git pull` on the other machines. Two things are generated and shouldn't be edited by hand: Herdr's
`~/.config/herdr/config.toml` (edit `config.base.toml` beside it in the repo) and anything under
`~/.config/skein/current`.

## When something looks wrong

| Symptom | What to check |
|---|---|
| `hdev: command not found` | `~/.local/bin` isn't linked or on the PATH: run `./bootstrap.sh` |
| `Ctrl+h` does nothing in Herdr | the navigation plugin isn't installed: `herdr plugin list`, then `./bootstrap.sh` |
| Herdr's colors lag behind a theme switch | resize the window, or `Ctrl+B` then `Shift+R` |
| the Claude pane is stuck on a startup prompt | click into it and answer it, usually the folder trust question |
| `/ide` doesn't list Neovim | Neovim has to be running in the same project folder |
| Caps Lock doesn't switch in a game (Linux) | `capslock-mode status` shows the class and process it sees and the option it wants and has; `Super+Ctrl+F12` forces it meanwhile |
| no cursor-line tint or bold line number in Neovim | `:lua require('nvchad.utils').reload()` rebuilds the highlight cache |
| a tool is missing after `./bootstrap.sh` | `mise install` shows which one failed and why |
| Spotify isn't themed | start it once, then `spicetify-theme-sync --force` |
| Zed lacks an extension | `zed-extensions-check` |
| an image won't paste into Claude | use `Ctrl+V`, not `Cmd+V`, with an image on the clipboard |
| the Proton Pass agent isn't running | put a real token in `~/.config/proton-pass-cli/pat`, then restart the unit |

## Where things live

| Path | What is there |
|---|---|
| `bootstrap.sh`, `lib/` | the entry point and the shared installer helpers |
| `common/.config/zsh` | shell config, aliases, key bindings, prompt |
| `common/.config/nvim` | Neovim (NvChad plus `lua/plugins`, `mappings.lua`, `autocmds.lua`, `tutor`) |
| `common/.config/herdr`, `common/.local/bin/hdev` | Herdr's base config and the project launcher |
| `common/.config/mise/conf.d` | the tracked dev tool list |
| `common/.config/skein` | theme templates and the hooks that run on every theme change |
| `common/.claude/skills` | Claude Code skills (coordinator, caveman, humanizer, vue-ui-design) |
| `macos/` | Brewfile, Hyprspace, sketchybar, the `theme` command, macOS defaults |
| `linux/arch`, `linux/nobara` | distro installers, Hyprland files, systemd units |
| `linux/common` | what both distros share: the Caps Lock as Super module and its `capslock-mode` script |
