#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/symlink.sh"
source "$SCRIPT_DIR/../lib/miniconda.sh"

log "Symlinking shared dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
  log "Installing tmux plugin manager (TPM)..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

log "Installing tmux plugins..."
"$HOME/.config/tmux/plugins/tpm/scripts/install_plugins.sh"

# Same prefix and installer on every OS, so the config in .zshenv is universal.
# Non-fatal: a flaky download shouldn't fail the rest of the dotfiles.
install_miniconda || log "WARNING: Miniconda wasn't installed (see above) - rerun ./bootstrap.sh to retry."

log "common/install.sh complete."
