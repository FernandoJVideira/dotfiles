#!/usr/bin/env bash

# The calendar panel, opened from the clock: this month in a grid, today in brackets.
# `calendar.sh toggle` fills it in and opens or closes it.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"

fill() {
  local today first_dow days day col cell row
  today="$(date +%-d)"
  first_dow="$(date -v1d +%u)" # 1 = Monday
  days="$(date -v1d -v+1m -v-1d +%d)"
  days=$((10#$days))

  local args=(--set cal.title label="$(date '+%B %Y')" --set cal.head label=" Mo  Tu  We  Th  Fr  Sa  Su")
  day=1
  col=$((first_dow - 1))
  for row in 1 2 3 4 5 6; do
    cell=""
    for ((c = 0; c < 7; c++)); do
      if ((row == 1 && c < col)) || ((day > days)); then
        cell+="    "
      elif ((day == today)); then
        cell+="$(printf '[%2d]' "$day")"
        day=$((day + 1))
      else
        cell+="$(printf ' %2d ' "$day")"
        day=$((day + 1))
      fi
    done
    # a trailing empty row is hidden
    if [[ -z ${cell// /} ]]; then
      args+=(--set "cal.w$row" drawing=off)
    else
      args+=(--set "cal.w$row" drawing=on label="$cell")
    fi
  done
  sketchybar "${args[@]}"
}

if [[ ${1:-} == toggle ]]; then
  fill
  sketchybar --set clock popup.drawing=toggle
fi
