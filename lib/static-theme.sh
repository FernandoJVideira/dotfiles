#!/usr/bin/env bash
# Static One Dark theme for apps-mode installs (no Skein).

STATIC_THEME_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/log.sh
source "$STATIC_THEME_LIB_DIR/log.sh"

apply_static_theme() {
  local repo_dir="${STATIC_THEME_LIB_DIR%/lib}/linux/apps-theme/one-dark"
  local state_file="${XDG_STATE_HOME:-$HOME/.local/state}/nvim/omarchy_theme"
  local sync

  mkdir -p "$HOME/.config/dotfiles" || return 1
  ln -sfn "$repo_dir" "$HOME/.config/dotfiles/theme" || return 1

  for sync in starship-theme-sync zed-theme-sync; do
    if [[ -x $HOME/.local/bin/$sync ]]; then
      "$HOME/.local/bin/$sync" || log "WARNING: $sync failed"
    fi
  done

  if [[ ! -e $state_file ]]; then
    mkdir -p "$(dirname "$state_file")" && printf 'onedark\n' >"$state_file" ||
      log "WARNING: could not write $state_file"
  fi
  return 0
}

remove_static_theme() {
  if [[ -L $HOME/.config/dotfiles/theme ]]; then
    rm -f "$HOME/.config/dotfiles/theme"
  fi
}
