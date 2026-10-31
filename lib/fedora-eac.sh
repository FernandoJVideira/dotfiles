#!/usr/bin/env bash
# Fedora: Easy Anti-Cheat (EAC Linux v2) boot entries, adapted from Nobara's nobara-eac.
# Sourced, never executed.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

FEDORA_EAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../linux/fedora/system/eac" 2>/dev/null && pwd)"

fedora_eac_setup() {
  if [[ ! -d /sys/firmware/efi ]]; then
    log "Not booted with UEFI, skipping the Easy Anti-Cheat boot entries"
    return 0
  fi

  if ! command -v mokutil &>/dev/null; then
    log "Installing mokutil..."
    sudo dnf install -y mokutil || { log "WARNING: could not install mokutil, skipping EAC setup"; return 0; }
  fi

  log "Installing the Easy Anti-Cheat boot entry hook..."
  if ! {
    sudo install -D -m 0755 "$FEDORA_EAC_DIR/95-eac.install" /etc/kernel/install.d/95-eac.install &&
    sudo install -D -m 0755 "$FEDORA_EAC_DIR/eac-enroll" /usr/local/bin/eac-enroll &&
    sudo install -D -m 0644 "$FEDORA_EAC_DIR/eac.service" /etc/systemd/system/eac.service &&
    { sudo test -e /etc/sysconfig/eac || sudo install -D -m 0644 "$FEDORA_EAC_DIR/eac.sysconfig" /etc/sysconfig/eac; } &&
    sudo systemctl daemon-reload &&
    sudo systemctl enable eac.service
  }; then
    log "WARNING: could not install the Easy Anti-Cheat files"
    return 0
  fi

  sudo /etc/kernel/install.d/95-eac.install apply-all || log "WARNING: could not write the EAC boot entries"

  if /usr/local/bin/eac-enroll --check; then
    log "Easy Anti-Cheat keys already enrolled"
  elif [[ -t 0 ]]; then
    sudo /usr/local/bin/eac-enroll || log "WARNING: key enrolment failed, retry with: sudo eac-enroll"
  else
    log "Enroll the DKMS and akmods keys for Easy Anti-Cheat: sudo eac-enroll"
  fi
  log "Enable Secure Boot in the firmware for the Easy Anti-Cheat entry to be the default"
  return 0
}
