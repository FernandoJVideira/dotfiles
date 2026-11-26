#!/usr/bin/env bash

# Stay awake (caffeinate), like Skein's indicator: a bright filled cup while on, a dim outline while off.
# Click toggles it: `awake.sh toggle`.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"
NAME="${NAME:-awake}"
# only our own caffeinate: other apps run theirs (e.g. `caffeinate -i -w <pid>`), and those must
# neither light the icon nor be killed by a click
OWN="caffeinate -di"

if [[ ${1:-} == toggle ]]; then
  if pgrep -xf "$OWN" >/dev/null; then
    pkill -xf "$OWN"
  else
    nohup caffeinate -di >/dev/null 2>&1 &
    disown
  fi
  sleep 0.2
fi

# the glyph changes too (filled cup on, outline off): in a monochrome theme the accent and the dim
# color are both grey, so color alone doesn't show the state
if pgrep -xf "$OWN" >/dev/null; then
  sketchybar --set "$NAME" icon="󰅶" icon.color="$CLR_FG"
else
  sketchybar --set "$NAME" icon="󰛊" icon.color="$CLR_FG_DIM"
fi
