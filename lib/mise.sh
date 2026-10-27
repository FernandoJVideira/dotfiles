#!/usr/bin/env bash
# Installs every dev tool listed in common/.config/mise/conf.d/dotfiles.toml with mise, the same
# way on every OS: Go, Node, pnpm, Java, .NET, Neovim, gh, just, cloudflared, golang-migrate, Herdr
# and Claude Code. Package managers keep the rest: GUI apps, shell utilities, hugo (mise's build
# lacks the extended SCSS support) and tmux (mise's build lags Homebrew's; only Nobara,
# where Fedora's is stale, adds it, in linux/nobara/.config/mise/conf.d).
#
# The list lives in conf.d so it merges with a machine's own ~/.config/mise/config.toml (what
# `mise use --global` writes, or Omarchy's) instead of replacing it. Versions are "latest", so
# `mise install` only fills in what is missing; `mise upgrade` moves a machine forward.
#
# mise itself comes from the Brewfile (macOS) and mise.run (Nobara). Run after
# symlink_dotfiles, since that is what puts the list in place.
#
# Nothing here needs sudo. mise prints optional macOS Java integration commands (symlinks into
# /Library/Java/JavaVirtualMachines, so /usr/libexec/java_home finds its JDKs); they are skipped.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

install_mise_tools() {
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
  if ! command -v mise >/dev/null 2>&1; then
    log "WARNING: mise isn't installed - skipping the dev tools."
    return 1
  fi

  log "Installing dev tools with mise..."
  mise install || {
    log "WARNING: some mise tools failed to install - run 'mise install' to see which."
    return 1
  }
}
