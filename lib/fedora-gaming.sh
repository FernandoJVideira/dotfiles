#!/usr/bin/env bash
# Stock Fedora: RPM Fusion, codecs, gaming stack and NVIDIA driver (what Nobara preconfigures).
# Sourced, never executed. Every function returns 0 even when a step fails (callers run under set -e).

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

FEDORA_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../linux/fedora/system" 2>/dev/null && pwd)"

# Install what is missing; warn per package that is still absent afterwards.
_fg_install() {
  local pkg missing=()
  sudo dnf install -y --skip-unavailable "$@" || log "WARNING: dnf install failed for: $*"
  for pkg in "$@"; do
    [[ $pkg == -* ]] && continue
    rpm -q "$pkg" &>/dev/null || missing+=("$pkg")
  done
  ((${#missing[@]} == 0)) || log "WARNING: not installed: ${missing[*]}"
  return 0
}

fedora_repos_setup() {
  local rel
  rel=$(rpm -E %fedora)

  if ! rpm -q rpmfusion-free-release &>/dev/null || ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
    log "Enabling RPM Fusion free + nonfree..."
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${rel}.noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${rel}.noarch.rpm" \
      || log "WARNING: could not install the RPM Fusion release packages."
  fi

  log "Enabling the Cisco OpenH264 repo..."
  sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1 \
    || log "WARNING: could not enable fedora-cisco-openh264."

  if rpm -q ffmpeg-free &>/dev/null; then
    log "Swapping ffmpeg-free for ffmpeg..."
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing \
      || log "WARNING: ffmpeg swap failed."
  fi

  # F44 folds the VA-API/VDPAU drivers into mesa-dri-drivers; RPM Fusion's freeworld package adds the patented codecs
  if ! rpm -q mesa-va-drivers-freeworld &>/dev/null; then
    log "Installing mesa-va-drivers-freeworld..."
    sudo dnf install -y --allowerasing mesa-va-drivers-freeworld \
      || log "WARNING: mesa-va-drivers-freeworld failed - hardware video decode stays limited."
  fi
  return 0
}

fedora_gaming_setup() {
  local answer=${DOTFILES_GAMING:-}
  case $answer in
    yes) ;;
    no) log "Skipping gaming setup (DOTFILES_GAMING=no)."; return 0 ;;
    *)
      if command -v gum >/dev/null && [[ -t 0 ]]; then
        gum confirm "Set up gaming tools (Steam, Heroic, falcond, sysctl tweaks)?" || return 0
      else
        log "Skipping gaming setup (no tty). Re-run with DOTFILES_GAMING=yes to install it."
        return 0
      fi
      ;;
  esac

  log "Installing gaming packages..."
  # falcond conflicts with gamemode: install it first (erasing gamemode) and keep gamemode out afterwards.
  _fg_install --allowerasing heroic-games-launcher falcond falcond-profiles
  _fg_install --disablerepo='terra*' --exclude=gamemode steam steam-devices gamescope mangohud goverlay
  if rpm -q falcond &>/dev/null && rpm -q gamemode &>/dev/null; then
    log "Removing gamemode (conflicts with falcond)..."
    sudo dnf remove -y gamemode || log "WARNING: could not remove gamemode - something requires it: $(rpm -q --whatrequires gamemode 2>&1 | tr '\n' ' ')"
  fi

  if [[ -d ${FEDORA_SYSTEM_DIR:-}/sysctl.d ]]; then
    log "Installing gaming sysctl drop-ins..."
    local f
    for f in "$FEDORA_SYSTEM_DIR"/sysctl.d/*.conf; do
      [[ -e $f ]] || continue
      sudo install -m 0644 "$f" "/etc/sysctl.d/$(basename "$f")" \
        || log "WARNING: could not install $f."
    done
    sudo sysctl --system >/dev/null || log "WARNING: sysctl --system failed."
  else
    log "WARNING: no sysctl.d directory under FEDORA_SYSTEM_DIR - sysctl tweaks skipped."
  fi

  if rpm -q falcond &>/dev/null; then
    sudo systemctl enable --now falcond.service || log "WARNING: could not enable falcond.service."
    if getent group falcond >/dev/null; then
      sudo usermod -aG falcond "$USER" || log "WARNING: could not add $USER to the falcond group."
    fi
  fi
  return 0
}

fedora_nvidia_setup() {
  lspci 2>/dev/null | grep -E 'VGA|3D|Display' | grep -qi nvidia || return 0

  log "NVIDIA GPU found - installing the driver..."
  _fg_install akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver

  if [[ ! -f /etc/pki/akmods/certs/public_key.der ]]; then
    log "Generating the akmods signing key..."
    sudo kmodgenca -a || log "WARNING: kmodgenca failed - the NVIDIA module cannot be signed."
  fi

  log "Building the NVIDIA kernel module (this takes a few minutes)..."
  sudo akmods --force || log "WARNING: akmods build failed - check /var/cache/akmods."

  log "WARNING: with Secure Boot the key /etc/pki/akmods/certs/public_key.der must be enrolled (mokutil) or the module will not load; fedora_eac_setup does this."

  # Fedora's nvidia-kmod-common sets modeset=1 through modprobe; only add it when absent.
  if ! grep -rqs 'nvidia-drm.*modeset=1' /etc/modprobe.d /usr/lib/modprobe.d; then
    log "Setting nvidia-drm modeset=1..."
    echo 'options nvidia-drm modeset=1' | sudo tee /etc/modprobe.d/nvidia-modeset.conf >/dev/null \
      || log "WARNING: could not write nvidia-modeset.conf."
  fi
  return 0
}
