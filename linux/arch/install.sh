#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"
source "$SCRIPT_DIR/../../lib/monitors.sh"
source "$SCRIPT_DIR/../../lib/limine.sh"
source "$SCRIPT_DIR/../../lib/secrets.sh"

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
sudo chsh -s "$(command -v zsh)" "$USER"

# Omadora (my fork, arch branch) provides the Hyprland session, the Quickshell
# shell, SDDM and their packages. It goes in before the dotfiles are symlinked so
# my own configs win over its defaults. HTTPS, since a fresh machine has no SSH
# key yet. A first install runs its installer (which ends by rebooting, so run
# this script again afterwards); an existing checkout is only fast-forwarded
# (update it afterwards with `omactl update`).
OMADORA_DIR="$HOME/.local/share/omadora"
OMADORA_REPO_URL="${OMADORA_REPO_URL:-https://github.com/FernandoJVideira/omadora.git}"
OMADORA_REF="${OMADORA_REF:-arch}"
# python-filelock: pipx (used by the Omadora installer) imports it but the package does not depend on it
sudo pacman -S --needed --noconfirm git base-devel python-filelock
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
# what both Linux distros share (Caps Lock as Super, see linux/common/.config/hypr/capslock.lua)
symlink_dotfiles "$SCRIPT_DIR/../common"

# Monitor layout: the fastest monitor becomes the primary at 0x0, the rest chain
# to its right. Written into the (symlinked) monitors.lua; needs a running
# Hyprland to read the mode lists, so on a first install from a TTY it is
# skipped - re-run this script from the desktop.
log "Detecting monitors..."
sync_hypr_monitors "$SCRIPT_DIR/.config/hypr/monitors.lua" "$(detect_monitors || true)" || true

# The SDDM greeter runs on X11 and ignores monitors.lua, so give it an Xsetup
# script that lays the screens out the same way (works at login time, no
# detection needed here).
log "Matching the SDDM login screen to the monitor layout..."
sudo install -D -m 755 "$SCRIPT_DIR/../../lib/sddm-monitors.xsetup" /usr/local/bin/omadora-sddm-monitors
sudo install -d /etc/sddm.conf.d
printf '[X11]\nDisplayCommand=/usr/local/bin/omadora-sddm-monitors\n' \
  | sudo tee /etc/sddm.conf.d/omadora-monitors.conf >/dev/null

# Install workstation tools
log "Installing workstation tools..."
sudo pacman -S --needed --noconfirm element-desktop ghostty kitty zed mpv
# Zed's terminal font (common/.config/zed/settings.json)
sudo pacman -S --needed --noconfirm ttf-hack-nerd
# Tools the shared zsh config assumes
sudo pacman -S --needed --noconfirm fzf zoxide fd bat eza starship fastfetch jq

limine_setup

yay -S --needed --noconfirm brave-origin-bin proton-pass-cli opendeck spotify
# Spicetify patches Spotify in place, and the AUR package installs it root-owned in /opt/spotify
if [[ -d /opt/spotify ]]; then
  sudo chmod a+wr /opt/spotify
  sudo chmod -R a+wr /opt/spotify/Apps
fi
# ani-cli (plays with mpv, installed above) and OnlyOffice, each a call of its own so a wrong AUR
# name can't take the rest down.
yay -S --needed --noconfirm ani-cli \
  || log "WARNING: ani-cli failed to install - check the AUR name."
yay -S --needed --noconfirm onlyoffice-bin \
  || log "WARNING: onlyoffice-bin failed to install - check the AUR name."
# Cloudflare WARP (the AUR package carries Cloudflare's own build). Registering, which asks you to
# accept Cloudflare's terms, is left to you: warp-cli registration new, then warp-cli connect.
yay -S --needed --noconfirm cloudflare-warp-bin \
  || log "WARNING: cloudflare-warp-bin failed to install - check the AUR name."
if pacman -Qq cloudflare-warp-bin &>/dev/null; then
  sudo systemctl enable --now warp-svc.service \
    || log "WARNING: couldn't start warp-svc - check: journalctl -u warp-svc"
fi
# LocalSend and GPU Screen Recorder (Flatpaks on Nobara); a separate call so a
# wrong package name can't take the list above down with it.
yay -S --needed --noconfirm localsend-bin gpu-screen-recorder \
  || log "WARNING: localsend-bin / gpu-screen-recorder failed to install - check the AUR names."

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

# The unit logs in with a personal access token from ~/.config/proton-pass-cli/pat. This script
# creates the file with a placeholder (an existing one is left alone), enables the unit always and
# only starts it once the placeholder has been replaced; the instructions are printed at the end.
log "Enabling Proton Pass SSH agent..."
mkdir -p -m 700 "$HOME/.ssh"
create_secret_templates
systemctl --user enable proton-pass-agent.service
if secret_ready "$PROTON_PAT"; then
  systemctl --user restart proton-pass-agent.service || log "WARNING: proton-pass-agent failed to start - check: journalctl --user -u proton-pass-agent"
else
  log "Proton Pass agent enabled but NOT started: add your personal access token to ~/.config/proton-pass-cli/pat (instructions at the end)."
fi

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../../common/install.sh"

# Omadora preferences (same as Nobara): Claude as the default agent and the idle
# screensaver off. Both are plain state files; omadora-default-agent would also
# launch the agent, and `omactl toggle screensaver` flips instead of setting.
log "Applying Omadora preferences..."
mkdir -p "$HOME/.config/omadora/defaults" "$HOME/.local/state/omadora/toggles"
echo claude >"$HOME/.config/omadora/defaults/agent"
touch "$HOME/.local/state/omadora/toggles/screensaver-off"

# Re-apply the current theme so kitty's themed colors file exists (Omadora defaults to
# its own theme on a machine that's never had one set).
log "Re-applying the current theme..."
theme="$(cat "$HOME/.config/omadora/current/theme.name" 2>/dev/null || echo matte-black)"
# First run only: start from matte-black instead of Omadora's own default theme; later
# runs keep whatever theme was picked since.
theme_marker="$HOME/.local/state/dotfiles/theme-initialised"
if [[ ! -f "$theme_marker" ]]; then
  theme=matte-black
  mkdir -p "$(dirname "$theme_marker")" && touch "$theme_marker"
fi
omactl theme set "$theme" \
  || log "WARNING: theme re-apply failed - run: omactl theme set <name> from the desktop."

# Themed starship prompt: needs the shared symlinks (script + template) from above
log "Rendering the starship prompt for the current theme..."
"$HOME/.local/bin/starship-theme-sync" || log "WARNING: starship-theme-sync failed - the prompt keeps its static colors."

# Zed's theme follows the OS theme too (same shared-symlinks dependency)
log "Rendering the Zed theme for the current theme..."
"$HOME/.local/bin/zed-theme-sync" || log "WARNING: zed-theme-sync failed - Zed has no 'Desktop Theme' until the next theme change."
log "Zed installs its extensions (settings.json) the first time it starts - run zed-extensions-check afterwards to confirm."
