#!/usr/bin/env bash

# The clock, short like macOS's: "Wed 28 Oct  18:45". Its text is always shown (it has no hover label),
# so leaving it only closes the calendar panel.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"

if [[ ${SENDER:-} == mouse.exited.global ]]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

sketchybar --set "$NAME" label="$(date '+%a %-d %b  %H:%M')"
