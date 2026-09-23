#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"

# illogical-impulse (end-4/dots-hyprland) is the Hyprland+Quickshell base end4-pC
# builds on top of - its own installer already knows how to detect Fedora-family
# distros (Nobara includes) and install everything it needs via dnf, so we lean
# on it instead of hand-rolling a package list here.
ILLOGICAL_IMPULSE_DIR="$HOME/.local/share/illogical-impulse"
ILLOGICAL_IMPULSE_REPO="https://github.com/end-4/dots-hyprland.git"

# Our fork, for the Claude Code AI backend and any other customizations.
END4_PC_REPO="https://github.com/FernandoJVideira/end4-pC.git"
END4_PC_DIR="$HOME/.config/quickshell/end4-pC"

# Install zsh and set it as the default shell (mirrors linux/arch/install.sh)
log "Installing zsh..."
sudo dnf install -y zsh
sudo chsh -s "$(which zsh)" "$USER"

log "Installing git (needed to fetch illogical-impulse and end4-pC)..."
sudo dnf install -y git

if [[ -d "$ILLOGICAL_IMPULSE_DIR/.git" ]]; then
  log "Updating illogical-impulse..."
  git -C "$ILLOGICAL_IMPULSE_DIR" pull
else
  log "Cloning illogical-impulse..."
  git clone "$ILLOGICAL_IMPULSE_REPO" "$ILLOGICAL_IMPULSE_DIR"
fi

log "Running illogical-impulse's installer (installs Hyprland, Quickshell, and every other dependency end4-pC needs)..."
"$ILLOGICAL_IMPULSE_DIR/setup" install

log "Symlinking Nobara-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

mkdir -p "$(dirname "$END4_PC_DIR")"
if [[ -d "$END4_PC_DIR/.git" ]]; then
  log "Updating end4-pC..."
  git -C "$END4_PC_DIR" pull
else
  log "Cloning end4-pC..."
  git clone "$END4_PC_REPO" "$END4_PC_DIR"
fi

VARIABLES_LUA="$HOME/.config/hypr/hyprland/variables.lua"
if [[ -f "$VARIABLES_LUA" ]] && grep -q 'hl\.env("qsConfig", "ii")' "$VARIABLES_LUA"; then
  log "Setting end4-pC as the default Quickshell config..."
  sed -i 's/hl\.env("qsConfig", "ii")/hl.env("qsConfig", "end4-pC")/' "$VARIABLES_LUA"
fi

log "(Re)starting Quickshell with end4-pC..."
killall qs 2>/dev/null || true
qs -c end4-pC > /dev/null 2>&1 & disown

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../../common/install.sh"
