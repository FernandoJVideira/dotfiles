#!/usr/bin/env bash
# Two secrets this repo can't ship: ~/.npmrc (the Gitea token for the @fernandojvideira npm registry,
# every OS) and the Proton Pass personal access token the SSH agent unit logs in with (Linux only: it
# lives in the login keyring, read with secret-tool; the macOS agent uses the login pass-cli keeps in
# the keychain). create_secret_templates writes ~/.npmrc with everything but the token, and only when
# the file doesn't exist, so a file that is already there is never touched. migrate_pat_file moves a
# token left in the old ~/.config/proton-pass-cli/pat into the keyring and deletes the file.
# print_secret_instructions lists what is still missing and says what to do; it only looks for the
# placeholder text and never reads or prints a token. prompt_for_secrets, called first thing by
# bootstrap.sh, asks for the tokens up front (hidden input, Enter skips one), so everything after it
# runs unattended and the SSH agent is up before the Brain vault is cloned through it.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

NPMRC="$HOME/.npmrc"
PROTON_PAT_FILE="$HOME/.config/proton-pass-cli/pat"
NPM_PLACEHOLDER="REPLACE_WITH_YOUR_GITEA_TOKEN"

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

# true when the keyring holds the Proton Pass token
pat_ready() {
  command -v secret-tool >/dev/null || return 1
  [[ -n $(secret-tool lookup service proton-pass-cli account pat 2>/dev/null) ]]
}

pat_store() {
  printf %s "$1" | secret-tool store --label='Proton Pass personal access token' service proton-pass-cli account pat
}

# Linux: move a token from the old pat file into the keyring, then delete the file
migrate_pat_file() {
  [[ $(uname -s) == Linux && -f $PROTON_PAT_FILE ]] || return 0
  local token
  token="$(tr -d '[:space:]' <"$PROTON_PAT_FILE")"
  if [[ -z $token || $token == *REPLACE_WITH_* ]]; then
    rm -f "$PROTON_PAT_FILE"
  elif pat_ready; then
    return 0
  elif pat_store "$token" 2>/dev/null; then
    rm -f "$PROTON_PAT_FILE"
    log "Moved the Proton Pass token from $PROTON_PAT_FILE into the keyring."
  else
    log "WARNING: could not store the Proton Pass token in the keyring (locked?); kept $PROTON_PAT_FILE."
  fi
  return 0
}

# Ask for each token that is still missing: ~/.npmrc doesn't exist or holds the placeholder, or the
# keyring has no Proton Pass token. A token that is already in place is never asked for or touched.
# Enter skips (the instructions at the end of the run apply). No terminal: skip silently.
prompt_for_secrets() {
  local need_npm=0 need_pat=0 token=""
  migrate_pat_file
  if [[ ! -e $NPMRC ]] || secret_pending "$NPMRC"; then need_npm=1; fi
  if [[ $(uname -s) == Linux ]] && ! pat_ready; then need_pat=1; fi
  [[ $need_npm == 0 && $need_pat == 0 ]] && return 0
  { : </dev/tty; } 2>/dev/null || return 0

  printf '\n\033[32m==>\033[0m Tokens: paste each one (hidden), or press Enter to add it later.\n'
  if [[ $need_npm == 1 ]]; then
    printf '    Only needed for the @fernandojvideira npm registry (skip it if that is not you). A Gitea token\n'
    printf '    with the "package" scope: git.fernandovideira.com > Settings > Applications.\n'
    if ask_secret '    npm registry token (~/.npmrc): ' token && [[ -n $token ]]; then
      create_npmrc_template
      fill_secret "$NPMRC" "$token" "$NPM_PLACEHOLDER" && log "Saved $NPMRC."
    fi
  fi
  if [[ $need_pat == 1 ]]; then
    printf '    Proton Pass personal access token: the SSH agent logs in with it, and this run reaches git through the agent.\n'
    if ask_secret '    Proton Pass token (stored in the login keyring): ' token && [[ -n $token ]]; then
      if pat_store "$token" 2>/dev/null; then
        log "Saved the Proton Pass token in the keyring."
      else
        log "WARNING: could not save the Proton Pass token: the keyring may be locked. The instructions at the end say how to add it later."
      fi
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
  migrate_pat_file
  return 0
}

print_secret_instructions() {
  local pending=0 pat_pending=0
  secret_pending "$NPMRC" && pending=1
  if [[ $(uname -s) == Linux ]] && ! pat_ready; then pat_pending=1; pending=1; fi
  if [[ $pending == 0 ]]; then
    local ready=()
    secret_ready "$NPMRC" && ready+=("~/.npmrc")
    [[ $(uname -s) == Linux ]] && pat_ready && ready+=("Proton Pass token (keyring)")
    [[ ${#ready[@]} -eq 0 ]] || log "Tokens are in place, nothing to add: ${ready[*]}"
    return 0
  fi

  printf '\n\033[33m==> Tokens to add\033[0m:\n\n'
  if secret_pending "$NPMRC"; then
    cat <<EOF
  ~/.npmrc
    Replace $NPM_PLACEHOLDER with a Gitea token that has the "package" scope
    (git.fernandovideira.com > Settings > Applications > Generate New Token).
    It lets npm and pnpm install @fernandojvideira/vue-ui-kit.
    Edit it:  ${EDITOR:-nvim} ~/.npmrc

EOF
  fi
  if [[ $pat_pending == 1 ]]; then
    cat <<EOF
  Proton Pass token (login keyring)
    Store a Proton Pass personal access token in the keyring (it asks for the token on stdin).
    The SSH agent stays off until you do.
    Store it: secret-tool store --label='Proton Pass personal access token' service proton-pass-cli account pat
    Then:     systemctl --user restart proton-pass-agent.service

EOF
  fi
  return 0
}
