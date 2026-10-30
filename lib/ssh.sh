#!/usr/bin/env bash
# SSH glue for the second Proton Pass agent, the one that serves the "Deploy" vault (the main agent serves
# only "SSH"). The Host block that uses it is common/.ssh/config.d/vue-ui-kit-deploy.conf, linked into
# ~/.ssh/config.d by symlink_dotfiles; ensure_ssh_include makes ~/.ssh/config read that directory.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

DEPLOY_SOCK="$HOME/.ssh/proton-deploy-agent.sock"

# `Include config.d/*.conf` at the top of ~/.ssh/config (Include only reaches Host blocks when it comes
# before them). Idempotent; an existing file is backed up once, and edited in place so a symlinked
# config stays a symlink.
ensure_ssh_include() {
  local cfg="$HOME/.ssh/config" line='Include config.d/*.conf' tmp
  mkdir -p -m 700 "$HOME/.ssh"
  if [[ ! -e $cfg ]]; then
    printf '%s\n' "$line" >"$cfg" && chmod 600 "$cfg"
    log "Created $cfg with an Include for ~/.ssh/config.d."
    return 0
  fi
  grep -Eq '^[[:space:]]*Include[[:space:]].*config\.d' "$cfg" && return 0
  [[ -e $cfg.pre-dotfiles ]] || cp -p "$cfg" "$cfg.pre-dotfiles"
  tmp="$(mktemp "${TMPDIR:-/tmp}/sshcfg.XXXXXX")" || return 1
  { printf '%s\n\n' "$line"; cat "$cfg"; } >"$tmp" && cat "$tmp" >"$cfg"
  rm -f "$tmp"
  log "Added 'Include config.d/*.conf' to the top of $cfg (a copy is in $cfg.pre-dotfiles)."
}

# Does the Deploy agent answer with a key? It was started by the OS installer; give it a few seconds.
# Not fatal: without the vault access (a PAT is granted vaults one by one) it simply serves nothing.
check_deploy_agent() {
  command -v ssh-add >/dev/null || return 0
  # only where Proton Pass is in use (logged in): anywhere else there is nothing to wait for
  command -v pass-cli >/dev/null && pass-cli info >/dev/null 2>&1 || return 0
  local i rc=2
  for i in 1 2 3 4 5 6 7 8; do
    SSH_AUTH_SOCK="$DEPLOY_SOCK" ssh-add -L >/dev/null 2>&1; rc=$?
    [[ -S $DEPLOY_SOCK && $rc -eq 0 ]] && { log "The Deploy-vault SSH agent is serving a key."; return 0; }
    sleep 2
  done
  log "WARNING: the Deploy-vault SSH agent isn't serving a key ($DEPLOY_SOCK). The usual cause is a Proton Pass token with no access to the vault; grant it (names: pass-cli personal-access-token list):"
  log "         pass-cli personal-access-token access grant --personal-access-token-name <name> --vault-name Deploy"
  return 0
}
