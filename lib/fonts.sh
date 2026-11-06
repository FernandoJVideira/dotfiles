#!/usr/bin/env bash
# install_fonts: copies the licensed fonts in the repo's gitignored fonts/ directory (Dank Mono) into
# the user font directory, and on Linux makes Dank Mono the GNOME/GTK monospace font. The fontconfig
# side (monospace -> Dank Mono) is linux/common/.config/fontconfig/conf.d/50-dank-mono.conf.
# Without the files it only logs; every config names a Nerd Font fallback.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

install_fonts() {
  local src dest f found=0
  src="$(cd "$(dirname "${BASH_SOURCE[0]}")/../fonts" && pwd)"
  if [[ $(uname) == Darwin ]]; then dest="$HOME/Library/Fonts"; else dest="$HOME/.local/share/fonts/dotfiles"; fi
  mkdir -p "$dest"
  for f in "$src"/*.ttf "$src"/*.otf; do
    [[ -f $f ]] || continue
    install -m 644 "$f" "$dest/" && found=1
  done
  if ((!found)); then
    log "WARNING: no fonts in $src - copy DankMono-*.ttf there and rerun ./bootstrap.sh (falling back to JetBrainsMono Nerd Font)."
    return 0
  fi
  log "Installed the fonts from $src into $dest"
  [[ $(uname) == Darwin ]] && return 0
  command -v fc-cache >/dev/null && fc-cache -f "$dest" >/dev/null
  if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface monospace-font-name "Dank Mono 10.5" \
      || log "WARNING: couldn't set the GTK monospace font."
  fi
}
