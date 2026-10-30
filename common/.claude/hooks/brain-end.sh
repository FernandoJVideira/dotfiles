#!/usr/bin/env bash
# SessionEnd and PreCompact: write what git says changed into the project's log.md and move the checkpoint
# forward. No model, no network, under a second (SessionEnd hooks get a 1.5 s budget). Only for projects
# that already have a state.md, so it never litters the vault with folders. Then the vault is committed and
# pushed to the server (see brain_push_bg).
set -uo pipefail

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/brain-lib.sh"
brain_read_input

[[ -n $(brain_field agent_id) ]] && exit 0
# whichever way this exits, commit the notes and send them to the server in the background
trap 'brain_commit; brain_push_bg' EXIT
cwd="$(brain_field cwd)"
cwd="${cwd:-$PWD}"
git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || exit 0

slug="$(brain_slug "$cwd")"
note_dir="$BRAIN_DIR/projects/$slug"
state="$note_dir/state.md"
[[ -f $state ]] || exit 0

head="$(git -C "$cwd" rev-parse HEAD 2>/dev/null || true)"
[[ -n $head ]] || exit 0
last="$(brain_front "$state" commit)"
dirty="$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

# no new commits since the last checkpoint: nothing to log (uncommitted files alone are not news)
[[ $head == "$last" ]] && exit 0

branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
entry="## $(date '+%Y-%m-%d %H:%M') ($branch)"$'\n'
if [[ -n $last && $head != "$last" ]] && git -C "$cwd" cat-file -e "$last^{commit}" 2>/dev/null; then
  entry="$entry$(git -C "$cwd" log --format='- %h %s' "$last..HEAD" 2>/dev/null | head -n 20)"$'\n'
  entry="$entry"$'\n''```'$'\n'"$(git -C "$cwd" diff --stat "$last..HEAD" 2>/dev/null | tail -n 12)"$'\n''```'$'\n'
elif [[ $head != "$last" ]]; then
  entry="$entry$(git -C "$cwd" log --format='- %h %s' -n 5 2>/dev/null)"$'\n'
fi
[[ $dirty != 0 ]] && entry="$entry- $dirty uncommitted files"$'\n'

printf '\n%s' "$entry" >>"$note_dir/log.md"
brain_set_front "$state" commit "$head"
brain_set_front "$state" updated "$(date '+%Y-%m-%d')"
exit 0
