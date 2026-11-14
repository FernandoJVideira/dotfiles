#!/usr/bin/env bash
# Git clean filters for files that hold machine-local data. Registered per clone, since git config
# isn't versioned; .gitattributes names the filters.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# Zed rewrites ssh_connections (hosts, usernames) into settings.json itself; keep it out of the repo.
register_git_filters() {
  local root="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  git -C "$root" config filter.zed-ssh.clean "$root/lib/git-filters/zed-strip-ssh" &&
    git -C "$root" config filter.zed-ssh.smudge cat &&
    git -C "$root" config filter.zed-ssh.required true || return 1
  log "Registered the zed-ssh git filter."
}
