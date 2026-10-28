#!/usr/bin/env bash

# All the workspace items at once (so a refresh is two Hyprspace calls, not twenty): the one in use shows
# a dot in the accent color, the others their number, dimmed while empty. 6-10 only show while they have
# windows. Runs on workspace changes and every two seconds, for windows opening and closing.

# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"

focused="${FOCUSED_WORKSPACE:-$(hyprspace list-workspaces --focused 2>/dev/null)}"
occupied=" $(hyprspace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ') "

args=()
for sid in 1 2 3 4 5 6 7 8 9 10; do
  item="space.$sid"
  has=0
  [[ $occupied == *" $sid "* ]] && has=1
  if [[ $sid == "$focused" ]]; then
    args+=(--set "$item" drawing=on icon.drawing=on label.drawing=off)
  else
    color="$CLR_FG"
    ((has)) || color="$CLR_FG_DIM"
    show=on
    ((sid > 5 && !has)) && show=off
    args+=(--set "$item" drawing="$show" icon.drawing=off label.drawing=on label.color="$color")
  fi
done
sketchybar "${args[@]}"
