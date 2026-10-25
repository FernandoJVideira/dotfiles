#!/usr/bin/env bash

# Theme colors (see sketchybarrc); Gruvbox values until the first theme is set
COLORS_FILE="$HOME/.config/omadora/current/theme/macos-colors.sh"
# shellcheck source=/dev/null
[[ -f $COLORS_FILE ]] && source "$COLORS_FILE"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME label.color="${CLR_ACCENT:-0xfffe8019}"
else
    sketchybar --set $NAME label.color="${CLR_FG_DIM:-0x77ebdbb2}"
fi
