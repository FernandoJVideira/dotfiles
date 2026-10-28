#!/usr/bin/env bash

# The clock, short like macOS's: "Wed 28 Oct  18:45". Opens the calendar panel on click.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"
hover && exit 0

sketchybar --set "$NAME" label="$(date '+%a %-d %b  %H:%M')"
