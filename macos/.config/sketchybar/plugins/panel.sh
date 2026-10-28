#!/usr/bin/env bash

# The battery, Wi-Fi and CPU panels (Skein's panels as popups): fill in the lines (popup_toggle.sh opens
# the popup). Usage: panel.sh <battery|net|cpu_load>
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh"

panel="${1:?usage: panel.sh <battery|net|cpu_load>}"
rows=()
extra=()

case "$panel" in
battery)
  info="$(pmset -g batt)"
  charge="$(grep -o '[0-9]\+%' <<<"$info" | head -n 1)"
  source_name="$(sed -n "s/^Now drawing from '\(.*\)'.*/\1/p" <<<"$info")"
  state="$(grep -oE 'discharging|finishing charge|charging|charged|AC attached' <<<"$info" | head -n 1)"
  remaining="$(grep -oE '[0-9]+:[0-9]+ remaining' <<<"$info" | head -n 1)"
  rows=("Charge   ${charge:-n/a}" "Source   ${source_name:-unknown}" "State    ${state:-unknown}")
  [[ -n $remaining ]] && rows+=("Time     $remaining")
  ;;
net)
  power="$(networksetup -getairportpower en0 2>/dev/null | awk '{print $NF}')"
  ssid="$(networksetup -getairportnetwork en0 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p')"
  address="$(ipconfig getifaddr en0 2>/dev/null)"
  if [[ $power == Off ]]; then
    rows=("Wi-Fi    off")
    extra=(--set net.power label="Turn Wi-Fi on")
  else
    rows=("Network  ${ssid:-${address:+connected}}" "Address  ${address:-none}")
    [[ -z ${ssid:-$address} ]] && rows=("Network  not connected")
    extra=(--set net.power label="Turn Wi-Fi off")
  fi
  ;;
cpu_load)
  cores="$(sysctl -n hw.logicalcpu)"
  load="$(ps -A -o %cpu | awk -v cores="$cores" '{ s += $1 } END { printf "%.0f", s / cores }')"
  rows=("CPU      ${load}%")
  while IFS= read -r line; do
    rows+=("$line")
  done < <(ps -Ao pcpu=,comm= -r | head -n 5 | awk '{ cpu = $1; $1 = ""; sub(/^ +/, ""); n = split($0, p, "/"); printf "%5.1f%%  %s\n", cpu, substr(p[n], 1, 28) }')
  ;;
esac

args=()
for i in 1 2 3 4 5 6; do
  if ((i <= ${#rows[@]})); then
    args+=(--set "$panel.i$i" drawing=on label="${rows[$((i - 1))]}")
  else
    args+=(--set "$panel.i$i" drawing=off)
  fi
done
sketchybar "${args[@]}" "${extra[@]}"

exit 0
