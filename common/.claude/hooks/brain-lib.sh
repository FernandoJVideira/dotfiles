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

# bring in what the other machines pushed. Offline: silent. Diverged notes: leave the vault as it was
# and set BRAIN_SYNC_NOTE so the session can tell the user.
brain_pull() {
  brain_repo || return 0
  local br
  br="$(git -C "$BRAIN_DIR" symbolic-ref -q --short HEAD)" || return 0
  brain_git fetch -q origin "$br" >/dev/null 2>&1 || return 0
  git -C "$BRAIN_DIR" rev-parse -q --verify "origin/$br" >/dev/null 2>&1 || return 0
  if ! brain_git rebase -q "origin/$br" >/dev/null 2>&1; then
    git -C "$BRAIN_DIR" rebase --abort >/dev/null 2>&1 || true
    BRAIN_SYNC_NOTE="Brain sync: the notes on this machine and the server changed in the same place, so they were not merged. Tell the user to run: git -C $BRAIN_DIR pull --rebase (and fix the conflict)."
  fi
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
