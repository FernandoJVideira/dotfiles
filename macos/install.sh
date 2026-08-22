#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/symlink.sh"

# Check if Xcode Command Line Tools are installed, and install them if not
if ! xcode-select -p &>/dev/null; then
  log "Installing Xcode Command Line Tools..."
  xcode-select --install
fi

# Wait for Xcode Command Line Tools installation to complete
until xcode-select -p &>/dev/null; do
  sleep 5
done

# Install Homebrew if not already installed

if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add Felix Kratz's tap for Sketchybar
log "Adding felixkratz/formulae tap..."
brew tap felixkratz/formulae

# Install dependencies from Brewfile
log "Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

# Create symlinks for dotfiles
log "Symlinking macOS-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

# Activate Proton Pass agent if not already running
if ! launchctl print gui/$(id -u)/com.proton.pass.agent &>/dev/null; then
  log "Starting Proton Pass SSH agent..."
  launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/com.proton.pass.agent.plist"
fi

if [[ "$(sysctl -n hw.model)" == MacBook* ]]; then
  log "Laptop detected — installing AlDente..."
  brew install --cask aldente
fi

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../common/install.sh"

log "macOS setup complete."
