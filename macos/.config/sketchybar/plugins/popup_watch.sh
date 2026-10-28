#!/usr/bin/env bash

# While a panel is open, close it at the first click outside it (and outside the bar: a click on another
# item there switches panels). Started by popup_toggle.sh; popup_close.sh stops it.
# Usage: popup_watch.sh <item whose popup is open>

item="${1:?usage: popup_watch.sh <item>}"
dir="$(dirname "$0")"
pidfile=/tmp/skein-popup-watch.pid
bar_height="$(sketchybar --query bar | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["height"])')"

# the panel's rectangle: its visible rows (hidden ones are parked at y = -9999), with some margin
rect="$(sketchybar --query "$item" | python3 -I -c '
import json, subprocess, sys
rows = []
for name in json.load(sys.stdin)["popup"]["items"]:
    d = json.loads(subprocess.check_output(["sketchybar", "--query", name]))
    if d["geometry"]["drawing"] != "on":
        continue
    for r in d["bounding_rects"].values():
        x, y = r["origin"]
        w, h = r["size"]
        if y > -1000:
            rows.append((x, y, x + w, y + h))
if rows:
    pad = 14
    print(min(r[0] for r in rows) - pad, min(r[1] for r in rows) - pad, max(r[2] for r in rows) + pad, max(r[3] for r in rows) + pad)
')"
[[ -n $rect ]] || exit 0

out="$(mktemp)"
# shellcheck disable=SC2086
osascript -l JavaScript "$dir/popup_watch.js" $rect "$bar_height" 120 >"$out" 2>/dev/null &
watcher=$!
echo "$watcher" >"$pidfile"
wait "$watcher"
result="$(cat "$out")"
rm -f "$out"
# only remove our own pid file: a new watcher may already have written its own
[[ "$(cat "$pidfile" 2>/dev/null)" == "$watcher" ]] && rm -f "$pidfile"

[[ $result == outside ]] && "$dir/popup_close.sh"
exit 0
