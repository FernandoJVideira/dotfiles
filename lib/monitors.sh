#!/usr/bin/env bash
# Monitor layout shared by the Linux installers: detect the connected monitors,
# rank them by refresh rate (fastest = primary, at 0x0, the rest chained to its
# right in the same order) and write that layout into Hyprland's monitors.lua.
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
         | sort_by([.w * .h, .r]) | last
         # nested/virtual outputs can report no mode list: use the current mode
         // {w: $m.width, h: $m.height, r: $m.refreshRate}) as $b
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
