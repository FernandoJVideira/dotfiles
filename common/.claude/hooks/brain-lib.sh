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
