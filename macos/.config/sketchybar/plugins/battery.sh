#!/usr/bin/env bash

# Battery: Skein's glyph for the level, the alert color when it is low and not charging.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"
hover && exit 0

info="$(pmset -g batt)"
percentage="$(grep -o '[0-9]\+%' <<<"$info" | head -n 1 | tr -d %)"
if [[ -z $percentage ]]; then
  sketchybar --set "$NAME" drawing=off # a desktop Mac has no battery
  exit 0
fi

discharging=("󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
charging=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
index=$((percentage / 10))
((index > 9)) && index=9

color="$CLR_FG"
if grep -q 'AC Power' <<<"$info"; then
  icon="${charging[$index]}"
else
  icon="${discharging[$index]}"
  ((percentage <= 15)) && color="$CLR_ALERT"
fi

sketchybar --set "$NAME" drawing=on icon="$icon" icon.color="$color" label="${percentage}%"
