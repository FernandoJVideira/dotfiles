#!/usr/bin/env bash

# All the workspace items at once (so a refresh is two Hyprspace calls, not twenty): the one in use is in the
# accent color, the others in the text color, dimmed while empty. All ten are always shown.
# Runs on workspace changes and every two seconds, for windows opening and closing.

# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"

focused="${FOCUSED_WORKSPACE:-$(hyprspace list-workspaces --focused 2>/dev/null)}"
occupied=" $(hyprspace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ') "

args=()
for sid in 1 2 3 4 5 6 7 8 9 10; do
  has=0
  [[ $occupied == *" $sid "* ]] && has=1
  if [[ $sid == "$focused" ]]; then
    color="$CLR_ACCENT"
  elif ((has)); then
    color="$CLR_FG"
  else
    color="$CLR_FG_DIM"
  fi
  args+=(--set "space.$sid" drawing=on icon.color="$color")
done
sketchybar "${args[@]}"
