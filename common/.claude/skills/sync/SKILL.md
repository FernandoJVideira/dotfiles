---
name: sync
description: >
  Force an immediate sync of the Brain (the ~/Brain notes vault) with the server, in a session that
  is already open. Use on "sync", "sync the brain", "pull the brain", "refresh the notes", "get the
  latest notes from the other machine".
---

# Sync

Pulls the other machine's notes now. The prompt hook only fetches every 2 minutes, and a session opened
before the hooks were registered has no prompt hook at all, so this forces what they would do.

Run this with the Bash tool. It uses the same `brain-lib.sh` as the hooks (so the commit, rebase,
conflict handling and ssh settings are identical, and nothing ever prompts):

```bash
bash <<'SH'
export BRAIN_DIR="${BRAIN_DIR:-$HOME/Brain}"
source "$HOME/.claude/hooks/brain-lib.sh"
brain_repo || { echo "no vault"; exit 0; }
BRAIN_SYNC_NOTE=""
old="$(git -C "$BRAIN_DIR" rev-parse HEAD)"
brain_sync_now
status=$?
br="$(git -C "$BRAIN_DIR" symbolic-ref -q --short HEAD)"
if brain_git fetch -q origin "$br" >/dev/null 2>&1; then echo "fetch: ok"; else echo "fetch: failed"; fi
echo "status: $status"
echo "note: ${BRAIN_SYNC_NOTE:-}"
echo "slug: $(brain_slug "$PWD")"
echo "changed:"
git -C "$BRAIN_DIR" diff --name-only "$old" HEAD
rm -f "$BRAIN_DIR/.git/brain-notice"
SH
```

Why each part: `brain_repo` stops when there is no linked vault. `brain_sync_now` commits loose edits first so
the pull cannot trip on them. The `old` HEAD makes the changed list exact. The extra fetch exists
because `brain_sync_now` stays silent offline, and that silence must not read as "current". The notice
file is removed so the next prompt does not announce what you just handled.

Report from the output:
- Nothing changed and `fetch: ok`: "Brain already current".
- Nothing changed and `fetch: failed`: say the server could not be reached, so the local copy may be stale.
- `note:` set or `status` non-zero: show the note and tell the user the command it names. Do not touch the vault.
- Paths changed: re-read the ones this session relies on: `INDEX.md`, `knowledge/*`, and
  `projects/<slug>/*` for the printed slug. Only name notes of other projects, do not read them.
- A `*.conflict-*` file appeared: the newer version was kept and the other parked beside it. Fold anything
  still true into the real page, then delete the conflict file, as the Brain rules say.

This skill never edits notes itself, except for that conflict rule.
