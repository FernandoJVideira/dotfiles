# Herdr cheat sheet

[Herdr](https://herdr.dev) is a terminal multiplexer for coding agents (think tmux, plus it knows
which agent is working, blocked or done). Keys below are Herdr 0.9.5's defaults; the config
(`common/.config/herdr/config.toml`) only adds `Ctrl+h/j/k/l`. `prefix ?` shows the live list.

## The model

| Thing | What it is |
|---|---|
| **Workspace** | a project. `hdev` makes one named after the folder |
| **Tab** | a view inside a workspace. `hdev` adds a `dev` tab next to your shell |
| **Pane** | a real terminal inside a tab (Neovim is a pane, Claude Code is a pane) |
| **Agent** | a pane Herdr recognizes as a coding agent; its state rolls up to the workspace in the sidebar |
| **Session** | the whole server. One is enough: workspaces already separate projects |

Herdr keeps running in the background. Closing the window or detaching doesn't stop anything.

## The prefix

Almost every key is **prefix + a key**. The prefix is `Ctrl+B`: press it, release it, then press the
key. Below, "`prefix c`" means exactly that. Don't run Herdr inside tmux: this repo's tmux also
has `Ctrl+B` as a prefix and would eat it. Run Herdr straight in kitty.

## Start a project

```bash
cd ~/Developer/some-project
hdev
```

Neovim on top, Claude Code below (`HDEV_AGENT`, `HDEV_EDITOR`, `HDEV_RATIO` change that). A project
is its full path: two folders with the same name are two projects. Run it again and it goes back
to the agent that is already there. If the project's workspace already exists (a plain shell, say),
the layout is added to it as a `dev` tab and the rest is left alone. If Herdr isn't running, `hdev`
starts it in the background first (the saved layout of the last session comes back too) and then
builds the project next to it.

After a Herdr restart the restored `dev` tab is just shells (processes don't survive a restart).
`hdev` notices that the agent isn't running and says so; `hdev --fresh` closes that tab and
builds it again.

## Moving around

| What | Keys |
|---|---|
| Between panes (also in and out of Neovim's splits) | `Ctrl+h` `Ctrl+j` `Ctrl+k` `Ctrl+l` |
| Between panes, plain Herdr | `prefix h` `j` `k` `l`, or `prefix Tab` |
| Zoom a pane to full screen (again to undo) | `prefix z` |
| Next / previous tab, tab 1-9 | `prefix n` / `prefix p`, `prefix 1`...`9` |
| Switch workspace | `prefix w`, then arrows or `j`/`k`, Enter; Esc leaves |
| Jump to any agent | `prefix g`: a picker of all agents by workspace. `/` searches, `b` blocked, `w` working, `i` idle, `d` done, `a` all |
| Open what a notification was about | `prefix o` |
| Show / hide the sidebar | `prefix b` |

## Building and tidying

| What | Keys |
|---|---|
| New tab | `prefix c` |
| Split right / split down | `prefix v` / `prefix -` |
| Resize panes | `prefix r`, then arrows (Esc to finish), or drag a border |
| New workspace | `prefix Shift+N` |
| Rename workspace / tab / pane | `prefix Shift+W` / `Shift+T` / `Shift+P` |
| Close pane / tab / workspace | `prefix x` / `prefix Shift+X` / `prefix Shift+D` |
| Read a pane's scrollback in your editor | `prefix e` |
| Settings / key help / reload config | `prefix s` / `prefix ?` / `prefix Shift+R` |

The mouse works too: click panes, tabs, workspaces and agents, drag borders.

## Reading the agents

| State | Meaning |
|---|---|
| **working** | busy |
| **blocked** | needs you: an approval or a question. Watch for this one |
| **done** | finished and you haven't looked yet |
| **idle** | finished and you've seen it |
| **unknown** | Herdr can't tell |

Start work, switch to another workspace, and let the sidebar tell you when to come back.

## Leaving, coming back, starting over

| What | How |
|---|---|
| Detach (everything keeps running) | `prefix q` |
| Reattach | `herdr` |
| Stop everything | `herdr server stop` |

**`herdr server stop` kills every process in the session** (Neovim, Claude, anything running), so save
work first. And it isn't a reset: the next `herdr` restores the layout (workspaces, tabs, panes,
folders) as fresh shells.

**Starting from scratch.** The saved layout is `session.json` plus `session-snapshots/` in
`~/.config/herdr`. Move them aside (don't delete, so you can undo), then start:

```bash
herdr server stop
mkdir -p ~/.config/herdr/old-session && mv ~/.config/herdr/session.json ~/.config/herdr/session-snapshots ~/.config/herdr/old-session/
herdr
```

Leave everything else in that folder alone: `config.toml` is your config, `plugins/` and
`plugins.json` are the Neovim navigation plugin. To undo, stop the server and move the two
items back. Tried on a throwaway session: stop + start brought the workspaces back, and moving
those two items away gave a single empty workspace.

## Neovim and Claude together

- `Ctrl+h/j/k/l` is one set of windows across Neovim's splits and Herdr's panes
  (the `herdr-nvim-nav` plugin, pinned in `lib/herdr.sh`).
- In Neovim, `<leader>lt` opens the interactive NvChad lesson (`:Tutor nvchad`).
- The first time Claude Code starts in a pane it asks for a text style and maybe a login. Once.

## When something is off

| Symptom | Cause |
|---|---|
| `hdev` lands on an old workspace or dead shells | Herdr restored the last layout (a restart does that). Your project is still there as its own workspace; if its `dev` tab is just shells, `hdev --fresh` rebuilds it. For a really empty start, see "Starting from scratch" above |
| `Ctrl+h` does nothing in a pane | the navigation plugin isn't installed: `herdr plugin list`; run `./bootstrap.sh` or `herdr plugin install aimdevlee/herdr-nvim-nav --ref ec047fd6d8d0269d54a34e9405af28d8aad4c8f0` |
| `hdev: command not found` | `~/.local/bin` isn't linked or on PATH: `./bootstrap.sh` (or `common/install.sh`) |
| Claude pane is a plain shell | no `claude` on PATH: `mise use --global claude-code` |
| A key combo does nothing | the terminal or the OS took it first; `prefix ?` shows what Herdr is bound to |
| Config change not picked up | `herdr config check`, then `prefix Shift+R` |

## Ten-minute practice

1. In a project folder run `hdev`. Use `Ctrl+k` / `Ctrl+j` to go between Neovim and Claude.
2. `prefix z` on Claude, then `prefix z` again.
3. `prefix c`, run `ls`, then `prefix p` back.
4. `prefix g`, then `Esc`.
5. `prefix q` to detach, then `herdr` to come back.

More: <https://herdr.dev/docs/>, and `herdr --default-config` prints every key and option.
