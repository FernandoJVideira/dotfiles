#!/usr/bin/env bash

# Wi-Fi: connected or not as the glyph, the network's name while hovering.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"
hover && exit 0

ssid="$(networksetup -getairportnetwork en0 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p')"
if [[ -z $ssid ]]; then
  # newer systems don't hand the name out; the interface's address still says whether it is connected
  if ipconfig getifaddr en0 >/dev/null 2>&1; then
    sketchybar --set "$NAME" icon="󰖩" icon.color="$CLR_FG" label="Connected"
  else
    sketchybar --set "$NAME" icon="󰖪" icon.color="$CLR_FG_DIM" label="Offline"
  fi
else
  sketchybar --set "$NAME" icon="󰖩" icon.color="$CLR_FG" label="$ssid"
fi
