#!/usr/bin/env bash
# Move a Nobara machine from BIOS+GRUB to UEFI+Limine, safely, in two phases.
# Nobara-only and deliberately NOT part of install.sh: it repartitions the boot disk.
#
# Why a new /boot: Limine (12.9.1, tested) only reads FAT32 here - not ext4 - in both BIOS and UEFI
# mode, and GRUB's /boot is ext4. So /boot becomes a FAT32 EFI System Partition.
#
#   sudo ./limine-migrate.sh prepare   # phase 1, run while still booted in BIOS via GRUB:
#                                      #   shrink swap by 2 GiB, make a FAT32 /boot there, copy the kernels,
#                                      #   install Limine (EFI) + its config + the kernel-install hook,
#                                      #   point /etc/fstab at the new /boot. GRUB and the old ext4 /boot
#                                      #   are left alone, so BIOS boot keeps working.
#   (reboot; confirm Nobara still boots in BIOS; then in the firmware switch to UEFI, disable Secure Boot,
#    boot the disk: Limine should show a menu)
#   sudo ./limine-migrate.sh finish    # phase 2, run after booting via UEFI+Limine:
#                                      #   register the UEFI boot entry, stop kernel-install using GRUB
#   sudo ./limine-migrate.sh purge-grub  # optional: remove the (unused, dnf-protected) GRUB and shim packages
#   sudo ./limine-migrate.sh auto      # what the Nobara bootstrap runs: picks prepare or finish for this machine
#   sudo ./limine-migrate.sh rollback  # undo phase 1's fstab change (before switching to UEFI)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR=/var/lib/limine-migrate
SYNC_BIN=/usr/local/libexec/limine-sync
THEME_SRC="$HERE/../../lib/limine-theme.conf"
THEME_DEST=/usr/local/share/limine-sync/theme.conf
PLUGIN=/etc/kernel/install.d/95-limine.install
NEW_BOOT_SECTORS=4194304 # 2 GiB of 512-byte sectors
STAGE=/mnt/limine-newboot

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$*"; }
die() { printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "run as root: sudo $0 ${1:-prepare}"

need() { for c in "$@"; do command -v "$c" >/dev/null || die "missing command: $c (sudo dnf install gdisk dosfstools rsync limine efibootmgr)"; done; }

disk_of() { echo "/dev/$(lsblk -no PKNAME "$1" | head -1)"; }
partnum_of() { cat "/sys/class/block/$(basename "$1")/partition"; }
part_path() { # disk partnum -> device path (handles nvme0n1p4 vs sda4)
  case $1 in *[0-9]) echo "$1p$2" ;; *) echo "$1$2" ;; esac
}

# limine-sync and its theme; safe to repeat. The kernel-install hook is installed separately, once /boot is switched.
install_assets() {
  install -Dm755 "$HERE/limine-sync" "$SYNC_BIN"
  install -Dm644 "$THEME_SRC" "$THEME_DEST"
}

cmd_prepare() {
  need sgdisk rsync mkfs.fat mkswap swapoff swapon blkid limine partprobe lsblk findmnt
  [[ -f /usr/share/limine/BOOTX64.EFI ]] || die "limine package is missing BOOTX64.EFI (sudo dnf install limine; Terra repo)"
  mountpoint -q /boot || die "/boot must be its own partition"
  [[ $(findmnt -no FSTYPE /boot) == ext* ]] || die "/boot is not ext2/3/4 - nothing to migrate (already $(findmnt -no FSTYPE /boot)?)"
  [[ -d /boot/loader/entries ]] || die "no Boot Loader Spec entries in /boot/loader/entries"

  local old_boot disk swap_part swap_n swap_uuid swap_label swap_guid swap_start swap_end
  old_boot=$(findmnt -no SOURCE /boot)
  disk=$(disk_of "$old_boot")
  [[ $(lsblk -dno PTTYPE "$disk") == gpt ]] || die "$disk is not GPT"

  # The swap partition must be the last partition on the same disk.
  swap_part=$(lsblk -lno NAME,PARTTYPE "$disk" | awk 'tolower($2)=="0657fd6d-a4ab-43c4-84e5-0933c84b4f4f"{print "/dev/"$1}' | tail -1)
  [[ -n $swap_part ]] || die "no Linux swap partition on $disk to take 2 GiB from"
  swap_n=$(partnum_of "$swap_part")
  [[ $(sgdisk -p "$disk" | awk '/^ +[0-9]+ /{n=$1} END{print n}') == "$swap_n" ]] || die "$swap_part is not the last partition on $disk"
  swap_start=$(sgdisk -i "$swap_n" "$disk" | awk '/First sector:/{print $3}')
  swap_end=$(sgdisk -i "$swap_n" "$disk" | awk '/Last sector:/{print $3}')
  (( swap_end - swap_start + 1 > 2 * NEW_BOOT_SECTORS )) || die "swap is too small to give up 2 GiB"
  swap_uuid=$(blkid -s UUID -o value "$swap_part"); swap_label=$(blkid -s LABEL -o value "$swap_part" || true)
  swap_guid=$(sgdisk -i "$swap_n" "$disk" | awk '/Partition unique GUID:/{print $4}')
  [[ -n $swap_uuid && -n $swap_guid ]] || die "could not read the swap UUID/GUID from $swap_part"

  say "Boot disk $disk; old /boot is $old_boot (ext4); swap is $swap_part (UUID $swap_uuid)"
  say "Plan: shrink $swap_part by 2 GiB and create a FAT32 /boot in the freed space. Swap contents are discarded."
  warn "A saved hibernation image will be lost. Nothing else on the disk is modified."
  read -rp "Type YES to continue: " a; [[ $a == YES ]] || die "aborted"

  mkdir -p "$BACKUP_DIR"
  local stamp; stamp=$(date +%Y%m%d%H%M%S)
  sgdisk --backup="$BACKUP_DIR/gpt-$stamp.bin" "$disk" >/dev/null
  cp -a /etc/fstab "$BACKUP_DIR/fstab-$stamp"
  ln -sf "fstab-$stamp" "$BACKUP_DIR/fstab-latest"; ln -sf "gpt-$stamp.bin" "$BACKUP_DIR/gpt-latest"
  say "Backed up the partition table and /etc/fstab to $BACKUP_DIR"

  local new_start=$(( (swap_end + 1 - NEW_BOOT_SECTORS) / 2048 * 2048 ))
  say "Repartitioning: swap ends at $((new_start - 1)); new boot partition $new_start-$swap_end"
  swapoff "$swap_part"
  sgdisk -d "$swap_n" \
    -n "$swap_n:$swap_start:$((new_start - 1))" -t "$swap_n:8200" -u "$swap_n:$swap_guid" \
    -n "$((swap_n + 1)):$new_start:$swap_end" -t "$((swap_n + 1)):EF00" -c "$((swap_n + 1)):boot" "$disk" >/dev/null
  partprobe "$disk"; udevadm settle
  local new_boot; new_boot=$(part_path "$disk" "$((swap_n + 1))")
  [[ -b $new_boot ]] || die "$new_boot did not appear; restore with: sgdisk --load-backup=$BACKUP_DIR/gpt-$stamp.bin $disk"

  mkswap -q ${swap_label:+-L "$swap_label"} -U "$swap_uuid" "$swap_part" >/dev/null
  swapon "$swap_part"
  say "Swap recreated with the same UUID ($swap_uuid)"

  mkfs.fat -F32 -n BOOT "$new_boot" >/dev/null
  mkdir -p "$STAGE"; mount "$new_boot" "$STAGE"
  say "Copying /boot to the new FAT32 partition"
  rsync -rt --copy-links --no-perms --no-owner --no-group --exclude=/lost+found --exclude=/efi --exclude=/limine /boot/ "$STAGE/"
  mkdir -p "$STAGE/EFI/BOOT" "$STAGE/limine"
  install -m 644 /usr/share/limine/BOOTX64.EFI "$STAGE/EFI/BOOT/BOOTX64.EFI"

  install_assets
  say "Generating the Limine menu from the kernel entries"
  BOOT="$STAGE" "$SYNC_BIN"
  cat "$STAGE/limine/limine.conf"
  umount "$STAGE"

  local new_uuid old_uuid; new_uuid=$(blkid -s UUID -o value "$new_boot"); old_uuid=$(blkid -s UUID -o value "$old_boot")
  say "Updating /etc/fstab (old /boot stays available as /boot.old)"
  mkdir -p /boot.old
  python3 - "$old_uuid" "$new_uuid" <<'PY'
import re, sys
old, new = sys.argv[1], sys.argv[2]
out, done = [], False
for line in open('/etc/fstab'):
    f = line.split()
    if not done and len(f) >= 3 and not line.lstrip().startswith('#') and f[1] == '/boot':
        out.append(f"UUID={new} /boot vfat umask=0077,shortname=winnt 0 2\n")
        out.append(f"UUID={old} /boot.old {f[2]} noauto,nofail 0 0\n")
        done = True
    else:
        out.append(line)
if not done:
    sys.exit("no /boot line found in /etc/fstab")
open('/etc/fstab', 'w').write(''.join(out))
PY
  install -Dm755 "$HERE/95-limine.install" "$PLUGIN"
  systemctl daemon-reload
  say "Phase 1 done. Next:"
  say "  1. reboot (still in BIOS mode) and check Nobara boots; /boot is now FAT32"
  say "  2. in the firmware: enable UEFI boot, disable Secure Boot, boot the disk -> Limine's menu"
  say "  3. after that boots Nobara: sudo $0 finish"
  say "Undo before step 2: sudo $0 rollback (and reboot)"
}

cmd_rollback() {
  [[ -L $BACKUP_DIR/fstab-latest ]] || die "no backup in $BACKUP_DIR"
  cp -a "$(readlink -f "$BACKUP_DIR/fstab-latest")" /etc/fstab
  rm -f "$PLUGIN"
  say "Restored /etc/fstab: /boot is the old ext4 partition again after a reboot. The new FAT partition is left unused."
  say "Kernels installed since phase 1 exist only on the FAT /boot; regenerate GRUB after reboot: sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
}

cmd_finish() {
  need efibootmgr lsblk findmnt
  [[ -d /sys/firmware/efi ]] || die "not booted in UEFI mode - boot via Limine first"
  [[ $(findmnt -no FSTYPE /boot) == vfat ]] || die "/boot is not the new FAT32 partition"
  [[ -f /boot/EFI/BOOT/BOOTX64.EFI && -f /boot/limine/limine.conf ]] || die "Limine files missing from /boot"
  local src disk
  src=$(findmnt -no SOURCE /boot); disk=$(disk_of "$src")
  say "Registering a UEFI boot entry for Limine on $disk partition $(partnum_of "$src")"
  if efibootmgr | grep -q "Limine (Nobara)"; then
    say "A 'Limine (Nobara)' boot entry already exists"
  else
    efibootmgr -c -d "$disk" -p "$(partnum_of "$src")" -L "Limine (Nobara)" -l '\EFI\BOOT\BOOTX64.EFI' | grep -i limine || true
  fi
  install_assets
  install -Dm755 "$HERE/95-limine.install" "$PLUGIN"
  say "Making kernel-install ignore GRUB (Limine's hook keeps the menu current)"
  install -d /etc/kernel/install.d
  for p in 20-grub.install 99-grub-mkconfig.install; do
    [[ -e /usr/lib/kernel/install.d/$p ]] && ln -sf /dev/null "/etc/kernel/install.d/$p"
  done
  "$SYNC_BIN"
  say "GRUB is now unused. Its packages are still installed (dnf protects them). To remove them: sudo $0 purge-grub"
  say "The old ext4 /boot (mount it with: mount /boot.old) can be wiped and reused once you are happy."
}

cmd_purge_grub() {
  [[ -d /sys/firmware/efi ]] || die "boot via UEFI+Limine first"
  [[ $(findmnt -no FSTYPE /boot) == vfat && -f /boot/limine/limine.conf ]] || die "Limine is not set up on /boot"
  efibootmgr | grep -q "Limine (Nobara)" || die "run finish first (no Limine boot entry registered)"
  mapfile -t pk < <(rpm -qa --qf '%{NAME}\n' 'grub2*' 'shim*' | sort -u)
  ((${#pk[@]})) || { say "No GRUB packages installed."; return 0; }
  say "Will remove: ${pk[*]}"
  warn "dnf marks these as protected; the protection files for them are moved to $BACKUP_DIR/protected.d first."
  read -rp "Remove GRUB and shim now? Limine is already booting this machine. [y/N] " a
  [[ $a == [yY]* ]] || { say "Nothing changed."; return 0; }
  mkdir -p "$BACKUP_DIR/protected.d"
  for f in /etc/dnf/protected.d/grub2*.conf /etc/dnf/protected.d/shim*.conf; do
    [[ -e $f ]] && mv "$f" "$BACKUP_DIR/protected.d/"
  done
  if dnf remove -y "${pk[@]}"; then
    say "GRUB removed. /boot.old (the old ext4 /boot) can be wiped and reused."
  else
    warn "dnf failed; restoring the protection files"
    mv "$BACKUP_DIR"/protected.d/*.conf /etc/dnf/protected.d/ 2>/dev/null || true
    exit 1
  fi
}

# What a bootstrap run calls: do whichever phase applies to this machine, never abort the caller.
cmd_auto() {
  local fs; fs=$(findmnt -no FSTYPE /boot 2>/dev/null || true)
  if [[ $fs == ext* ]]; then
    if [[ -d /sys/firmware/efi ]]; then
      warn "Booted via UEFI with an ext4 /boot: this migration only covers BIOS+GRUB machines. Leaving the bootloader alone."
    else
      cmd_prepare
    fi
  elif [[ $fs == vfat && -f /boot/limine/limine.conf ]]; then
    if [[ -d /sys/firmware/efi ]]; then
      cmd_finish
    else
      install_assets && "$SYNC_BIN"
      warn "Phase 1 is done but this boot is still BIOS. Switch the firmware to UEFI (Secure Boot off), boot the disk, then run this again."
    fi
  else
    warn "Unrecognised /boot layout (fs: ${fs:-none}). Leaving the bootloader alone."
  fi
}

case "${1:-}" in
auto) cmd_auto ;;
prepare) cmd_prepare ;;
finish) cmd_finish ;;
rollback) cmd_rollback ;;
purge-grub) cmd_purge_grub ;;
*) die "usage: $0 auto|prepare|finish|purge-grub|rollback" ;;
esac
