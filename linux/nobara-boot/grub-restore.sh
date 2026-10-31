#!/usr/bin/env bash
# Move a Nobara machine from booting Limine back to shim+GRUB (EFI), the path Nobara supports for EAC.
#
#   sudo ./grub-restore.sh             # do it
#   sudo ./grub-restore.sh --dry-run   # print every action, change nothing
#
# Idempotent. Secure Boot, firmware settings and EAC_DEFAULT are left alone; /boot/limine is kept.
# /boot is the ESP (vfat, case-insensitive), so payloads go straight to /boot/EFI; the shim/grub RPM
# scriptlets only update /boot/efi, which does not exist here, so rerun this script after such updates.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/grub.sh
source "$HERE/../../lib/grub.sh"

BACKUP_DIR=/var/lib/grub-restore
ESP=/boot
LABEL="Nobara (GRUB)"
OLD_LABEL="Limine (Nobara)"
EAC_HOOK=/usr/lib/kernel/install.d/95-nobara-eac.install
DRY_RUN=0

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$*"; }
die() { printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

case ${1:-} in
  '') ;;
  --dry-run) DRY_RUN=1 ;;
  *) die "usage: sudo $0 [--dry-run]" ;;
esac

[[ $EUID -eq 0 || ${GRUB_RESTORE_SKIP_ROOT_CHECK:-} == 1 ]] || die "run as root: sudo $0"

run() {
  if ((DRY_RUN)); then printf '   [dry-run] %s\n' "$*"; else "$@"; fi
}

need() { for c in "$@"; do command -v "$c" >/dev/null || die "missing command: $c"; done; }

newest() { # glob -> newest matching directory
  local d
  # shellcheck disable=SC2012,SC2086
  d=$(ls -d $1 2>/dev/null | sort -V | tail -1) || true
  [[ -n $d && -d $d ]] || die "no directory matches $1"
  printf '%s\n' "$d"
}

boot_entry_num() { # label -> hex number of the first UEFI entry with that label, if any
  efibootmgr | awk -F'\t' -v want="$1" '
    /^Boot[0-9A-Fa-f]{4}/ {
      name = $1; sub(/^Boot[0-9A-Fa-f]{4}\*? /, "", name)
      if (name == want) { print substr($1, 5, 4); exit }
    }'
}

preflight() {
  [[ -d /sys/firmware/efi ]] || die "not booted via UEFI"
  need efibootmgr cp findmnt lsblk cmp
  [[ $(findmnt -no FSTYPE /boot | head -1) == vfat ]] || die "/boot is not vfat"
  [[ -f /boot/grub2/grub.cfg ]] || die "/boot/grub2/grub.cfg is missing"
  [[ -f /boot/EFI/BOOT/BOOTX64.EFI || -f /boot/limine/BOOTX64.EFI.bak ]] || die "no Limine fallback loader and no backup of it"
  SHIM_DIR=$(newest '/usr/lib/efi/shim/*/EFI')
  GRUB_DIR=$(newest '/usr/lib/efi/grub2/*/EFI')
  [[ -f $SHIM_DIR/fedora/shimx64.efi && -f $SHIM_DIR/BOOT/BOOTX64.EFI ]] || die "incomplete shim payload in $SHIM_DIR"
  [[ -f $GRUB_DIR/fedora/grubx64.efi ]] || die "incomplete grub payload in $GRUB_DIR"
}

drop_stale_bind() {
  if mountpoint -q /boot/EFI; then
    say "unmounting stale bind mounts on /boot/EFI"
    # failed runs can leave several stacked
    for _ in 1 2 3 4; do mountpoint -q /boot/EFI && run umount /boot/EFI || true; ((DRY_RUN)) && break; done
  fi
  if grep -qE '^/boot /boot/efi none bind' /etc/fstab; then
    say "removing stale /boot/efi bind mount from /etc/fstab"
    run mkdir -p "$BACKUP_DIR"
    run cp -a /etc/fstab "$BACKUP_DIR/fstab.$(date +%Y%m%d-%H%M%S)"
    run sed -i '\#^/boot /boot/efi none bind#d' /etc/fstab
    run systemctl daemon-reload
  fi
}

copy_payloads() {
  local f
  run mkdir -p "$ESP/EFI/fedora" "$ESP/EFI/BOOT"
  # fedora/ first so the disk always has a bootable shim+GRUB pair before the fallback loader is replaced
  for f in "$SHIM_DIR"/fedora/* "$GRUB_DIR"/fedora/*; do run cp -f "$f" "$ESP/EFI/fedora/"; done
  for f in "$SHIM_DIR"/BOOT/*; do run cp -f "$f" "$ESP/EFI/BOOT/"; done
  if ((DRY_RUN)); then return; fi
  cmp -s "$SHIM_DIR/fedora/shimx64.efi" "$ESP/EFI/fedora/shimx64.efi" || die "shimx64.efi copy does not match"
  cmp -s "$GRUB_DIR/fedora/grubx64.efi" "$ESP/EFI/fedora/grubx64.efi" || die "grubx64.efi copy does not match"
}

register_entry() {
  local src part disk num
  src=$(findmnt -no SOURCE /boot | head -1)
  part=$(cat "/sys/class/block/$(basename "$src")/partition")
  disk="/dev/$(lsblk -no PKNAME "$src" | head -1)"
  if [[ -z $(boot_entry_num "$LABEL") ]]; then
    say "registering UEFI entry '$LABEL'"
    run efibootmgr -c -d "$disk" -p "$part" -L "$LABEL" -l '\EFI\fedora\shimx64.efi'
  else
    say "UEFI entry '$LABEL' already present"
  fi
  num=$(boot_entry_num "$OLD_LABEL")
  if [[ -n $num ]]; then
    say "removing UEFI entry '$OLD_LABEL' (Boot$num)"
    run efibootmgr -B -b "$num"
  fi
}

reenable_hook() {
  local mask=/etc/kernel/install.d/99-grub-mkconfig.install
  if [[ -L $mask && $(readlink "$mask") == /dev/null ]]; then
    say "unmasking $mask"
    run rm -f "$mask"
  fi
}

remove_limine() {
  say "removing Limine files from the system (/boot/limine stays)"
  run rm -f /etc/kernel/install.d/95-limine.install /usr/local/libexec/limine-sync
  run rm -rf /usr/local/share/limine-sync
}

preflight

if ((DRY_RUN)); then
  say "dry run: nothing will be changed"
else
  read -r -p "Move this machine from Limine back to shim+GRUB. Type YES to continue: " ans
  [[ $ans == YES ]] || die "aborted"
fi

drop_stale_bind

say "backing up Limine's fallback loader"
if [[ ! -e /boot/limine/BOOTX64.EFI.bak ]]; then
  run cp -p /boot/EFI/BOOT/BOOTX64.EFI /boot/limine/BOOTX64.EFI.bak
fi

say "copying shim and GRUB to the ESP"
copy_payloads

register_entry

reenable_hook

remove_limine

say "theming GRUB and regenerating grub.cfg"
if ((DRY_RUN)); then
  printf '   [dry-run] grub_setup\n'
  printf '   [dry-run] %s apply-all\n' "$EAC_HOOK"
else
  grub_setup
  "$EAC_HOOK" apply-all
fi

say "boot order"
efibootmgr | grep -E '^Boot(Order|Current)' || true
if ! ((DRY_RUN)); then
  say "GRUB menu entries: $(grep -c '^menuentry' /boot/grub2/grub.cfg)"
fi

cat <<'EOF'

Done. The next reboot should show the GRUB menu (shim+GRUB).
Limine files remain in /boot/limine.
After a shim or grub2-efi update, rerun: sudo grub-restore.sh (the RPM scriptlets only update /boot/efi, which does not exist here).
Rollback: cp /boot/limine/BOOTX64.EFI.bak /boot/EFI/BOOT/BOOTX64.EFI, then
  efibootmgr -c -d <disk> -p <partition> -L "Limine (Nobara)" -l '\EFI\BOOT\BOOTX64.EFI'
EOF
