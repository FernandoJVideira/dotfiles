# The Brain: project memory for Claude

The goal is fewer tokens per project without losing quality. Claude starts every session knowing the
project's state, what changed and why, so it doesn't re-read and re-discover. The memory is an
Obsidian-style vault of plain markdown, `~/Brain` (set `BRAIN_DIR` to move it). It is a git repo, and the
session hooks keep it in step across machines through your server.

## On each machine

The bootstrap does everything, on macOS, Nobara and Arch alike: the vault (cloned from the server when the
machine has none, otherwise started and pushed), the hooks, the skill overrides, `gopls` and
`typescript-language-server` (mise), Anthropic's `gopls-lsp` and `typescript-lsp` plugins, and Obsidian
itself (Homebrew cask, Arch package, Nobara Flatpak `md.obsidian.Obsidian`). Nothing to set up by hand,
except that the machine reaches the server through the Proton Pass SSH agent (the installer asks for
the tokens that log it in; the hooks use its socket even when the session was started from the desktop
app, and never prompt). Without that access the vault stays local, the session tells you, and a rerun of
`./bootstrap.sh` links it.

The remote is `BRAIN_REMOTE` in `lib/claude.sh`
(`git@git.fernandovideira.com:FernandoJVideira/agent-brain.git`).

## How the sync works

Sync happens at the moments you switch machines, not in the background:

- **Session start** (`startup` and `resume`): the hook commits any loose edits, pulls the server's
  changes (a rebase), and pushes anything still waiting from the last session. A `/clear` or a compaction
  doesn't pull.
- **Session end and compaction**: the hook commits the notes and pushes in the background (a
  `SessionEnd` hook only has 1.5 s, and a push can take longer).
- **Offline or no SSH**: both steps stay quiet and the session uses the local copy. The next start
  pushes whatever was missed.
- **Same lines changed on two machines**: `log.md` and `decisions.md` merge by union, so lines added on
  both sides are all kept. A real clash (say `state.md` rewritten on both) is not merged: the vault
  stays as it was, Claude is told, and you fix it with `git -C ~/Brain pull --rebase`.
- One gap: the other machine only sees a session's notes once the first has pushed. If you switch
  seconds after quitting, or the push failed, run `git -C ~/Brain push` on the first machine.
- `.obsidian/` is not synced (per-machine settings, and plugin data that can hold credentials). Open
  `~/Brain` in Obsidian on each machine to read or edit; its changes travel at the next session boundary.
  Don't also run LiveSync on this folder: two syncers fight over the files.

## How a session goes

1. `hdev` opens the project in Herdr and starts `claude /coordinator` in the agent pane
   (`HDEV_COORDINATOR=0` starts a plain Claude).
2. A SessionStart hook (`~/.claude/hooks/brain-start.sh`) loads the project's `state.md`, the last five
   decisions and the commits since the last checkpoint into the session. About 800 tokens at most.
3. The coordinator says what it understood, then you talk. It **discusses**: options, trade-offs, a
   recommendation, the reason. No agent is spawned and no file is edited until you say to implement
   ("implement", "build it", "go").
4. Settled decisions are appended to `decisions.md` at once. `state.md` is rewritten when a task ends or
   the topic changes, and on "save".
5. When the session ends (or is compacted) a second hook (`brain-end.sh`, no model, no network) appends
   what git saw to `log.md`.

## The vault

```
Brain/
  INDEX.md                  one line per project and per knowledge note
  projects/<slug>/
    state.md                goal, status, next, open questions, Project Map (max 60 lines, rewritten)
    decisions.md            "- date | chose X over Y because Z", one bullet per line, appended
    log.md                  commits and files per session; written only by the end hook
  knowledge/                lessons across projects, your own notes
  _agent/                   scratch
```

`<slug>` is `owner-repo` from the git remote, so the Mac and Nobara share one folder per project (a
repo with no remote uses the folder name). Notes are plain and complete sentences, written for a reader
who hasn't seen the session. **No secrets go in the vault**: it syncs to a server.

Edit anything in Obsidian. The coordinator only writes `state.md`, `decisions.md` and the `INDEX.md`
line of a project; the hook only writes `log.md`; your other notes are never touched.

## What loads every session (the token budget)

| Piece | Cost | Notes |
|---|---|---|
| Brain hook | about 800 tokens max | silent without a vault or outside a project |
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

`common/.claude/hooks/brain-{lib,start,end}.sh` the hooks. `lib/claude.sh` creates the vault, merges the
hooks and the skill overrides into `~/.claude/settings.json` (leaving Herdr's hook alone) and holds
`install_rtk`. `common/.claude/skills/coordinator/` the skill: `SKILL.md` (discuss, memory, the gate),
`references/implement.md` (workflow, caps, prompts), `memory.md`, `oversight.md`, `frontend.md`, `nuxt.md`.
