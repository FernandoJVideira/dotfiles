#!/usr/bin/env bash

# The audio panel's slider: a click sets the output volume to where it landed.
if [[ ${SENDER:-} == mouse.clicked ]]; then
  osascript -e "set volume output volume ${PERCENTAGE:-0}"
  NAME=volume "$(dirname "$0")/volume.sh"
fi
