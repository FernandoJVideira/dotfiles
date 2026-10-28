#!/usr/bin/env bash

# Shared by the plugins: the theme's colors (Gruvbox values until the first theme is set), and
# ignoring pointer events. The bar is icon-only; the values are in the panels.

COLORS_FILE="$HOME/.config/skein/current/theme/macos-colors.sh"
# shellcheck source=/dev/null
[[ -f $COLORS_FILE ]] && source "$COLORS_FILE"
CLR_FG="${CLR_FG:-0xffebdbb2}"
CLR_FG_DIM="${CLR_FG_DIM:-0x77ebdbb2}"
CLR_ACCENT="${CLR_ACCENT:-0xfffe8019}"
CLR_ALERT="${CLR_ALERT:-0xffa55555}"

# Returns 0 for the pointer events a plugin has no use for, so it can `hover && exit 0`
hover() {
  case "${SENDER:-}" in
  mouse.entered | mouse.exited | mouse.exited.global) return 0 ;;
  esac
  return 1
}
