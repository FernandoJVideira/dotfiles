# Project memory: the Brain

The Brain is an Obsidian-style vault (`~/Brain`, or `$BRAIN_DIR`), synced across the user's machines
by the session hooks (git: pull at start, push at end). Each project has a folder, `projects/<slug>/`, where `<slug>` is `owner-repo` from the
git remote (the session-start context names the exact path). A hook loads `state.md`, the last 5 lines of
`decisions.md` and a "since the last checkpoint" git summary into every session, so a session starts
knowing the project. Your job is to keep those notes true, short and about the why.

## Files

| File | Who writes it | What it holds |
|---|---|---|
| `state.md` | you, rewritten whole | where the project stands: goal, status, next steps, open questions, Project Map. Max 60 lines |
| `decisions.md` | you, appended | one line per settled decision |
| `log.md` | the end-of-session hook only | commits and files changed per session. Never edit it |
| `../../INDEX.md` | you, one line when you create a project | `- [[projects/<slug>/state\|<slug>]] what it is` |
| `../../knowledge/` | you, only when asked or when a lesson shows up in a second project | cross-project lessons, linked with `[[wikilinks]]` |

### state.md

```
---
slug: <owner-repo>
remote: <git remote url, or "none">
paths: <absolute path(s) of the checkout, comma separated>
commit: <output of git rev-parse HEAD>
updated: <YYYY-MM-DD>
---
# <project name>
Goal: <one line: what this project is for>
Status: <2-4 lines: what works, what is in progress, what is broken>

## Next
- <the next 1-5 things, in order>

## Open questions
- <what is undecided, and who has to decide>

## Project Map
<layout, stacks, key paths, commands, API contract, conventions (implement.md, step 1)>
```

The hook keeps `commit:` and `updated:` current. When you rewrite the file, keep `slug`, `remote`,
`paths`, and copy `commit` as it is. If you create the file, run `git rev-parse HEAD` for `commit`.

### decisions.md

One line per decision, appended: `YYYY-MM-DD | chose X over Y because Z`. The user's decisions and yours,
the reason always included, in under 30 words. A decision that replaces an older one says
`(replaces YYYY-MM-DD)`. Not decisions: tasks done (git has them), ideas still being discussed.

## When to write (checkpoints)

- A decision is settled: append to `decisions.md` at once, before going on.
- A task is finished, the topic changes, or a design discussion ends with a conclusion: rewrite
  `state.md` (status, next, open questions).
- The user says "save", "checkpoint" or that they are stopping: do both and say in one line what you saved.
- Do not write on every message, and do not recap the conversation. Notes are for a later session that
  has not seen this one: what it needs in order to continue, and why things are the way they are.

## Rules

- Write the **why**, not a transcript. If a line would not help a reader a month from now, drop it.
- Facts the code or git already shows (file lists, function names, diffs) do not go in. Link the
  decision to the area ("auth: ...") and let the reader look at the code.
- **Never put secrets in the vault**: no `.env` values, tokens, keys, passwords, or private URLs with
  credentials. It syncs to a server.
- Plain markdown only, short lines, no tables in `state.md` (it is injected into the context).
- Do not read the vault broadly. The injected context is the memory. Open another project's notes only
  when the user asks about that project, starting from `INDEX.md`.
- The vault belongs to the user too: never delete or rewrite their own notes. You own only the files in
  the table above.
