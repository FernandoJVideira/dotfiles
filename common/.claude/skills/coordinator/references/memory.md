# Project memory: the Brain

The Brain is a small wiki of markdown that you maintain (`~/Brain`, or `$BRAIN_DIR`), an Obsidian-style
vault in git. The idea is Karpathy's "LLM wiki": instead of re-deriving everything each session, you
keep a persistent wiki up to date and it compounds. There are no raw sources and no notes by the user:
the source is the conversation, you own every file, and the user only reads it. This file is the schema.

Each project has a folder, `projects/<slug>/`, where `<slug>` is `owner-repo` from the git remote (the
session-start context names the exact path). A hook injects `state.md`, the last 5 lines of
`decisions.md`, the names and summaries of the topic pages and a "since the last checkpoint" git summary
into every session. Your job is to keep the pages true, short and about the why.

## Layout

Per project files live in `projects/<slug>/`; `INDEX.md` and `knowledge/` are at the vault root.

| File | Who writes it | What it holds |
|---|---|---|
| `INDEX.md` | you | `- [[path\|title]] one-line summary`, grouped under Projects and Knowledge. Read it first when looking for anything |
| `state.md` | you, rewritten whole | where the project stands: goal, status, next steps, open questions, Project Map. Max 60 lines, injected into every session |
| `decisions.md` | you, appended | one line per settled decision |
| `log.md` | the end-of-session hook only | commits and files changed per session. Never edit it |
| `topics/<name>.md` | you | one durable how or why: a mechanism, a design, a lesson tied to this project. Loaded only when needed, never injected whole |
| `knowledge/<name>.md` | you | a lesson that holds across projects, same page format. Only when it shows up in a second project or the user asks |

### Topic and knowledge pages

```
---
summary: <one line, shown at session start>
updated: <YYYY-MM-DD>
---
<short plain markdown: the conclusion and the why, [[wikilinks]] to related topics and decisions>
```

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

One bullet per decision, appended: `- YYYY-MM-DD | chose X over Y because Z`. Keep each on a single line with
no blank lines between (the session hook loads the last 5 lines, and two machines' lines merge by line). The user's decisions and yours,
the reason always included, in under 30 words. A decision that replaces an older one says
`(replaces YYYY-MM-DD)`. Not decisions: tasks done (git has them), ideas still being discussed.

## Operations

1. **Ingest.** At a checkpoint the conversation is the source. Decide what is durable. Update or create
   the topic pages it touches (one conversation may touch several), move detail out of `state.md` into
   topics so it stays short, append decisions, add or fix the page's line in `INDEX.md`, and note a
   supersession in both the old and the new place. Prefer updating a page over creating one. Never
   copy transcript; write conclusions and the why.
2. **Query.** To answer a question about the project's past or design, read `INDEX.md` first, then only
   the pages it points to, not the whole vault. When an answer took real work to put together and would
   be asked again, file it back as a topic page and index it.
3. **Lint.** Only when the user asks ("lint the brain") or when `state.md` exceeds its limit. Check:
   contradictions between pages and decisions, claims a newer decision superseded, orphan pages not in
   `INDEX.md`, topic pages with no links in or out, things mentioned repeatedly with no page,
   `state.md` over 60 lines, secrets. Fix what is clear; list what needs the user's call.

## When to write (checkpoints)

- A decision is settled: append to `decisions.md` at once, before going on.
- A task is finished, the topic changes, or a design discussion ends with a conclusion: ingest it
  (topics, `state.md` status, next, open questions, `INDEX.md`).
- The user says "save", "checkpoint" or that they are stopping: do both and say in one line what you saved.
- Do not write on every message, and do not recap the conversation. Pages are for a later session that
  has not seen this one: what it needs in order to continue, and why things are the way they are.
- Commit and push are done by a hook after you write. Do not run git on the vault.

## Rules

- The vault is entirely yours, written from conversations. The user may read it but writes nothing
  there, so no file needs to preserve their edits.
- Write the **why**, not a transcript. If a line would not help a reader a month from now, drop it.
- Facts the code or git already shows (file lists, function names, diffs) do not go in. Link the
  decision to the area ("auth: ...") and let the reader look at the code.
- **Never put secrets in the vault**: no `.env` values, tokens, keys, passwords, or private URLs with
  credentials. It syncs to a server.
- Plain markdown only, short lines, no tables in `state.md` (it is injected into the context).
- Do not read the vault broadly. The injected context is the memory. Open a topic page when the work
  touches it, and another project's pages only when the user asks about that project, starting from
  `INDEX.md`.
