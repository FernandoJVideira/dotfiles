#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# Finder
# =========================================================

defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# =========================================================
# Dock
# =========================================================

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock show-recents -bool false

# =========================================================
# Trackpad
# =========================================================

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# =========================================================
# Appearance
# =========================================================

defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# =========================================================
# Apply changes (most defaults changes need the owning app restarted)
# =========================================================

killall Finder Dock >/dev/null 2>&1 || true
