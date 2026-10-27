#!/usr/bin/env bash
# Arch / CachyOS: make sure Limine is installed and apply the shared menu theme
# (lib/limine-theme.conf, the same Tokyo Night look as Omarchy) to the limine.conf in use.
# It never converts the machine to Limine: with another bootloader it only installs the package.

LIMINE_THEME_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/limine-theme.conf"

limine_find_conf() {
  local c
  for c in /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf /boot/EFI/BOOT/limine.conf \
           /efi/limine.conf /efi/limine/limine.conf /efi/EFI/limine/limine.conf /efi/EFI/BOOT/limine.conf; do
    [[ -f $c ]] && { echo "$c"; return 0; }
  done
  return 1
}

# Replace the theme block in the global section of a limine.conf (everything before the
# first /entry). Idempotent: the block sits between markers, and stray copies of the same
# keys in the global section are dropped so they can't override it.
limine_apply_theme() {
  local conf=$1
  sudo cp -f "$conf" "$conf.dotfiles-bak"
  sudo python3 - "$conf" "$LIMINE_THEME_SRC" <<'PY'
import re, sys
conf, themef = sys.argv[1], sys.argv[2]
theme = open(themef).read().strip('\n')
keys = {l.split(':', 1)[0].strip() for l in theme.splitlines() if re.match(r'^[a-z_]+:', l)}
BEGIN, END = '# BEGIN dotfiles-theme', '# END dotfiles-theme'
text = re.sub(re.escape(BEGIN) + r'.*?' + re.escape(END) + r'\n?', '', open(conf).read(), flags=re.S)
lines, head, rest = text.splitlines(keepends=True), [], []
for i, l in enumerate(lines):
    if l.startswith('/'):
        rest = lines[i:]
        break
    head.append(l)
head = [l for l in head if l.split(':', 1)[0].strip() not in keys]
out = ''.join(head).rstrip('\n') + '\n\n' + BEGIN + '\n' + theme + '\n' + END + '\n\n' + ''.join(rest)
open(conf, 'w').write(out)
PY
}

limine_setup() {
  log "Installing Limine..."
  sudo pacman -S --needed --noconfirm limine
  local conf
  if conf=$(limine_find_conf); then
    log "Applying the Limine menu theme to $conf..."
    limine_apply_theme "$conf" \
      || log "WARNING: could not theme $conf (backup: $conf.dotfiles-bak)."
    log "If your boot-entry tool regenerates limine.conf, re-run this script afterwards to re-apply the theme."
  else
    log "WARNING: Limine is installed but no limine.conf was found (/boot or /efi) - this machine doesn't boot via Limine, so no theme was applied."
  fi
}
