#!/usr/bin/env bash
# SessionStart: hand Claude the project's memory (state, recent decisions, what changed in git since the last
# checkpoint), so it starts knowing where the project stands. Capped at about 800 tokens. Wired in
# ~/.claude/settings.json by common/install.sh. Silent when there is no vault or the event is a subagent's.
set -uo pipefail

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/brain-lib.sh"
brain_read_input

[[ -n $(brain_field agent_id) ]] && exit 0
[[ -d $BRAIN_DIR ]] || exit 0

cwd="$(brain_field cwd)"
cwd="${cwd:-$PWD}"
slug="$(brain_slug "$cwd")"
[[ -n $slug ]] || exit 0
note_dir="$BRAIN_DIR/projects/$slug"
state="$note_dir/state.md"

ctx="Project memory (the Brain, an Obsidian vault): project \`$slug\`, notes in $note_dir. Read-only here; the coordinator updates state.md and decisions.md at checkpoints (see the coordinator skill's references/memory.md)."

if [[ -f $state ]]; then
  ctx="$ctx"$'\n\n'"## state.md"$'\n'"$(brain_body "$state" | head -c 3500)"

  if [[ -s $note_dir/decisions.md ]]; then
    ctx="$ctx"$'\n\n'"## Recent decisions"$'\n'"$(tail -n 5 "$note_dir/decisions.md")"
  fi

  # what moved in git since the last checkpoint, computed here so it costs no model tokens
  last="$(brain_front "$state" commit)"
  if [[ -n $last ]] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    head="$(git -C "$cwd" rev-parse HEAD 2>/dev/null || true)"
    if [[ -n $head && $head != "$last" ]] && git -C "$cwd" cat-file -e "$last^{commit}" 2>/dev/null; then
      count="$(git -C "$cwd" rev-list --count "$last..HEAD" 2>/dev/null || echo 0)"
      ctx="$ctx"$'\n\n'"## Since the last checkpoint ($count new)"$'\n'"$(git -C "$cwd" log --oneline -8 "$last..HEAD" 2>/dev/null)"
    fi
    dirty="$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    [[ $dirty != 0 ]] && ctx="$ctx"$'\n'"Uncommitted changes: $dirty files."
  fi
else
  ctx="$ctx"$'\n\n'"No note for this project yet. Create $state when its first goal or decision is settled (format in references/memory.md)."
fi

jq -n --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
