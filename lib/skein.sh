#!/usr/bin/env bash
# Moving a machine from Omadora's names (the project is now Skein) to Skein's.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# ~/.config, ~/.local/state and ~/.cache: omadora -> skein, the old path left behind as a symlink so
# anything that still mentions it keeps working. Run it before symlink_dotfiles, which links into the
# new directory. (A Linux machine's Skein checkout also moves its user units: skein-migrate-names.)
migrate_skein_dirs() {
  local pair old new
  for pair in ".config" ".local/state" ".cache"; do
    old="$HOME/$pair/omadora"
    new="$HOME/$pair/skein"
    if [[ -d $old && ! -L $old && ! -e $new ]]; then
      mkdir -p "$(dirname "$new")"
      mv "$old" "$new" && ln -s "$new" "$old" && log "Moved $old to $new"
    fi
  done
}

# migrate_skein_checkout <dir> <repo url> <ref>: an existing Omadora checkout (~/.local/share/omadora)
# becomes <dir>, follows the repo's new URL and moves to <ref>, where the renamed code lives.
migrate_skein_checkout() {
  local dir="$1" url="$2" ref="$3"
  local old="$HOME/.local/share/omadora"
  if [[ -d $old/.git && ! -L $old && ! -e $dir ]]; then
    mv "$old" "$dir" && ln -s "$dir" "$old" && log "Moved $old to $dir"
  fi
  [[ -d $dir/.git ]] || return 0
  git -C "$dir" remote set-url origin "$url"
  if [[ "$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)" != "$ref" ]]; then
    log "Switching the Skein checkout to $ref..."
    git -C "$dir" fetch origin "$ref" && git -C "$dir" checkout -q -B "$ref" FETCH_HEAD \
      || log "WARNING: couldn't switch $dir to $ref - resolve it by hand (local changes in the way?)."
  fi
}
