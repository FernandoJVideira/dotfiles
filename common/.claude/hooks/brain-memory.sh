#!/usr/bin/env bash
# Sourced by brain-start.sh. Claude Code keeps a project's auto-memory in ~/.claude/projects/<dir>/memory, where
# <dir> embeds this machine's path; moving it into the vault and symlinking it back makes every machine share it.

# brain_link_memory <cwd> <slug>: silent, never fails. Leaves the old directory untouched if anything goes wrong.
brain_link_memory() {
  local cwd="$1" slug="$2" enc src dst
  enc="${cwd//[^A-Za-z0-9]/-}"
  src="$HOME/.claude/projects/$enc/memory"
  dst="$BRAIN_DIR/projects/$slug/memory"
  [[ -n $cwd && -n $slug ]] || return 0
  [[ -L $src && $src -ef $dst ]] && return 0
  (_brain_link_memory "$src" "$dst") >/dev/null 2>&1 || true
  return 0
}

_brain_link_memory() {
  local src="$1" dst="$2" f name host ext
  if [[ -L $src ]]; then
    return 0
  elif [[ ! -e $src ]]; then
    mkdir -p "$dst" "$(dirname "$src")" && ln -s "$dst" "$src"
    return
  elif [[ ! -d $src ]]; then
    return 0
  fi

  mkdir -p "$dst" || return 0
  host="$(hostname -s 2>/dev/null || uname -n)"
  shopt -s dotglob nullglob
  for f in "$src"/*; do
    name="$(basename "$f")"
    if [[ ! -e $dst/$name ]]; then
      mv "$f" "$dst/$name" || return 0
    elif [[ -f $f && -f $dst/$name ]] && cmp -s "$f" "$dst/$name"; then
      rm -f "$f" || return 0
    elif [[ $name == MEMORY.md && -f $f && -f $dst/$name ]]; then
      { grep -vxFf "$dst/$name" "$f" || true; } >>"$dst/$name" && rm -f "$f" || return 0
    elif [[ -f $f ]]; then
      ext=""
      [[ $name == ?*.* ]] && ext=".${name##*.}"
      mv -f "$f" "$dst/${name%"$ext"}.from-$host$ext" || return 0
    else
      return 0
    fi
  done
  rmdir "$src" 2>/dev/null && ln -s "$dst" "$src"
}
