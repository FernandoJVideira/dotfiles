#!/usr/bin/env bash
# Monitor layout shared by the Linux installers: detect the connected monitors,
# rank them by refresh rate (fastest = primary, at 0x0, the rest chained to its
# right in the same order) and write that layout into Hyprland's monitors.lua.
# The Nobara login screen (plasmalogin/KWin) is fed from the same list.
#
# Detection asks the running Hyprland (it knows each monitor's real mode list),
# so on a clean machine this only works from inside a Hyprland session. Outside
# one the functions warn and change nothing; re-run the installer from the
# desktop after the first login.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# Prints one line per monitor, fastest first:
#   name<TAB>width<TAB>height<TAB>refresh_hz<TAB>drm_connector_dir
# width/height/refresh are the best mode: the largest resolution, then the
# highest refresh rate at it. refresh_hz is the monitor's exact current rate when
# it already runs that mode (the mode list only has 2 decimals).
detect_monitors() {
  command -v hyprctl >/dev/null && command -v jq >/dev/null || return 1
  local json
  json="$(hyprctl monitors all -j 2>/dev/null)" || return 1
  [[ -n "$json" && "$json" != "[]" ]] || return 1
  jq -r '
    def parse: capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)Hz$")
               | {w: (.w|tonumber), h: (.h|tonumber), r: (.r|tonumber)};
    [ .[] | select(.disabled | not) | . as $m
      | ($m.availableModes | map(parse)
         | sort_by([.w * .h, .r]) | last) as $b
      | { name: $m.name, w: $b.w, h: $b.h,
          r: (if $m.width == $b.w and $m.height == $b.h
                 and (($m.refreshRate * 100 | round) == ($b.r * 100 | round))
              then $m.refreshRate else $b.r end) } ]
    | sort_by([-.r, .name])[]
    | [.name, .w, .h, .r] | @tsv' <<<"$json" |
  while IFS=$'\t' read -r name w h r; do
    local dir=""
    for dir in /sys/class/drm/card*-"$name"; do [[ -e "$dir" ]] && break; dir=""; done
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$w" "$h" "$r" "$dir"
  done
}

# Replaces the lines between "-- BEGIN generated: <name>" and "-- END generated:
# <name>" in <file> with the contents of <body-file>.
_replace_generated_block() {
  local file="$1" name="$2" body="$3"
  awk -v name="$name" -v body="$body" '
    $0 ~ "^-- BEGIN generated: " name { print; while ((getline l < body) > 0) print l; skip = 1; next }
    $0 ~ "^-- END generated: " name { skip = 0 }
    !skip { print }' "$file" >"$file.new" && mv "$file.new" "$file"
}

# sync_hypr_monitors <monitors.lua> [detect_monitors output]
sync_hypr_monitors() {
  local lua="$1" monitors="$2"
  [[ -f "$lua" ]] || { log "WARNING: $lua not found - skipping the monitor layout."; return 1; }
  [[ -n "$monitors" ]] || { log "WARNING: no monitors detected (not in a Hyprland session?) - kept the existing monitor layout. Re-run this script from the desktop to regenerate it."; return 1; }

  local tmp pos_body ws_body name i=0 first=1 ws
  tmp="$(mktemp -d)"
  pos_body="$tmp/pos"; ws_body="$tmp/ws"
  echo 'local configured_positions = {' >"$pos_body"
  : >"$ws_body"
  while IFS=$'\t' read -r name _; do
    if ((first)); then
      echo "  [\"$name\"] = \"0x0\"," >>"$pos_body"; first=0
    else
      echo "  [\"$name\"] = \"auto-right\"," >>"$pos_body"
    fi
    for ws in 1 2 3 4 5; do
      printf 'hl.workspace_rule({ workspace = "%d", monitor = "%s", default = %s, persistent = true })\n' \
        $((i * 5 + ws)) "$name" "$([[ $ws == 1 ]] && echo true || echo false)" >>"$ws_body"
    done
    i=$((i + 1))
  done <<<"$monitors"
  echo '}' >>"$pos_body"

  _replace_generated_block "$lua" monitors "$pos_body"
  _replace_generated_block "$lua" workspaces "$ws_body"
  rm -rf "$tmp"
  log "Monitor layout written to $lua (primary: $(head -n1 <<<"$monitors" | cut -f1))."
}

# EDID -> KWin's "edidIdentifier" ("<vendor> <product> <serial> <week> <year> 0")
_edid_identifier() {
  local b
  read -ra b < <(od -An -tu1 -j8 -N10 "$1")
  local v=$(( (b[0] << 8) | b[1] ))
  printf '%s%s%s %d %d %d %d 0' \
    "$(printf "\\$(printf '%03o' $((64 + ((v >> 10) & 31))))")" \
    "$(printf "\\$(printf '%03o' $((64 + ((v >> 5) & 31))))")" \
    "$(printf "\\$(printf '%03o' $((64 + (v & 31))))")" \
    $(( (b[3] << 8) | b[2] )) \
    $(( b[4] | (b[5] << 8) | (b[6] << 16) | (b[7] << 24) )) \
    "$(od -An -tu1 -j16 -N1 "$1" | tr -d ' ')" \
    $(( 1990 + $(od -An -tu1 -j17 -N1 "$1" | tr -d ' ') ))
}

# Prints a KWin kwinoutputconfig.json for the detected monitors: fastest on the
# left and primary, best mode, scale 1.
kwin_output_config() {
  local monitors="$1" name w h r dir edid x=0 prio=0 entries=() setup=()
  while IFS=$'\t' read -r name w h r dir; do
    edid="$dir/edid"
    [[ -n "$dir" && -r "$edid" ]] || { log "WARNING: no EDID for $name - leaving it out of the login screen layout." >&2; continue; }
    entries+=("$(jq -n --arg n "$name" --argjson w "$w" --argjson h "$h" --argjson r "$r" \
      --arg hash "$(md5sum <"$edid" | cut -d' ' -f1)" --arg id "$(_edid_identifier "$edid")" \
      --arg uuid "$(uuidgen)" '{
        abmLevel: 0, autoBrightnessCurve: [range(11) | 0], allowDdcCi: true, allowSdrSoftwareBrightness: false,
        autoRotation: "InTabletMode", automaticBrightness: false, brightness: 1,
        colorPowerTradeoff: "PreferEfficiency", colorProfileSource: "sRGB",
        connectorName: $n, customModes: [], detectedDdcCi: true,
        edidHash: $hash, edidIdentifier: $id, edrPolicy: "always",
        hdrColorProfileSource: "EDID", hdrIccProfilePath: "", highDynamicRange: false,
        iccProfilePath: "", maxBitsPerColor: 0,
        mode: {flags: 0, height: $h, refreshRate: ($r * 1000 | round), width: $w},
        overscan: 0, rgbRange: "Automatic", scale: 1, sdrBrightness: 200,
        sdrGamutWideness: 0, sharpness: 0, transform: "Normal", uuid: $uuid,
        vrrPolicy: "Never", wideColorGamut: false}')")
    setup+=("$(jq -n --argjson i "${#setup[@]}" --argjson x "$x" --argjson p "$prio" \
      '{enabled: true, outputIndex: $i, position: {x: $x, y: 0}, priority: $p, replicationSource: ""}')")
    x=$((x + w)); prio=$((prio + 1))
  done <<<"$monitors"
  ((${#entries[@]})) || return 1
  jq -n --slurpfile o <(printf '%s\n' "${entries[@]}") --slurpfile s <(printf '%s\n' "${setup[@]}") \
    '[{name: "outputs", data: $o}, {name: "setups", data: [{lidClosed: false, outputs: $s}]}]'
}

# Nobara: plasmalogin's greeter runs on KWin and reads its own output config, so
# without this it lays the monitors out in connector order at default rates.
sync_plasmalogin_monitors() {
  local monitors="$1" cfg
  [[ -n "$monitors" ]] || { log "WARNING: no monitors detected - login screen layout left alone."; return 1; }
  [[ -d /var/lib/plasmalogin ]] || { log "plasmalogin not installed - skipping the login screen layout."; return 0; }
  cfg="$(mktemp)"
  if kwin_output_config "$monitors" >"$cfg"; then
    log "Writing the login screen monitor layout..."
    sudo install -D -o plasmalogin -g plasmalogin -m 644 "$cfg" /var/lib/plasmalogin/.config/kwinoutputconfig.json
  else
    log "WARNING: couldn't build the login screen monitor layout."
  fi
  rm -f "$cfg"
}
