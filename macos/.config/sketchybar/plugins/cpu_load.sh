#!/usr/bin/env bash

# CPU load as a share of all the cores, with no helper needed; shown while hovering.
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"
hover && exit 0

cores="$(sysctl -n hw.logicalcpu)"
load="$(ps -A -o %cpu | awk -v cores="$cores" '{ s += $1 } END { printf "%.0f", s / cores }')"
sketchybar --set "$NAME" label="CPU ${load}%"
