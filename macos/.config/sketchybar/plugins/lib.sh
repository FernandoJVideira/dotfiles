#!/usr/bin/env bash

# Shared by the plugins: the theme's colors (Gruvbox values until the first theme is set), and the hover
# label. The bar is icon-only; a module's value shows while the pointer is over it, like Skein's tooltips.

COLORS_FILE="$HOME/.config/skein/current/theme/macos-colors.sh"
# shellcheck source=/dev/null
[[ -f $COLORS_FILE ]] && source "$COLORS_FILE"
CLR_FG="${CLR_FG:-0xffebdbb2}"
CLR_FG_DIM="${CLR_FG_DIM:-0x77ebdbb2}"
CLR_ACCENT="${CLR_ACCENT:-0xfffe8019}"
CLR_ALERT="${CLR_ALERT:-0xffa55555}"

# Returns 0 (and does the work) when this run is a pointer event, so a plugin can `hover && exit 0`
hover() {
  case "${SENDER:-}" in
  mouse.entered)
    sketchybar --set "$NAME" label.drawing=on
    return 0
    ;;
  mouse.exited)
    sketchybar --set "$NAME" label.drawing=off
    return 0
    ;;
  mouse.exited.global)
    # the pointer left the item and its popup: close the popup too
    sketchybar --set "$NAME" label.drawing=off popup.drawing=off
    return 0
    ;;
  esac
  return 1
}
