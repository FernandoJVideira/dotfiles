#!/usr/bin/env bash
# Two files hold secrets this repo can't ship: ~/.npmrc (the Gitea token for the @fernandojvideira
# npm registry, every OS) and ~/.config/proton-pass-cli/pat (the Proton Pass personal access token
# the SSH agent unit logs in with, Linux only: the macOS agent uses the login pass-cli keeps in the
# keychain). create_secret_templates writes each one with everything but the token, and only when
# the file doesn't exist, so a file that is already there is never touched. print_secret_instructions
# lists the ones that still hold the placeholder and says what to do; it only looks for the
# placeholder text and never reads or prints anything else in them.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

NPMRC="$HOME/.npmrc"
PROTON_PAT="$HOME/.config/proton-pass-cli/pat"
NPM_PLACEHOLDER="REPLACE_WITH_YOUR_GITEA_TOKEN"
PAT_PLACEHOLDER="REPLACE_WITH_YOUR_PROTON_PASS_PAT"

# true when the file exists and still holds a placeholder
secret_pending() {
  [[ -f $1 ]] && grep -Fq REPLACE_WITH_ "$1"
}

# true when the file exists and the token has been filled in
secret_ready() {
  [[ -f $1 ]] && ! secret_pending "$1"
}

create_secret_templates() {
  if [[ ! -e $NPMRC ]]; then
    (
      umask 077
      cat >"$NPMRC" <<EOF
@fernandojvideira:registry=https://git.fernandovideira.com/api/packages/FernandoJVideira/npm/
//git.fernandovideira.com/api/packages/FernandoJVideira/npm/:_authToken=$NPM_PLACEHOLDER
EOF
    )
    log "Created $NPMRC with a placeholder token."
  fi

  if [[ $(uname -s) == Linux && ! -e $PROTON_PAT ]]; then
    (
      umask 077
      mkdir -p -m 700 "$(dirname "$PROTON_PAT")"
      printf '%s\n' "$PAT_PLACEHOLDER" >"$PROTON_PAT"
    )
    log "Created $PROTON_PAT with a placeholder token."
  fi
  return 0
}

print_secret_instructions() {
  local pending=0
  secret_pending "$NPMRC" && pending=1
  [[ $(uname -s) == Linux ]] && secret_pending "$PROTON_PAT" && pending=1
  if [[ $pending == 0 ]]; then
    local ready=()
    secret_ready "$NPMRC" && ready+=("~/.npmrc")
    [[ $(uname -s) == Linux ]] && secret_ready "$PROTON_PAT" && ready+=("~/.config/proton-pass-cli/pat")
    [[ ${#ready[@]} -eq 0 ]] || log "Token files are in place, nothing to add: ${ready[*]}"
    return 0
  fi

  printf '\n\033[33m==> Tokens to add\033[0m (each file was created with a placeholder in place of the token):\n\n'
  if secret_pending "$NPMRC"; then
    cat <<EOF
  ~/.npmrc
    Replace $NPM_PLACEHOLDER with a Gitea token that has the "package" scope
    (git.fernandovideira.com > Settings > Applications > Generate New Token).
    It lets npm and pnpm install @fernandojvideira/vue-ui-kit.
    Edit it:  ${EDITOR:-nvim} ~/.npmrc

EOF
  fi
  if [[ $(uname -s) == Linux ]] && secret_pending "$PROTON_PAT"; then
    cat <<EOF
  ~/.config/proton-pass-cli/pat
    Replace $PAT_PLACEHOLDER with a Proton Pass personal access token (the file holds
    the token and nothing else). The SSH agent stays off until you do.
    Edit it:  ${EDITOR:-nvim} ~/.config/proton-pass-cli/pat
    Then:     systemctl --user restart proton-pass-agent.service

EOF
  fi
  return 0
}
