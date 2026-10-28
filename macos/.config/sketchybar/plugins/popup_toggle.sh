#!/usr/bin/env bash

# Open a panel, or close it when it is open (clicking its icon again). Only one panel is open at a time,
# and it closes at a click outside it (popup_watch.sh).
# Usage: popup_toggle.sh <item> [command to fill the panel in first...]

item="${1:?usage: popup_toggle.sh <item> [fill command...]}"
shift
dir="$(dirname "$0")"

state="$(sketchybar --query "$item" | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["popup"]["drawing"])')"
"$dir/popup_close.sh"
[[ $state == on ]] && exit 0

(($#)) && "$@"
sketchybar --set "$item" popup.drawing=on
sleep 0.05 # let it lay out before the watcher measures it
nohup "$dir/popup_watch.sh" "$item" >/dev/null 2>&1 &
disown
exit 0
