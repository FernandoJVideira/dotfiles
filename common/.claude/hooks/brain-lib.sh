#!/usr/bin/env bash
# Shared by brain-start.sh and brain-end.sh. The Brain is an Obsidian-style vault (default ~/Brain,
# BRAIN_DIR overrides) holding one folder of notes per project: projects/<slug>/{state,decisions,log}.md.

BRAIN_DIR="${BRAIN_DIR:-$HOME/Brain}"

# The hook's JSON arrives on stdin; read it once into $HOOK_INPUT and pull fields from it.
brain_read_input() {
  HOOK_INPUT="$(cat 2>/dev/null || true)"
}

brain_field() {
  printf '%s' "$HOOK_INPUT" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
}

# owner-repo from the git remote (so the Mac and Nobara share a note), else the folder name.
brain_slug() {
  local dir="$1" remote name top
  remote="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
  if [[ -n $remote ]]; then
    name="$(printf '%s' "$remote" | sed -E 's#\.git$##; s#^[a-z+]+://##; s#^[^@/]+@##; s#:#/#' | awk -F/ '{ n = NF; if (n >= 2) print $(n-1) "-" $n; else print $n }')"
  else
    top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
    name="$(basename "${top:-$dir}")"
  fi
  printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//'
}

# `key: value` from the frontmatter (the first --- block) of a note
brain_front() {
  awk -v k="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && index($0, k ": ") == 1 { sub("^" k ": ", ""); print; exit }' "$1" 2>/dev/null
}

# the note without its frontmatter
brain_body() {
  awk 'NR == 1 && $0 == "---" { skip = 1; next } skip && $0 == "---" { skip = 0; next } !skip { print }' "$1" 2>/dev/null
}

# set `key: value` in the frontmatter, adding it if absent
brain_set_front() {
  local file="$1" key="$2" value="$3" tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/brain.XXXXXX")" || return 1
  awk -v k="$key" -v v="$value" '
    NR == 1 { print; if ($0 != "---") bad = 1; infront = 1; next }
    infront && $0 == "---" { if (!done) print k ": " v; infront = 0; print; next }
    infront && index($0, k ": ") == 1 { print k ": " v; done = 1; next }
    { print }' "$file" >"$tmp" && mv "$tmp" "$file"
}

# --- sync -------------------------------------------------------------------------------------------
# The vault is a git repo whose origin lives on the user's server. Sync happens at session boundaries,
# which is when the user moves between machines: pull when a session starts, commit and push when it
# ends. No prompts (BatchMode) and short timeouts, so an offline machine just uses its local copy.

# a vault linked to the server: a git repo with an origin and a first commit (the installer makes both)
brain_repo() {
  [[ -d $BRAIN_DIR/.git ]] && git -C "$BRAIN_DIR" remote get-url origin >/dev/null 2>&1 \
    && git -C "$BRAIN_DIR" rev-parse -q --verify HEAD >/dev/null 2>&1
}

# ssh for the server. The keys live in the Proton Pass agent; a session started from the desktop app
# has no SSH_AUTH_SOCK, so name the agent's socket when it exists. Never prompts.
brain_ssh() {
  local sock="$HOME/.ssh/proton-pass-agent.sock" agent=""
  [[ -S $sock ]] && agent=" -o IdentityAgent=$sock"
  printf 'ssh -o BatchMode=yes -o ConnectTimeout=%s -o ServerAliveInterval=2 -o ServerAliveCountMax=3%s' "${1:-3}" "$agent"
}

brain_git() {
  local t=()
  command -v timeout >/dev/null && t=(timeout 6)
  GIT_SSH_COMMAND="$(brain_ssh 3)" ${t[@]+"${t[@]}"} git -C "$BRAIN_DIR" "$@"
}

# commit everything the notes changed (the coordinator's, Obsidian's) so a pull can never trip on them
brain_commit() {
  brain_repo || return 0
  [[ -n $(git -C "$BRAIN_DIR" status --porcelain 2>/dev/null) ]] || return 0
  local id=()
  git -C "$BRAIN_DIR" config user.email >/dev/null || id=(-c user.name=brain -c user.email=brain@localhost)
  git -C "$BRAIN_DIR" add -A >/dev/null 2>&1 || return 0
  git -C "$BRAIN_DIR" ${id[@]+"${id[@]}"} -c commit.gpgsign=false commit -q -m "brain: $(hostname -s) $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1 || true
}

# one line per path in the notice file, shown once to the next prompt by brain-prompt.sh. It lives
# inside .git so it is never committed.
brain_notice_add() {
  local f="$BRAIN_DIR/.git/brain-notice"
  [[ -d $BRAIN_DIR/.git ]] || return 0
  grep -qxF -- "$1" "$f" 2>/dev/null || printf '%s\n' "$1" >>"$f"
}

# While a rebase is stopped, stage 2 is the upstream side and stage 3 the local commit being replayed.
# Keep the note with the newer `updated:` date (local on a tie or no date) and park the other next to
# it as <name>.conflict-<host>.<ext>. A file deleted on one side keeps the side that still has it.
brain_resolve_conflicts() {
  local f ours theirs od td keep lose dest host tmp
  host="$(hostname -s 2>/dev/null || uname -n)"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/brain.XXXXXX")" || return 1
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    ours="$tmp/ours"
    theirs="$tmp/theirs"
    rm -f "$ours" "$theirs"
    git -C "$BRAIN_DIR" show ":2:$f" >"$ours" 2>/dev/null || rm -f "$ours"
    git -C "$BRAIN_DIR" show ":3:$f" >"$theirs" 2>/dev/null || rm -f "$theirs"
    if [[ ! -e $ours && ! -e $theirs ]]; then
      git -C "$BRAIN_DIR" rm -q --cached -- "$f" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
      rm -f "$BRAIN_DIR/$f"
      continue
    fi
    if [[ -e $ours && -e $theirs ]]; then
      od="$(brain_front "$ours" updated)"
      td="$(brain_front "$theirs" updated)"
      if [[ -n $od && -n $td && $od > $td ]]; then keep="$ours"; lose="$theirs"; else keep="$theirs"; lose="$ours"; fi
    elif [[ -e $theirs ]]; then
      keep="$theirs"; lose=""
    else
      keep="$ours"; lose=""
    fi
    cp "$keep" "$BRAIN_DIR/$f" || { rm -rf "$tmp"; return 1; }
    git -C "$BRAIN_DIR" add -- "$f" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
    if [[ -n $lose ]]; then
      if [[ ${f##*/} == *.* ]]; then dest="${f%.*}.conflict-$host.${f##*.}"; else dest="$f.conflict-$host"; fi
      cp "$lose" "$BRAIN_DIR/$dest" || { rm -rf "$tmp"; return 1; }
      git -C "$BRAIN_DIR" add -- "$dest" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
      brain_notice_add "conflict: $dest"
    fi
  done < <(git -C "$BRAIN_DIR" diff --name-only --diff-filter=U 2>/dev/null)
  rm -rf "$tmp"
}

# bring in what the other machines pushed. Offline: silent. Conflicting notes are resolved by
# brain_resolve_conflicts; if that goes wrong the rebase is aborted and BRAIN_SYNC_NOTE tells the session.
brain_pull() {
  brain_repo || return 0
  local br id=() step
  br="$(git -C "$BRAIN_DIR" symbolic-ref -q --short HEAD)" || return 0
  brain_git fetch -q origin "$br" >/dev/null 2>&1 || return 0
  git -C "$BRAIN_DIR" rev-parse -q --verify "origin/$br" >/dev/null 2>&1 || return 0
  git -C "$BRAIN_DIR" config user.email >/dev/null || id=(-c user.name=brain -c user.email=brain@localhost)
  brain_git ${id[@]+"${id[@]}"} -c commit.gpgsign=false rebase -q "origin/$br" >/dev/null 2>&1 && return 0
  for step in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    [[ -n $(git -C "$BRAIN_DIR" diff --name-only --diff-filter=U 2>/dev/null) ]] || break
    brain_resolve_conflicts || break
    GIT_EDITOR=true git -C "$BRAIN_DIR" ${id[@]+"${id[@]}"} -c commit.gpgsign=false rebase --continue >/dev/null 2>&1 </dev/null && return 0
    [[ -d $BRAIN_DIR/.git/rebase-merge || -d $BRAIN_DIR/.git/rebase-apply ]] || break
  done
  git -C "$BRAIN_DIR" rebase --abort >/dev/null 2>&1 || true
  BRAIN_SYNC_NOTE="Brain sync: the notes on this machine and the server changed in the same place, so they were not merged. Tell the user to run: git -C $BRAIN_DIR pull --rebase (and fix the conflict)."
}

# push in the background: SessionEnd gets 1.5 s, a network push can take longer. Skipped when nothing
# is waiting to go out; a push that fails is retried by the next session's start.
brain_push_bg() {
  brain_repo || return 0
  local ahead
  ahead="$(git -C "$BRAIN_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null)" || ahead=1
  [[ $ahead != 0 ]] || return 0
  GIT_SSH_COMMAND="$(brain_ssh 5)" \
    nohup git -C "$BRAIN_DIR" push -q -u origin HEAD >/dev/null 2>&1 </dev/null &
  disown 2>/dev/null || true
}

# anything the vault still has to commit or push
brain_dirty() {
  [[ -n $(git -C "$BRAIN_DIR" status --porcelain 2>/dev/null) ]] && return 0
  [[ $(git -C "$BRAIN_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0) != 0 ]]
}

# commit, rebase onto the server's notes, push, all in the foreground. Callers run it detached (brain-sync.sh).
# A rebase conflict that cannot be resolved leaves the vault untouched and returns 1; offline or a failed push is silent.
brain_sync_now() {
  brain_repo || return 0
  local t=()
  command -v timeout >/dev/null && t=(timeout 20)
  brain_commit
  BRAIN_SYNC_NOTE=""
  brain_pull
  [[ -z $BRAIN_SYNC_NOTE ]] || return 1
  [[ $(git -C "$BRAIN_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 1) != 0 ]] || return 0
  GIT_SSH_COMMAND="$(brain_ssh 5)" ${t[@]+"${t[@]}"} git -C "$BRAIN_DIR" push -q -u origin HEAD >/dev/null 2>&1 </dev/null || true
}
