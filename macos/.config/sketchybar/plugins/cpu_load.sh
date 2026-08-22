#!/bin/bash

# Calculate CPU load percentage natively (no external dependencies required)
CORE_COUNT=$(sysctl -n hw.logicalcpu)
CPU_LOAD=$(ps -A -o %cpu | awk -v cores="$CORE_COUNT" '{s+=$1} END {printf "%.1f%%\n", s/cores}')

# Override the thermometer icon with a CPU chip icon and set the load percentage
sketchybar --set "$NAME" \
  icon="" \
  label="$CPU_LOAD"
