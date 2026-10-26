#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/symlink.sh"
source "$SCRIPT_DIR/../lib/miniconda.sh"
source "$SCRIPT_DIR/../lib/spicetify.sh"
source "$SCRIPT_DIR/../lib/herdr.sh"
source "$SCRIPT_DIR/../lib/draft.sh"
source "$SCRIPT_DIR/../lib/mise.sh"

log "Symlinking shared dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

# Dev tools (Go, Node, Java, .NET, Neovim, tmux, Herdr, Claude Code...) from the mise list just
# linked above. Before the Herdr plugin step below, which needs herdr on the PATH. Non-fatal.
install_mise_tools || log "WARNING: the mise dev tools weren't all installed (see above) - rerun ./bootstrap.sh to retry."

if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
  log "Installing tmux plugin manager (TPM)..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

log "Installing tmux plugins..."
"$HOME/.config/tmux/plugins/tpm/scripts/install_plugins.sh"

# Same prefix and installer on every OS, so the config in .zshenv is universal.
# Non-fatal: a flaky download shouldn't fail the rest of the dotfiles.
install_miniconda || log "WARNING: Miniconda wasn't installed (see above) - rerun ./bootstrap.sh to retry."

# Same for Spicetify (Spotify theming): one installer for every OS. Non-fatal too. The
# colors are applied by the theme-set hook (spicetify-sync), once Spotify has been started.
install_spicetify || log "WARNING: Spicetify wasn't installed (see above) - rerun ./bootstrap.sh to retry."

# Herdr's Ctrl+h/j/k/l navigation plugin; after the symlinks above, since config.toml (with its
# bindings) is one of them, and non-fatal like the rest.
install_herdr_plugins || log "WARNING: the Herdr navigation plugin wasn't installed (see above) - rerun ./bootstrap.sh to retry."

# My draft scaffolding CLI, latest release; also non-fatal. Rerunning updates it.
install_draft || log "WARNING: draft wasn't installed (see above) - rerun ./bootstrap.sh to retry."

log "common/install.sh complete."
