# The Brain: project memory for Claude

The goal is fewer tokens per project without losing quality. Claude starts every session knowing the
project's state, what changed and why, so it doesn't re-read and re-discover. The memory is an
Obsidian-style vault of plain markdown, `~/Brain` (set `BRAIN_DIR` to move it). It is a git repo, and the
session hooks keep it in step across machines through your server.

The design is adapted from Karpathy's "LLM wiki"
([gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)): instead of re-deriving
everything each session, Claude keeps a small persistent wiki up to date, so the memory compounds. The
original has a layer of raw sources; this one leaves it out, because you never write in the vault and the
conversation itself is the source. Claude owns every file; you read it (Obsidian is the viewer).

## On each machine

The bootstrap does everything, on macOS, Nobara and Arch alike: the vault (cloned from the server when the
machine has none, otherwise started and pushed), the hooks, the skill overrides, `gopls` and
`typescript-language-server` (mise), Anthropic's `gopls-lsp` and `typescript-lsp` plugins, and Obsidian
itself (Homebrew cask, Arch package, Nobara Flatpak `md.obsidian.Obsidian`). Nothing to set up by hand,
except that the machine reaches the server through the Proton Pass SSH agent (the installer asks for
the tokens that log it in; the hooks use its socket even when the session was started from the desktop
app, and never prompt). Without that access the vault stays local, the session tells you, and a rerun of
`./bootstrap.sh` links it.

Which remote the vault syncs to is decided once, the first time a machine's vault is linked:

1. `BRAIN_REMOTE` in the environment (`none` keeps the vault on that machine only), for unattended runs.
2. The remote saved on the machine, `~/.config/dotfiles/brain-remote`.
3. The owner's default, `BRAIN_DEFAULT_REMOTE` in `lib/claude.sh`, when it answers. It is a private repo,
   so answering proves the access, and the owner is never asked anything.
4. Otherwise the installer says the default isn't reachable and asks for a remote of your own (an empty
   private repo, such as `git@host:you/brain.git`). It must answer, and it is then saved. Enter keeps
   the vault on this machine, and the next `./bootstrap.sh` asks again.

The vault is always built from scratch, never downloaded from a template: its notes are loaded into
Claude's context at every session start, so unreviewed text from a template repo would end up there. A
forker only needs to set their own `BRAIN_DEFAULT_REMOTE`. If you are the owner and the bootstrap asks
anyway, your server wasn't reachable (usually the Proton token was skipped); press Enter and rerun once
the agent is up. A vault that has a first commit keeps its origin and is never asked about again.

## How the sync works

Sync happens in the background while you work, as well as at the session boundaries:

- **After a note is written**: a `PostToolUse` hook (`brain-sync.sh`) notices when a tool call touched
  the vault. After a few seconds of quiet it commits, rebases onto the server's changes and pushes, in
  the background. It prints nothing, so it costs no tokens, and a tool call that does not touch the
  vault costs it a few milliseconds.
- **Each prompt**: a `UserPromptSubmit` hook (`brain-prompt.sh`) checks the server in the background at
  most every 2 minutes (`BRAIN_FETCH_INTERVAL` seconds to change it), fast-forwards the vault, and
  tells Claude with one short line only when notes of the current project changed.
- **Force a sync**: the `/sync` skill commits, rebases onto the server and pushes right now, ignoring the
  2-minute throttle. Use it in a session that was open before the hooks were registered (it has no
  prompt hook) or to get the other machine's notes at once. It reports what changed and re-reads the
  notes the session relies on.
- **Session start** (`startup` and `resume`): the hook commits any loose edits, pulls the server's
  changes (a rebase), and pushes anything still waiting. A `/clear` or a compaction doesn't pull.
- **Session end and compaction**: the hook commits the notes and pushes in the background (a
  `SessionEnd` hook only has 1.5 s, and a push can take longer). Start and end are the safety net.
- **Offline or no SSH**: every step stays quiet and the session uses the local copy. A later sync
  retries and pushes whatever was missed.
- **Same lines changed on two machines**: `log.md` and `decisions.md` merge by union, so lines added on
  both sides are all kept. Any other clash is resolved by keeping the version with the newer
  `updated:` date and saving the other as `<name>.conflict-<host>.<ext>`. Nothing is lost and the vault
  is never left unmerged; Claude folds the conflict file into the page at its next checkpoint.
- **Claude Code's auto-memory**: each project's own memory lives in `projects/<slug>/memory/` in the
  vault, and `~/.claude/projects/<dir>/memory` (where `<dir>` is the project path with every
  non-alphanumeric character as `-`) is a symlink to it, made at the first session start after the
  bootstrap, so that first session may still read the old copy. An existing local directory is merged
  in (same-name files that differ keep the vault's and save yours as `<name>.from-<host>.<ext>`), so
  memories from this machine appear in the vault, and so in git.
- One gap: the other machine only sees the notes once the first has pushed. If you switch within seconds
  of the last write, or the push failed, run `git -C ~/Brain push` on the first machine.
- `.obsidian/` is not synced (per-machine settings, and plugin data that can hold credentials). Open
  `~/Brain` in Obsidian on each machine to read; Claude owns the files, so edits you make there may be
  rewritten.
  Don't also run LiveSync on this folder: two syncers fight over the files.

## How a session goes

1. `hdev` opens the project in Herdr and starts `claude /coordinator` in the agent pane
   (`HDEV_COORDINATOR=0` starts a plain Claude).
2. A SessionStart hook (`~/.claude/hooks/brain-start.sh`) loads the project's `state.md`, the last five
   decisions, the topic pages' names with their one-line summaries and the commits since the last
   checkpoint into the session. About 800 tokens at most.
3. The coordinator says what it understood, then you talk. It **discusses**: options, trade-offs, a
   recommendation, the reason. No agent is spawned and no file is edited until you say to implement
   ("implement", "build it", "go").
4. Settled decisions are appended to `decisions.md` at once. When a task ends, the topic changes or you
   say "save", Claude updates the topic pages the conversation touched, keeps `state.md` short and fixes
   `INDEX.md`. To answer a question about the past it reads `INDEX.md` first, then only the pages it
   points to.
5. `brain-sync.sh` commits and pushes those writes in the background. When the session ends (or is
   compacted) `brain-end.sh` (no model, no network) appends what git saw to `log.md`.

## The vault

```
Brain/
  INDEX.md                  catalog: one line per page, under Projects and Knowledge; read first
  projects/<slug>/
    state.md                goal, status, next, open questions, Project Map (max 60 lines, rewritten)
    decisions.md            "- date | chose X over Y because Z", one bullet per line, appended
    log.md                  commits and files per session; written only by the end hook
    topics/<name>.md        one durable how or why per page (summary, updated, [[wikilinks]])
    memory/                 Claude Code's own auto-memory (MEMORY.md index plus notes), symlinked from ~/.claude
  knowledge/<name>.md       lessons that hold across projects, same page format
  _agent/                   scratch
```

`<slug>` is `owner-repo` from the git remote, so the Mac and Nobara share one folder per project (a
repo with no remote uses the folder name). Notes are plain and complete sentences, written for a reader
who hasn't seen the session. **No secrets go in the vault**: it syncs to a server.

The vault is Claude's, written from your conversations. Read it in Obsidian, but write nothing there.
Claude writes `state.md`, `decisions.md`, the topic and knowledge pages and `INDEX.md`; the hook only
writes `log.md`. Topic pages cost nothing until Claude opens one. "Lint the brain" makes it check for
contradictions, orphan pages and a `state.md` over its limit.

## What loads every session (the token budget)

| Piece | Cost | Notes |
|---|---|---|
| Brain hook | about 800 tokens max | `state.md`, last decisions, topic names with summaries, git summary; silent without a vault or outside a project. Topic pages cost nothing until opened |
| Prompt hook | nothing unless notes changed, then under 400 bytes | `brain-prompt.sh`: one line naming the changed notes of the current project |
| `coordinator` skill | about 2k tokens | was 6.4k: the workflow and prompt templates now load only on "implement" |
| Skill listing | names plus descriptions | `common/.claude/skill-overrides.json` lists overlapping third-party skills by name only; `humanizer` is invoked by hand |
| Plugin skills | per plugin | not affected by `skillOverrides`: turn plugins you don't use for coding off in `/plugin`, and the claude.ai ones in its settings |

Measure with `/context`, `/skill-doctor` and `/usage`.

## Code intelligence

`gopls` and `typescript-language-server` are installed with mise, and Anthropic's `gopls-lsp` and
`typescript-lsp` plugins are on (`claude plugin install gopls-lsp@claude-plugins-official`). Claude
looks symbols up through the language server and sees type errors after an edit, instead of grepping and
reading files. There is no official Vue plugin yet.

## RTK, shorter command output (opt-in)

[RTK](https://github.com/rtk-ai/rtk) rewrites commands such as `git status` or `go test` so Claude reads a
compact version of their output. Reviewed before use: Apache-2.0 `rtk-oss` build only, pinned to
1.1.0 and checked against the release's checksums, the hook fails open, telemetry is off by default, and
the proxy daemon (which sits between Claude and the API) is not used. Its rewrites make Claude Code ask
for permission unless a rule allows them, so try it on one project first and compare `/usage`. It is
**not** run by the bootstrap. When you want it:

```bash
bash -c 'source lib/claude.sh; install_rtk'
```

To take it out, delete the `PreToolUse` entry ending in `rtk hook claude` from `~/.claude/settings.json`
(a copy of the file from before is `settings.json.pre-rtk`) and `~/.local/bin/rtk`.

## Files

`common/.claude/hooks/brain-{lib,start,end,sync,prompt,memory}.sh` the hooks. `lib/claude.sh` creates the vault, merges the
hooks and the skill overrides into `~/.claude/settings.json` (leaving Herdr's hook alone) and holds
`install_rtk`. `common/.claude/skills/coordinator/` the skill: `SKILL.md` (discuss, memory, the gate),
`references/implement.md` (workflow, caps, prompts), `memory.md`, `oversight.md`, `frontend.md`, `nuxt.md`.
`common/.claude/skills/sync/SKILL.md` the `/sync` skill (forced sync of the vault in an open session).
`common/.claude/CLAUDE.md` holds the standing preferences for every project (linked to `~/.claude/CLAUDE.md` by the bootstrap); a machine that already has its own `~/.claude/CLAUDE.md` loses it to the link, since the bootstrap links with `ln -sf`, so copy anything you want to keep into this file first.
