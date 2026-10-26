# Attribution

Caveman, by Julius Brussee: <https://github.com/JuliusBrussee/caveman>. Copyright 2026 Julius Brussee.

Vendored **unchanged** from release **v4.0.1** (2026-10-13), commit-pinned by tag, so that every
machine these dotfiles are installed on has the skills. Three skills come from it:

| Skill | Upstream path | Use |
|---|---|---|
| `caveman` | `skills/caveman/` | the default terse voice (`/caveman`, `stop caveman`) |
| `ultracave` | `skills/ultracave/` | `/ultracave` or `/caveman ultra`: maximum compression |
| `megacave` | `skills/megacave/` | `/megacave` or `/caveman wenyan`: Classical Chinese |

`ultracave` and `megacave` are here because `caveman` hands `/caveman ultra` and `/caveman wenyan`
over to them. Not vendored: the rest of the project (the Claude Code plugin, hooks, status line,
installer, `caveman-compress`...), which is installed with upstream's own tooling and edits
`~/.claude/settings.json`, so it doesn't belong in a dotfiles repo.

Licence: Apache-2.0 from 3.0.0 on (`LICENSE`), with the MIT text kept for the pre-3.0 parts
(`LICENSE-MIT`); `NOTICE` is upstream's, verbatim. `ultracave/` and `megacave/` are covered by the
same files, which live here in `caveman/`.

## Updating

Pick a new tag, read the diff of `skills/{caveman,ultracave,megacave}`, then fetch the files from
that tag (`https://raw.githubusercontent.com/JuliusBrussee/caveman/<tag>/skills/<name>/SKILL.md`,
`README.md`, plus `LICENSE`, `LICENSE-MIT`, `NOTICE` from the repo root) over the ones here and
update the tag above. Compare each file's `git hash-object` with the `sha` that
`https://api.github.com/repos/JuliusBrussee/caveman/contents/<path>?ref=<tag>` reports.
