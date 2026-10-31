#!/usr/bin/env bash
# Nobara: theme the GRUB menu like the Limine one (Tokyo Night, "Skein Bootloader").
# Paths are overridable through GRUB_ETC_DEFAULT, GRUB_THEME_DIR, GRUB_CFG_TARGET and
# GRUB_SKIP_MKCONFIG=1 so it can be tested without root.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

GRUB_THEME_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/grub-theme/theme.txt"

# Run directly when the target is writable by us, else through sudo.
_grub_run() {
  local target=$1; shift
  local probe=$target
  [[ -e $probe ]] || probe=$(dirname "$target")
  while [[ ! -e $probe ]]; do probe=$(dirname "$probe"); done
  if [[ -w $probe ]]; then "$@"; else sudo "$@"; fi
}

_grub_set_key() {
  local file=$1 key=$2 val=$3 tmp
  tmp=$(mktemp)
  awk -v k="$key" -v v="$val" '
    BEGIN { re = "^[[:space:]]*" k "=" }
    $0 ~ re { if (!done) print k "=" v; done = 1; next }
    { print }
    END { if (!done) print k "=" v }
  ' "$file" > "$tmp"
  _grub_run "$file" cp -f "$tmp" "$file"
  rm -f "$tmp"
}

grub_setup() {
  local etc=${GRUB_ETC_DEFAULT:-/etc/default/grub}
  local dir=${GRUB_THEME_DIR:-/boot/grub2/themes/skein}
  local font ttf tmp f

  ttf=$(fc-match -f '%{file}' monospace 2>/dev/null || true)
  if [[ -z $ttf || ! -f $ttf ]]; then
    ttf=
    for f in /usr/share/fonts/dejavu*/DejaVuSansMono.ttf /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf; do
      [[ -f $f ]] && { ttf=$f; break; }
    done
  fi
  if [[ -z $ttf || ! -f $ttf ]]; then
    log "WARNING: no monospace font found - GRUB theme not applied."
    return 1
  fi
  if ! command -v grub2-mkfont >/dev/null; then
    log "WARNING: grub2-mkfont not installed - GRUB theme not applied."
    return 1
  fi

  log "Installing the GRUB theme to $dir..."
  tmp=$(mktemp -d)
  font=$tmp/skein.pf2
  grub2-mkfont -n Skein -s 16 -o "$font" "$ttf" 2>/dev/null
  _grub_run "$dir" mkdir -p "$dir"
  _grub_run "$dir" install -m 644 "$GRUB_THEME_SRC" "$dir/theme.txt"
  _grub_run "$dir" install -m 644 "$font" "$dir/skein.pf2"
  rm -rf "$tmp"

  log "Pointing $etc at the theme..."
  _grub_set_key "$etc" GRUB_TERMINAL_OUTPUT gfxterm
  _grub_set_key "$etc" GRUB_THEME "$dir/theme.txt"
  _grub_set_key "$etc" GRUB_GFXMODE auto

  if [[ ${GRUB_SKIP_MKCONFIG:-0} == 1 ]]; then
    log "Skipping grub2-mkconfig (GRUB_SKIP_MKCONFIG=1)."
    return 0
  fi
  if ! command -v grub2-mkconfig >/dev/null; then
    log "grub2-mkconfig not installed - skipping config regeneration."
    return 0
  fi
  local cfg=${GRUB_CFG_TARGET:-}
  if [[ -z $cfg ]]; then
    cfg=$(readlink -f /etc/grub2-efi.cfg 2>/dev/null || true)
    [[ -n $cfg && -e $cfg ]] || cfg=/boot/grub2/grub.cfg
  fi
  log "Regenerating $cfg..."
  _grub_run "$cfg" grub2-mkconfig -o "$cfg"
}
