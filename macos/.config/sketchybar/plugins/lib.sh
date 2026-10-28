#!/usr/bin/env bash

# Shared by the plugins: the theme's colors (Gruvbox values until the first theme is set), and closing
# a popup when the pointer leaves it. The bar is icon-only; the values are in the panels.

COLORS_FILE="$HOME/.config/skein/current/theme/macos-colors.sh"
# shellcheck source=/dev/null
[[ -f $COLORS_FILE ]] && source "$COLORS_FILE"
CLR_FG="${CLR_FG:-0xffebdbb2}"
CLR_FG_DIM="${CLR_FG_DIM:-0x77ebdbb2}"
CLR_ACCENT="${CLR_ACCENT:-0xfffe8019}"
CLR_ALERT="${CLR_ALERT:-0xffa55555}"

# Returns 0 (and does the work) when this run is a pointer event, so a plugin can `hover && exit 0`:
# leaving an item and its popup closes the popup; the other pointer events need nothing.
hover() {
  case "${SENDER:-}" in
  mouse.exited.global)
    sketchybar --set "$NAME" popup.drawing=off
    return 0
    ;;
  mouse.entered | mouse.exited)
    return 0
    ;;
  esac
  return 1
}
