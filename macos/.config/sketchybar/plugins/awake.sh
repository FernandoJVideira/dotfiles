#!/usr/bin/env bash

# Stay awake (caffeinate), like Skein's indicator: the accent color while on, dimmed while off.
# Click toggles it: `awake.sh toggle`.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"
NAME="${NAME:-awake}"

if [[ ${1:-} == toggle ]]; then
  if pgrep -x caffeinate >/dev/null; then
    pkill -x caffeinate
  else
    nohup caffeinate -di >/dev/null 2>&1 &
    disown
  fi
  sleep 0.2
fi

if pgrep -x caffeinate >/dev/null; then
  sketchybar --set "$NAME" icon.color="$CLR_ACCENT"
else
  sketchybar --set "$NAME" icon.color="$CLR_FG_DIM"
fi
