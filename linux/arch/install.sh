#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"
source "$SCRIPT_DIR/../../lib/omarshell.sh"

# Check if the user wants to set up gaming tools
if gum confirm "Set up gaming tools too?"; then
  GAMING=true
else
  GAMING=false
fi

# Install zsh and set it as the default shell
log "Installing zsh..."
sudo pacman -S --needed --noconfirm zsh
sudo chsh -s "$(which zsh)" "$USER"

# Hyprland + the runtime deps omarshell's quickshell UI and bar scripts need.
# None of this touches pacman.conf - omarshell doesn't rewrite it like the
# omarchy package does, so there's nothing to preserve across it.
log "Installing Hyprland and omarshell's runtime dependencies..."
sudo pacman -S --needed --noconfirm \
  hyprland quickshell uwsm sddm xdg-desktop-portal-hyprland \
  wireplumber pipewire gnome-keyring jq gum wl-clipboard slurp hyprpicker \
  wtype brightnessctl bluez-utils networkmanager qrencode libnotify \
  ttf-jetbrains-mono-nerd pacman-contrib

install_omarshell_repo
setup_omarshell_session_env

log "Symlinking Linux-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

seed_hypr_personal_overrides

# Install workstation tools
log "Installing workstation tools..."
sudo pacman -S --needed --noconfirm go element-desktop ghostty kitty github-cli zed
# Tools the shared zsh config assumes
sudo pacman -S --needed --noconfirm fzf zoxide fd bat eza starship fastfetch
yay -S --needed --noconfirm brave-origin-bin proton-pass-cli opendeck spotify

# Re-apply the current theme now that omarshell's theme catalog is in place
# (generates kitty's themed colors file, among others). Defaults to
# matte-black on a machine that's never had a theme set before.
log "Re-applying the current theme..."
mkdir -p "$HOME/.local/state/omarchy/current"
CURRENT_THEME_FILE="$HOME/.local/state/omarchy/current/theme.name"
[[ -f "$CURRENT_THEME_FILE" ]] || echo "matte-black" >"$CURRENT_THEME_FILE"
omarchy-theme-set "$(cat "$CURRENT_THEME_FILE")"

# Set Brave Origin as the default browser
log "Setting Brave Origin as the default browser..."
xdg-settings set default-web-browser brave-origin.desktop

if gum confirm "Install Discord (native app)?"; then
  log "Installing Discord..."
  yay -S --needed --noconfirm discord
fi

if gum confirm "Install OBS Studio?"; then
  log "Installing OBS Studio..."
  sudo pacman -S --needed --noconfirm obs-studio
fi

if [[ "$GAMING" == true ]]; then
  log "Installing gaming tools..."
  # multilib ships commented out on a stock Arch pacman.conf; Steam needs it.
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
  fi
  sudo pacman -S --needed --noconfirm steam lutris mangohud lib32-mangohud
  # Lutris ships with `#!/usr/bin/env python3`, which resolves to mise's Python
  # and fails to import the lutris module. Pin the shebang to system Python.
  sudo sed -i '/env python3/ c\#!/bin/python3' /usr/bin/lutris
  yay -S --needed --noconfirm hydra-launcher-bin
fi

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  log "Reloading Hyprland and restarting the shell..."
  hyprctl reload
  omarchy-restart-shell || log "WARNING: shell restart failed - check 'journalctl --user -t omarchy-shell'."
fi

log "Configuring monitors..."
"$SCRIPT_DIR/configure-monitors.sh"

log "Enabling Proton Pass SSH agent..."
systemctl --user enable --now proton-pass-agent.service

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../../common/install.sh"
