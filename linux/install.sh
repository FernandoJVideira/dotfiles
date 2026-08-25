#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/symlink.sh"
source "$SCRIPT_DIR/../lib/log.sh"

if ! grep -q '^\[omarchy\]' /etc/pacman.conf; then
  log "Adding the omarchy edge repo..."
  sudo tee -a /etc/pacman.conf <<'EOF'

[omarchy]
SigLevel = Optional TrustAll
Server = https://pkgs.omarchy.org/stable/$arch
EOF
fi

log "Installing omarchy packages..."
sudo pacman -S --noconfirm omarchy-keyring omarchy omarchy-settings

log "Preserving CachyOS's custom repos..."
awk '
  /^\[core\]/ { exit }
  /^\[options\]/ { skip=1; next }
  /^\[/ { skip=0 }
  !skip && !/^[[:space:]]*#/ && !/^[[:space:]]*$/ { print }
' /etc/pacman.conf | sudo tee /etc/pacman.d/custom-repos.conf > /dev/null

log "Activating the custom-repo preservation hook..."
mkdir -p ~/.config/omarchy/hooks/pre-refresh-pacman.d
cp /usr/share/omarchy/config/omarchy/hooks/pre-refresh-pacman.d/add-custom-repo.sample \
   ~/.config/omarchy/hooks/pre-refresh-pacman.d/add-custom-repo

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

# Install Omarchy base packages
log "Installing Omarchy base packages..."
mapfile -t base_packages < <(grep -v '^#' /usr/share/omarchy/install/omarchy-base.packages)
sudo pacman -S --needed --noconfirm "${base_packages[@]}"

# Set up Omarchy system and user
log "Applying Omarchy system setup..."
sudo omarchy-apply-system --install-user "$USER" --first-install

log "Finalizing Omarchy user setup..."
omarchy-provision-user --force --first-install

# Seed Omarchy's shipped configs (Hyprland, Quickshell, etc.) into $HOME.
# Needed because our user was created by the CachyOS installer, before
# Omarchy was ever installed - /etc/skel seeding only happens at useradd
# time, so it never ran with Omarchy's content. Must run before
# symlink_dotfiles, since it force-copies over $HOME and would blow away
# our own symlinks if it ran after.
log "Seeding Omarchy's shipped configs..."
omarchy-reinstall-configs

# Prune unnecessary preinstalled apps (like Kdenlive and LibreOffice) to save space
log "Removing unused preinstalled apps..."
omarchy-pkg-drop kdenlive libreoffice-fresh

selected_webapps=$(gum choose --no-limit \
  "Basecamp" "Google Contacts" "Google Maps" "Google Messages" \
  "Google Photos" "WhatsApp" "X" "YouTube")

while IFS= read -r webapp; do
  [[ -n "$webapp" ]] && omarchy-webapp-remove "$webapp"
done <<< "$selected_webapps"

# Install workstation tools
log "Installing workstation tools..."
sudo pacman -S --needed --noconfirm go element-desktop ghostty
omarchy-install-editor-zed
yay -S --noconfirm brave-origin-bin

# Set Brave Origin as the default browser
log "Setting Brave Origin as the default browser..."
xdg-settings set default-web-browser brave-origin.desktop

if gum confirm "Replace Discord webapp with the native app (better screen-share)?"; then
  log "Installing native Discord..."
  yay -S --noconfirm discord
  omarchy-webapp-remove "Discord"
fi

if ! gum confirm "Keep OBS installed?" --default; then
  log "Removing OBS..."
  omarchy-pkg-drop obs-studio
fi

if [[ "$GAMING" == true ]]; then
  log "Installing gaming tools..."
  omarchy-install-gaming-steam
  omarchy-install-gaming-lutris
  sudo pacman -S --needed --noconfirm mangohud lib32-mangohud
  yay -S --noconfirm hydra-launcher-bin
fi

log "Symlinking Linux-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

log "Enabling Proton Pass SSH agent..."
systemctl --user enable --now proton-pass-agent.service

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../common/install.sh"
