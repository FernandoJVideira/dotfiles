#!/usr/bin/env bash

# Output volume: the glyph follows the level, "muted" has its own. Shown while hovering.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"
hover && exit 0

if [[ ${SENDER:-} == volume_change && -n ${INFO:-} ]]; then
  volume="$INFO"
  muted=false
else
  # the first run and the slow refresh ask the system, since volume_change only fires on a change
  volume="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
  muted="$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)"
fi
[[ $volume == "missing value" || -z $volume ]] && volume=0

if [[ $muted == true || $volume -eq 0 ]]; then
  icon="󰖁"
elif ((volume < 30)); then
  icon="󰕿"
elif ((volume < 60)); then
  icon="󰖀"
else
  icon="󰕾"
fi
sketchybar --set "$NAME" icon="$icon" label="${volume}%" --set volume.slider slider.percentage="$volume" 2>/dev/null
