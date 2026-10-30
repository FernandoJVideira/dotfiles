#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/symlink.sh"
source "$SCRIPT_DIR/../lib/skein.sh"
source "$SCRIPT_DIR/../lib/secrets.sh"

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

# Initialize Hyprspace (creates a default config if one doesn't exist yet).
# Runs before symlink_dotfiles so our own hyprspace/config.toml correctly
# overwrites whatever this creates, same ordering reason as
# omarchy-reinstall-configs on the Linux side.
log "Initializing Hyprspace..."
hyprspace init

# Create symlinks for dotfiles
log "Symlinking macOS-specific dotfiles..."
# a machine that still has Omadora's config, state and cache directories: move them to Skein's names
# before the dotfiles are linked into them
migrate_skein_dirs

symlink_dotfiles "$SCRIPT_DIR"

# The agent serves the SSH keys from a Proton Pass login. With a personal access token in the login
# Keychain the login needs nobody at the keyboard; without one, fall back to the web login (needs a
# terminal). pass-cli keeps the session it creates; the token is only used when there is none.
if command -v pass-cli &>/dev/null && ! pass-cli info &>/dev/null; then
  if pat_ready; then
    log "Logging in to Proton Pass with the token from the Keychain..."
    pass-cli login --pat "$(pat_load)" >/dev/null || log "WARNING: the Proton Pass token login failed (revoked or expired?) - run: pass-cli login"
  elif { : </dev/tty; } 2>/dev/null; then
    log "Logging in to Proton Pass (the SSH agent needs it)..."
    pass-cli login </dev/tty || log "WARNING: Proton Pass login failed - run: pass-cli login, then: launchctl kickstart -k gui/$(id -u)/com.proton.pass.agent"
  else
    log "WARNING: not logged in to Proton Pass and no terminal to ask on - run: pass-cli login"
  fi
fi

# Activate Proton Pass agent if not already running
if ! launchctl print gui/"$(id -u)"/com.proton.pass.agent &>/dev/null; then
  log "Starting Proton Pass SSH agent..."
  launchctl bootstrap gui/"$(id -u)" "$HOME/Library/LaunchAgents/com.proton.pass.agent.plist"
fi

# The second agent serves the "Deploy" vault (the vue-ui-kit deploy key) on its own socket
if ! launchctl print gui/"$(id -u)"/com.proton.pass.deploy-agent &>/dev/null; then
  log "Starting Proton Pass SSH agent for the Deploy vault..."
  launchctl bootstrap gui/"$(id -u)" "$HOME/Library/LaunchAgents/com.proton.pass.deploy-agent.plist" \
    || log "WARNING: couldn't start the Deploy-vault agent - run: launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.proton.pass.deploy-agent.plist"
fi

# GUI apps inherit launchd's environment, not zsh's, so SSH_AUTH_SOCK is set there too
if ! launchctl print gui/"$(id -u)"/com.proton.pass.agent-env &>/dev/null; then
  log "Exporting SSH_AUTH_SOCK to the login session..."
  launchctl bootstrap gui/"$(id -u)" "$HOME/Library/LaunchAgents/com.proton.pass.agent-env.plist" \
    || log "WARNING: couldn't export SSH_AUTH_SOCK to the session - run: launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.proton.pass.agent-env.plist"
fi

if [[ "$(sysctl -n hw.model)" == MacBook* ]]; then
  log "Laptop detected — installing AlDente..."
  brew install --cask aldente
fi

log "Applying macOS defaults..."
"$SCRIPT_DIR/macos-defaults.sh"

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../common/install.sh"

# Default theme, the first time only: a rerun must not undo a theme picked since.
# After common/install.sh, which provides the starship and Zed sync scripts the
# theme hooks call. Also fetches the Skein themes (see macos/.local/bin/theme).
if [[ -z "$("$HOME/.local/bin/theme" current 2>/dev/null)" ]]; then
  log "Applying the default theme (gruvbox-classic)..."
  "$HOME/.local/bin/theme" set gruvbox-classic || log "WARNING: couldn't apply the default theme - run: theme"
fi

log "macOS setup complete."
