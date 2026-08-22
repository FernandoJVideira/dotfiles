#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/symlink.sh"

log "Symlinking shared dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
  log "Installing tmux plugin manager (TPM)..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

log "Installing tmux plugins..."
"$HOME/.config/tmux/plugins/tpm/scripts/install_plugins.sh"

log "common/install.sh complete."
