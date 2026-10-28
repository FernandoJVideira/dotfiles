#!/usr/bin/env bash

# Close every panel and stop the click watcher.
pidfile=/tmp/skein-popup-watch.pid

args=()
for parent in skein clock battery cpu_load volume net; do
  args+=(--set "$parent" popup.drawing=off)
done
sketchybar "${args[@]}"

if [[ -f $pidfile ]]; then
  kill "$(cat "$pidfile")" 2>/dev/null
  rm -f "$pidfile"
fi
exit 0
