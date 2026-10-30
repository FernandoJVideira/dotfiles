#!/usr/bin/env bash
# UserPromptSubmit: tell the session once when another machine changed notes it relies on, and keep the
# vault fresh. The hot path (every prompt) is builtins plus at most one `date`; the fetch runs in a
# detached worker at most once per BRAIN_FETCH_INTERVAL. Never fails the prompt. Wired by lib/claude.sh.

if [[ ${1:-} != --worker ]]; then
  IFS= read -r -d '' input
  vault="${BRAIN_DIR:-$HOME/Brain}"
  [[ -d $vault/.git ]] || exit 0
  cwd=""
  [[ $input =~ \"cwd\":\"([^\"]*)\" ]] && cwd="${BASH_REMATCH[1]}"
  notice="$vault/.git/brain-notice"

  if [[ -s $notice ]]; then
    lines=()
    while IFS= read -r l; do [[ -n $l ]] && lines+=("$l"); done <"$notice"
    rm -f "$notice"
    paths=() conflicts=()
    for l in ${lines[@]+"${lines[@]}"}; do
      if [[ $l == "conflict: "* ]]; then conflicts+=("${l#conflict: }"); else paths+=("$l"); fi
    done
    text=""
    if ((${#paths[@]} > 0)); then
      list="" i=0
      for l in "${paths[@]}"; do
        ((i++ >= 5)) && break
        list="${list:+$list, }$l"
      done
      text="Brain updated from another machine: $list"
      ((${#paths[@]} > 5)) && text="$text and $((${#paths[@]} - 5)) more"
      text="$text. Re-read what you rely on before continuing."
    fi
    if ((${#conflicts[@]} > 0)); then
      text="${text:+$text }A merge conflict was resolved by keeping the newer version; the other is saved as ${conflicts[0]} (same folder): fold anything still true into the real page, then delete the conflict file."
    fi
    if [[ -n $text ]]; then
      jq -cn --arg t "${text:0:399}" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $t}}' 2>/dev/null
    fi
  fi

  stamp="$vault/.git/brain-fetch.stamp"
  if ! printf -v now '%(%s)T' -1 2>/dev/null; then now="$(date +%s)"; fi
  last=0
  [[ -r $stamp ]] && read -r last <"$stamp"
  [[ $last =~ ^[0-9]+$ ]] || last=0
  ((now - last >= ${BRAIN_FETCH_INTERVAL:-120})) || exit 0
  printf '%s\n' "$now" >"$stamp" 2>/dev/null || exit 0

  lock="$vault/.git/brain-fetch.lock"
  if ! mkdir "$lock" 2>/dev/null; then
    pid=""
    [[ -r $lock/pid ]] && read -r pid <"$lock/pid"
    if [[ -z $pid ]]; then
      [[ -n $(find "$lock" -maxdepth 0 -mmin +5 2>/dev/null) ]] || exit 0
    else
      kill -0 "$pid" 2>/dev/null && [[ -z $(find "$lock" -maxdepth 0 -mmin +5 2>/dev/null) ]] && exit 0
    fi
    rm -rf "$lock"
    mkdir "$lock" 2>/dev/null || exit 0
  fi
  BRAIN_DIR="$vault" nohup bash "$0" --worker "$cwd" >/dev/null 2>&1 </dev/null &
  printf '%s' "$!" >"$lock/pid"
  disown 2>/dev/null
  exit 0
fi

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/brain-lib.sh"
lock="$BRAIN_DIR/.git/brain-fetch.lock"
trap 'rm -rf "$lock"' EXIT
brain_repo || exit 0
[[ -d $BRAIN_DIR/.git/brain-sync.lock ]] && exit 0

br="$(git -C "$BRAIN_DIR" symbolic-ref -q --short HEAD)" || exit 0
brain_git fetch -q origin "$br" >/dev/null 2>&1 || exit 0
[[ $(git -C "$BRAIN_DIR" rev-list --count "HEAD..origin/$br" 2>/dev/null || echo 0) != 0 ]] || exit 0

old="$(git -C "$BRAIN_DIR" rev-parse HEAD)"
brain_commit
BRAIN_SYNC_NOTE=""
brain_pull
[[ -z $BRAIN_SYNC_NOTE ]] || exit 0
if [[ $(git -C "$BRAIN_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0) != 0 ]]; then
  GIT_SSH_COMMAND="$(brain_ssh 5)" git -C "$BRAIN_DIR" push -q -u origin HEAD >/dev/null 2>&1 </dev/null || true
fi

slug=""
[[ -n ${2:-} ]] && slug="$(brain_slug "$2")"
while IFS= read -r p; do
  case "$p" in
    INDEX.md | knowledge/*) brain_notice_add "$p" ;;
    projects/*) [[ -n $slug && $p == "projects/$slug/"* ]] && brain_notice_add "$p" ;;
  esac
done < <(git -C "$BRAIN_DIR" diff --name-only "$old" HEAD 2>/dev/null)
exit 0
