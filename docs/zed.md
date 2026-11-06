# Zed

Zed's settings, keymap and extension list live in the repo and reach every machine the same way. This page
covers what the settings do, the keys, the Hugo image bind, and how to change things.

## Where the config lives

`common/.config/zed/` holds `settings.json` and `keymap.json`, and the installers symlink each file in it
into `~/.config/zed`. Edit the files in the repo. Zed reloads settings on save, so most changes show up
at once. If something does not apply, restart Zed. Both files are JSONC: comments and trailing commas are
allowed.

## What the settings do

Theme. `"theme": "Desktop Theme"` has the same name on every OS. On Linux `zed-theme-sync` renders it
from the current OS theme (see Themes in [guide.md](guide.md)). On macOS the name points at a static
Gruvbox file.

Icons. `"icon_theme": "Warm Charmed Icons"` comes from the `charmed-icons` extension.

Fonts. The buffer and the terminal use Dank Mono, with JetBrainsMono Nerd Font Mono as the fallback.
Buffer and UI font sizes stay at Zed's defaults, and the terminal is 14. Dank Mono is a licensed font, so
the files sit in the gitignored `fonts/` directory and `lib/fonts.sh` installs them. Without them Zed
uses the fallback.

Editing.
- Vim mode is on, with which-key after 500 ms. `base_keymap` is `VSCode`.
- Line numbers are relative. The cursor is a blinking bar.
- Hard tabs are on for Go only. Autosave runs 1000 ms after the last edit.
- Indent guides are colored by indent level, and bracket colorizing, inlay hints, code lens and signature
  help are on.
- The scrollbar is hidden, and tabs mark errors only (no warnings).
- Private values in config files are redacted, and git blame shows inline.

Layout. The project, outline, git and collaboration panels dock on the right. The centered layout uses
0.15 padding on each side. `file_scan_exclusions` hides build output and editor folders such as `dist`,
`out` and `node_modules` from the explorer and from search.

Extensions. `auto_install_extensions` lists what Zed installs on first launch. An extension added from
Zed's UI exists only on that machine until it is listed. `zed-extensions-check` compares the installed
extensions with the list: it reports the missing ones, and the ones installed here but not listed.

Agent and SSH. `claude-acp` is the agent server, from Zed's registry, in `auto` mode with the `sonnet`
model. One SSH connection, `ssh.nexus.fernandovideira.com`, is saved.

## Keys

The Vim leader is `space`. After 500 ms Zed's which-key popup lists the chords that can follow what you
typed. The keymap is ported from [christitustech/zed-titus](https://github.com/christitustech/zed-titus),
with the Hugo clipboard bind moved to `space h i`. Unless noted, these work in Vim normal mode.

| Keys | Action |
| --- | --- |
| `space space`, `space f f` | File finder |
| `space /`, `space f g` | Project search |
| `space s w` | Search from the word under the cursor (normal and visual) |
| `space s b` | Search in the buffer (normal and visual) |
| `space g s` | Git panel (normal and visual) |
| `ctrl-shift-g` | Toggle the git panel (any context) |
| `space g h d` | Toggle diff hunks (normal and visual) |
| `] h`, `[ h` | Next and previous git hunk |
| `g d`, `g D` | Go to definition (`g D` in a split) |
| `g i`, `g I` | Go to implementation |
| `g t`, `g T` | Go to type definition |
| `g r` | Find all references |
| `space c a`, `space .` | Code actions |
| `space c r` | Rename |
| `] d`, `[ d` | Next and previous diagnostic |
| `space x x` | Diagnostics view |
| `s s`, `s S` | File outline, project symbols |
| `shift-h`, `shift-l` | Previous and next buffer |
| `shift-q`, `ctrl-q`, `space b d` | Close the buffer |
| `space b o` | Close the other buffers |
| `ctrl-h`, `ctrl-j`, `ctrl-k`, `ctrl-l` | Move between panes (also in the terminal and project panel) |
| `ctrl-\` | Toggle the terminal |
| `ctrl-b` | Toggle the right dock |
| `space e` | Reveal the file in the project panel |
| `space a c` | Agent panel |
| `space r t` | Run the nearest task |
| `space t i`, `space u w` | Toggle inlay hints, soft wrap |
| `space m p`, `space m P` | Markdown preview, preview to the side |
| `space f p` | Open a recent project |
| `jj`, `jk` | Leave insert mode |
| `g c` | Toggle comments (visual mode) |
| `space h i` | Save a clipboard image (Hugo) |

In the project panel, `a` creates a file, `A` a directory, `r` renames, `d` deletes, `x` cuts, `c` copies,
`p` pastes, and `q` or `space e` closes the panel.

The keymap rebinds `s` and `S` to the sneak motion in normal and visual mode, so Vim's own `s`
(substitute) is not available.

## The Hugo image bind

`space h i` in Vim normal mode runs the task "Save clipboard image (Hugo)". The task is defined in the
portfolio repo (`~/work/hugo_portfolio/.zed/tasks.json`) and runs its `scripts/save-img-hugo`, so the bind
only works while that project is open.

The script saves the clipboard image as webp. In a post bundle (`index*.md`) the image goes next to the
post. Any other `.md` file gets it under `static/images/<year>/`. It then inserts a markdown image link
above the cursor line. It needs `cwebp`, which the installers install, and on Linux `wl-paste` (Wayland)
or `xclip` (X11).

## Changing things

- Add an extension: install it from Zed, then add its folder name from the `extensions/installed`
  directory to `auto_install_extensions`. Otherwise it stays on one machine.
- Change a key: edit `keymap.json`. Each block has a context that decides where its keys apply. Run
  `zed: open default keymap` from the command palette to look up action names.
- Change the theme: switch the OS theme. Zed follows it. Do not edit the rendered theme file, because the
  next sync overwrites it. To change what the theme looks like, edit `desktop-theme.json.tpl`.

## When something looks wrong

- Zed shows a config error banner: check the JSONC syntax of the file it names, usually a missing comma
  or quote.
- Icons or the theme are missing: run `zed-extensions-check`, open Zed while online so it installs what
  is missing, then restart Zed.
- `space` chords do nothing: check that `vim_mode` and `which_key` are on in `settings.json`, and that
  the `space` unbind block for `VimControl` is still in `keymap.json`.
- The Hugo bind does nothing: open the portfolio project, check that `cwebp` is installed, and copy an
  image to the clipboard first.
