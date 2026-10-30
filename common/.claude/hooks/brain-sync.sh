#!/usr/bin/env bash
# PostToolUse: push the vault to the server within seconds of a note being written. The hot path (every
# tool call) is builtins only, no fork and no output; it spawns the detached worker once per burst of writes.
# The worker waits until writes pause, then commits, rebases and pushes. Wired by lib/claude.sh.

if [[ ${1:-} != --worker ]]; then
  IFS= read -r -d '' input
  vault="${BRAIN_DIR:-$HOME/Brain}"
  [[ $input == *"${vault##*/}"* && -d $vault/.git ]] || exit 0
  : >"$vault/.git/brain-sync.stamp" || exit 0
  lock="$vault/.git/brain-sync.lock"
  if ! mkdir "$lock" 2>/dev/null; then
    pid=""
    [[ -r $lock/pid ]] && read -r pid <"$lock/pid"
    if [[ -z $pid ]]; then
      [[ -n $(find "$lock" -maxdepth 0 -mmin +2 2>/dev/null) ]] || exit 0
    else
      kill -0 "$pid" 2>/dev/null && exit 0
    fi
    rm -rf "$lock"
    mkdir "$lock" 2>/dev/null || exit 0
  fi
  BRAIN_DIR="$vault" nohup bash "$0" --worker >/dev/null 2>&1 </dev/null &
  printf '%s' "$!" >"$lock/pid"
  disown 2>/dev/null
  exit 0
fi

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/brain-lib.sh"
stamp="$BRAIN_DIR/.git/brain-sync.stamp"
seen="$BRAIN_DIR/.git/brain-sync.seen"
lock="$BRAIN_DIR/.git/brain-sync.lock"
trap 'rm -rf "$lock" "$seen"' EXIT
brain_repo || exit 0

while :; do
  waited=0
  while :; do
    : >"$seen"
    sleep 4
    waited=$((waited + 4))
    [[ $stamp -nt $seen && $waited -lt 60 ]] || break
  done
  : >"$seen"
  brain_dirty && { brain_sync_now || exit 0; }
  [[ $stamp -nt $seen ]] || break
done
exit 0
