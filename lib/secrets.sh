#!/usr/bin/env bash
# Two files hold secrets this repo can't ship: ~/.npmrc (the Gitea token for the @fernandojvideira
# npm registry, every OS) and ~/.config/proton-pass-cli/pat (the Proton Pass personal access token
# the SSH agent unit logs in with, Linux only: the macOS agent uses the login pass-cli keeps in the
# keychain). create_secret_templates writes each one with everything but the token, and only when
# the file doesn't exist, so a file that is already there is never touched. print_secret_instructions
# lists the ones that still hold the placeholder and says what to do; it only looks for the
# placeholder text and never reads or prints anything else in them. prompt_for_secrets, called first
# thing by bootstrap.sh, asks for the tokens up front (hidden input, Enter skips one), so everything
# after it runs unattended and the SSH agent is up before the Brain vault is cloned through it.

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

# put $2 in place of the placeholder $3 in file $1 (the token only ever sits in the environment of one awk)
fill_secret() {
  local file="$1" token="$2" placeholder="$3" tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/secret.XXXXXX")" || return 1
  chmod 600 "$tmp"
  TOKEN="$token" awk -v ph="$placeholder" '{ i = index($0, ph); if (i) $0 = substr($0, 1, i - 1) ENVIRON["TOKEN"] substr($0, i + length(ph)); print }' "$file" >"$tmp" \
    && mv "$tmp" "$file" && chmod 600 "$file"
}

# read one hidden line from the terminal into the variable named $2; false when there is no terminal
ask_secret() {
  local prompt="$1" answer
  { : </dev/tty; } 2>/dev/null || return 1
  IFS= read -rs -p "$prompt" answer </dev/tty 2>/dev/tty || return 1
  printf '\n' >/dev/tty
  printf -v "$2" '%s' "$answer"
}

create_npmrc_template() {
  [[ -e $NPMRC ]] && return 0
  (
    umask 077
    cat >"$NPMRC" <<TEMPLATE
@fernandojvideira:registry=https://git.fernandovideira.com/api/packages/FernandoJVideira/npm/
//git.fernandovideira.com/api/packages/FernandoJVideira/npm/:_authToken=$NPM_PLACEHOLDER
TEMPLATE
  )
}

create_pat_template() {
  [[ -e $PROTON_PAT ]] && return 0
  (
    umask 077
    mkdir -p -m 700 "$(dirname "$PROTON_PAT")"
    printf '%s\n' "$PAT_PLACEHOLDER" >"$PROTON_PAT"
  )
}

# Ask for each token that is still missing: the file doesn't exist, or it holds the placeholder. A
# token that is already in place is never asked for or touched. Enter skips (the file then gets the
# placeholder and the instructions at the end of the run apply). No terminal: skip silently.
prompt_for_secrets() {
  local need_npm=0 need_pat=0 token=""
  if [[ ! -e $NPMRC ]] || secret_pending "$NPMRC"; then need_npm=1; fi
  if [[ $(uname -s) == Linux ]] && { [[ ! -e $PROTON_PAT ]] || secret_pending "$PROTON_PAT"; }; then need_pat=1; fi
  [[ $need_npm == 0 && $need_pat == 0 ]] && return 0
  { : </dev/tty; } 2>/dev/null || return 0

  printf '\n\033[32m==>\033[0m Tokens: paste each one (hidden), or press Enter to add it later.\n'
  if [[ $need_npm == 1 ]]; then
    printf '    Gitea token with the "package" scope: git.fernandovideira.com > Settings > Applications.\n'
    if ask_secret '    npm registry token (~/.npmrc): ' token && [[ -n $token ]]; then
      create_npmrc_template
      fill_secret "$NPMRC" "$token" "$NPM_PLACEHOLDER" && log "Saved $NPMRC."
    fi
  fi
  if [[ $need_pat == 1 ]]; then
    printf '    Proton Pass personal access token: the SSH agent logs in with it, and this run reaches git through the agent.\n'
    if ask_secret '    Proton Pass token (~/.config/proton-pass-cli/pat): ' token && [[ -n $token ]]; then
      create_pat_template
      fill_secret "$PROTON_PAT" "$token" "$PAT_PLACEHOLDER" && log "Saved $PROTON_PAT."
    fi
  fi
  token=""
  return 0
}

create_secret_templates() {
  if [[ ! -e $NPMRC ]]; then
    create_npmrc_template
    log "Created $NPMRC with a placeholder token."
  fi
  if [[ $(uname -s) == Linux && ! -e $PROTON_PAT ]]; then
    create_pat_template
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
