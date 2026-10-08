#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"

# gum (the prompts below) is not on a minimal install yet
sudo pacman -S --needed --noconfirm gum

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

# Omadora (my fork, arch branch) provides the Hyprland session, the Quickshell
# shell, SDDM and their packages. It goes in before the dotfiles are symlinked so
# my own configs win over its defaults. HTTPS, since a fresh machine has no SSH
# key yet. A first install runs its installer (which ends by rebooting, so run
# this script again afterwards); an existing checkout is only fast-forwarded
# (update it afterwards with `omactl update`).
OMADORA_DIR="$HOME/.local/share/omadora"
OMADORA_REPO_URL="${OMADORA_REPO_URL:-https://github.com/FernandoJVideira/omadora.git}"
OMADORA_REF="${OMADORA_REF:-arch}"
sudo pacman -S --needed --noconfirm git base-devel
if [[ -d "$OMADORA_DIR/.git" ]]; then
  log "Updating Omadora..."
  git -C "$OMADORA_DIR" pull --ff-only \
    || log "WARNING: couldn't fast-forward Omadora - resolve it in $OMADORA_DIR by hand."
else
  log "Cloning Omadora ($OMADORA_REF)..."
  mkdir -p "$(dirname "$OMADORA_DIR")"
  git clone --branch "$OMADORA_REF" "$OMADORA_REPO_URL" "$OMADORA_DIR"
  log "Running the Omadora installer..."
  # Its last step reboots; tolerate that failing (e.g. over SSH) so this script can finish.
  bash "$OMADORA_DIR/install.sh" || log "WARNING: the Omadora installer ended with an error - check ~/omadora-install.log."
fi
export OMADORA_PATH="$OMADORA_DIR"
export PATH="$OMADORA_DIR/bin:$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

log "Symlinking Linux-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

# Install workstation tools
log "Installing workstation tools..."
sudo pacman -S --needed --noconfirm go element-desktop ghostty kitty github-cli zed
# Tools the shared zsh config assumes
sudo pacman -S --needed --noconfirm fzf zoxide fd bat eza starship fastfetch
yay -S --needed --noconfirm brave-origin-bin proton-pass-cli opendeck spotify

# Re-apply the current theme so kitty's themed colors file exists (Omadora defaults to
# its own theme on a machine that's never had one set).
log "Re-applying the current theme..."
omactl theme set "$(cat "$HOME/.config/omadora/current/theme.name" 2>/dev/null || echo matte-black)" \
  || log "WARNING: theme re-apply failed - run: omactl theme set <name> from the desktop."

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
  log "Reloading Hyprland..."
  hyprctl reload
fi

log "Enabling Proton Pass SSH agent..."
systemctl --user enable --now proton-pass-agent.service

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../../common/install.sh"

# Themed starship prompt: needs the shared symlinks (script + template) from above
log "Rendering the starship prompt for the current theme..."
"$HOME/.local/bin/starship-theme-sync" || log "WARNING: starship-theme-sync failed - the prompt keeps its static colors."
