#!/usr/bin/env bash

# The clock around the notch: the day on the left of it, the time on the right.
case "$NAME" in
clock_date) sketchybar --set "$NAME" label="$(date '+%A %-d %B')" ;;
clock_time) sketchybar --set "$NAME" label="$(date '+%H:%M')" ;;
esac
