#!/usr/bin/env bash
# Herdr (terminal multiplexer for coding agents) + Neovim: installs the herdr-nvim-nav plugin,
# which makes Ctrl+h/j/k/l move across Neovim splits and Herdr panes as one set of windows (so
# you can go from Neovim straight down into the Claude pane `hdev` opens). The keys are bound in
# common/.config/herdr/config.toml, the Neovim half is common/.config/nvim/lua/plugins/herdr.lua.
#
# Herdr itself comes from the Brewfile (macOS) or mise (Linux installers).
#
# The plugin is third-party code that gets compiled (one `cc` command) and then run by Herdr on
# every Ctrl+h/j/k/l, so it is pinned to the commit that was read in full before being adopted
# (about 200 lines of C that only read a marker file and talk to Herdr's local socket, plus one
# Lua module; no network, no subprocess apart from a `herdr pane focus` fallback). To move to a
# newer version: read the diff, then change the SHA below.
#
# Order matters: with the keys bound and no plugin installed, Ctrl+h (also Backspace in many
# terminals) does nothing in a Herdr pane. So the config reload happens only after the plugin is
# there; and the Herdr server must be running for the plugin to register, which it is from the
# moment Herdr has been opened once.
#
# Every step handles its own failure instead of relying on `set -e`: bash turns errexit off
# inside a function that's called as `install_herdr_plugins || ...`.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

HERDR_NAV_REPO="aimdevlee/herdr-nvim-nav"
HERDR_NAV_REF="ec047fd6d8d0269d54a34e9405af28d8aad4c8f0"

# Homebrew puts herdr on PATH; mise installs it under its own prefix, which only shell
# activation puts on PATH, so ask mise too.
_herdr_bin() {
  local mise path
  command -v herdr 2>/dev/null && return 0
  for mise in "$(command -v mise 2>/dev/null)" "$HOME/.local/bin/mise" /opt/homebrew/bin/mise; do
    [[ -x $mise ]] || continue
    path="$("$mise" which herdr 2>/dev/null)" && [[ -x $path ]] && { echo "$path"; return 0; }
  done
  return 1
}

install_herdr_plugins() {
  local herdr yes
  herdr="$(_herdr_bin)" || {
    log "Herdr isn't installed - skipping its Neovim navigation plugin."
    return 0
  }
  command -v cc >/dev/null 2>&1 || {
    log "WARNING: no C compiler (cc) - the herdr-nvim-nav plugin can't be built; install Xcode's command line tools / base-devel / gcc."
    return 1
  }

  if "$herdr" plugin list 2>/dev/null | grep -q 'herdr-nvim-nav'; then
    log "Herdr plugin herdr-nvim-nav already installed."
  else
    log "Installing the herdr-nvim-nav plugin (pinned to ${HERDR_NAV_REF:0:7})..."
    # Herdr asks for confirmation before installing a plugin: at a terminal you get its own
    # prompt; with no terminal to answer on (a script, CI) it refuses without --yes. The pinned
    # commit was reviewed (see above), which is what that confirmation stands for.
    yes=()
    [[ -t 0 ]] || yes=(--yes)
    "$herdr" plugin install "$HERDR_NAV_REPO" --ref "$HERDR_NAV_REF" ${yes[@]+"${yes[@]}"} || {
      log "WARNING: couldn't install herdr-nvim-nav - Ctrl+h/j/k/l are bound to it in config.toml, so until it is installed they do nothing in Herdr. Run: herdr plugin install $HERDR_NAV_REPO --ref $HERDR_NAV_REF"
      return 1
    }
  fi

  # a running server only re-reads config.toml when told to; harmless when none is running
  "$herdr" server reload-config >/dev/null 2>&1 || true
  return 0
}
