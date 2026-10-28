#!/usr/bin/env bash

# Turn Wi-Fi off, or on again (the Wi-Fi panel's first action).
if [[ "$(networksetup -getairportpower en0 2>/dev/null | awk '{print $NF}')" == On ]]; then
  networksetup -setairportpower en0 off
else
  networksetup -setairportpower en0 on
fi
