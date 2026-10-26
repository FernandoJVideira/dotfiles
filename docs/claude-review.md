# Reviewing Claude's changes in Neovim

Claude Code runs in its own Herdr pane; Neovim sits above it. Two things connect them, depending on
how Claude is working.

## Connect once per Claude session

In the Claude pane run `/ide` and pick Neovim. Claude then opens its proposed edits as a diff in
Neovim and can see your selection. Neovim has to be open on the same project folder, and its server
only listens on `127.0.0.1` with a token (the plugin is `coder/claudecode.nvim`, pinned to a reviewed
commit in `lua/plugins/claude.lua`).

## 1. Claude asks before editing (default mode)

`shift+tab` in Claude cycles the modes. When it asks, the proposal opens as a side-by-side diff:
the old file on the left, Claude's version on the right, and the right side is editable.

| Keys | What it does |
|---|---|
| `<leader>aa` or `:w` | accept the proposal (with any edits you made) |
| `<leader>ad` or `:q` | reject it |
| `]c` / `[c` | next / previous change |
| `do` on a change | deny just that part: pulls the old text into the proposal. Then accept the rest |

## 2. Auto mode: Claude already wrote the files

Open files reload on their own within a second. A hunk is **accepted once it is staged**, so the
signs in the gutter only ever show what is still waiting for your review.

| Keys | What it does |
|---|---|
| `]h` / `[h` | next / previous hunk |
| `<leader>hp` | preview the hunk inline, with the removed lines |
| `<leader>ha` | accept the hunk (in visual mode: only the selected lines) |
| `<leader>hd` | deny the hunk: puts the old lines back (in visual mode: only the selected lines). It edits the buffer, so `:w` to keep it, or `u` to undo |
| `<leader>hA` / `<leader>hD` | accept / deny every hunk in this file |
| `<leader>hu` | undo the last accept |
| `<leader>hl` | list every hunk still to review, across all files (quickfix; `]q` and `[q` to move) |
| `<leader>gt` | Telescope list of changed files, with a diff preview |
| `<leader>hF` | accept everything in the repo (asks first; `git add -A`) |

## Asking Claude to change something

Select the lines in visual mode and press `<leader>as` to send them to Claude as an `@` mention of
that file and range, then move to the Claude pane with `Ctrl+j` and write what to change.
`<leader>ab` sends the whole file; in the file tree `<leader>as` sends the file under the cursor.

## Notes

- Denying every change in the repo at once isn't bound on purpose. Use `<leader>hD` per file, or
  `git restore .` yourself.
- New files Claude creates show as added lines until you accept them (`<leader>hA`).
- Neovim reloads a file only if you have no unsaved edits in it; otherwise it warns.
