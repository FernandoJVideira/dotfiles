#!/usr/bin/env bash
# Claude Code setup that isn't a plain symlink: the Brain vault skeleton, and the hook entries in
# ~/.claude/settings.json. The files themselves come from common/.claude (symlinked by symlink_dotfiles).

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/secrets.sh"

# ~/Brain (or $BRAIN_DIR): an Obsidian-style vault with one folder of notes per project, kept in step
# between machines through a git remote. The skeleton is only created when missing and nothing already
# there is touched. See docs/brain.md.
#
# Which remote (BRAIN_REMOTE) is decided once, when the vault isn't linked to one yet:
#   1. $BRAIN_REMOTE in the environment ("none" = keep the vault on this machine only)
#   2. the one saved on this machine, ~/.config/dotfiles/brain-remote
#   3. the owner's default, when it answers (it is private, so answering proves the access)
#   4. otherwise ask for one's own remote; Enter keeps the vault local
# A vault that already has a commit keeps its origin and none of this runs again.
BRAIN_DEFAULT_REMOTE="${BRAIN_DEFAULT_REMOTE:-git@git.fernandovideira.com:FernandoJVideira/agent-brain.git}"
BRAIN_REMOTE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/brain-remote"

# ssh options for the server: no prompts, short timeouts, and the Proton Pass agent's socket when it
# exists (this script's shell doesn't have SSH_AUTH_SOCK yet on a fresh machine)
brain_ssh_cmd() {
  local sock="$HOME/.ssh/proton-pass-agent.sock"
  printf 'ssh -o BatchMode=yes -o ConnectTimeout=5%s' "$([[ -S $sock ]] && printf ' -o IdentityAgent=%s' "$sock")"
}

# does this remote answer (an empty repo does too)?
brain_remote_answers() {
  GIT_SSH_COMMAND="$(brain_ssh_cmd)" git ls-remote "$1" >/dev/null 2>&1
}

# is a Proton Pass agent on its way up on this machine? (no point waiting for one otherwise)
proton_agent_expected() {
  [[ -S $HOME/.ssh/proton-pass-agent.sock ]] && return 0
  pat_ready && return 0
  command -v pass-cli >/dev/null && pass-cli info >/dev/null 2>&1
}

# the agent (started earlier by the OS installer) needs a few seconds to log in; give it up to 20
wait_for_ssh_agent() {
  local sock="$HOME/.ssh/proton-pass-agent.sock" rc
  for _ in $(seq 10); do
    SSH_AUTH_SOCK="$sock" ssh-add -l >/dev/null 2>&1; rc=$?
    [[ -S $sock && $rc -ne 2 ]] && return 0
    sleep 2
  done
  return 1
}

# the default isn't reachable from here, so this is someone else's machine (or the owner's, not logged in
# yet): ask for a remote of their own. Sets BRAIN_REMOTE, empty when none.
ask_brain_remote() {
  local answer=""
  BRAIN_REMOTE=""
  if ! { : </dev/tty; } 2>/dev/null; then
    log "The Brain vault stays on this machine: $BRAIN_DEFAULT_REMOTE isn't reachable and there is no terminal to ask on. To sync it, rerun with BRAIN_REMOTE=<your git remote>."
    return 0
  fi
  printf '\n\033[32m==>\033[0m The Brain (Claude'"'"'s project memory) syncs through a git remote, and the default one\n'
  printf '    (%s) isn'"'"'t reachable from here.\n' "$BRAIN_DEFAULT_REMOTE"
  printf '    Give a remote of your own (an empty private repo, e.g. git@host:you/brain.git), or press Enter to\n'
  printf '    keep the vault on this machine only (a rerun of ./bootstrap.sh asks again).\n'
  IFS= read -r -p '    Brain remote: ' answer </dev/tty 2>/dev/tty || answer=""
  answer="${answer#"${answer%%[![:space:]]*}"}"; answer="${answer%"${answer##*[![:space:]]}"}"
  [[ -n $answer ]] || return 0
  if brain_remote_answers "$answer"; then
    mkdir -p "$(dirname "$BRAIN_REMOTE_FILE")" && printf '%s\n' "$answer" >"$BRAIN_REMOTE_FILE"
    BRAIN_REMOTE="$answer"
    log "Saved the Brain remote in $BRAIN_REMOTE_FILE"
  else
    log "WARNING: $answer didn't answer (wrong URL, or no access), so the vault stays on this machine; rerun ./bootstrap.sh."
  fi
}

choose_brain_remote() {
  if [[ -n ${BRAIN_REMOTE+x} ]]; then
    :
  elif [[ -s $BRAIN_REMOTE_FILE ]]; then
    BRAIN_REMOTE="$(head -n 1 "$BRAIN_REMOTE_FILE")"
  elif brain_remote_answers "$BRAIN_DEFAULT_REMOTE"; then
    BRAIN_REMOTE="$BRAIN_DEFAULT_REMOTE"
  else
    ask_brain_remote
  fi
  [[ $BRAIN_REMOTE == none ]] && BRAIN_REMOTE=""
  return 0
}

create_brain_vault() {
  local vault="${BRAIN_DIR:-$HOME/Brain}" ssh refs
  if git -C "$vault" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    BRAIN_REMOTE="$(git -C "$vault" remote get-url origin 2>/dev/null || true)"
  elif command -v git >/dev/null; then
    # not linked yet: the agent may still be logging in, and the remote has to be chosen
    if proton_agent_expected; then
      wait_for_ssh_agent || log "The Proton Pass SSH agent isn't answering yet."
    fi
    choose_brain_remote
  else
    BRAIN_REMOTE=""
  fi
  ssh="$(brain_ssh_cmd)"

  # a machine with no vault yet takes the server's copy
  if [[ ! -e $vault/.git && -n $BRAIN_REMOTE ]] && [[ ! -e $vault || -z $(ls -A "$vault" 2>/dev/null) ]]; then
    if GIT_SSH_COMMAND="$ssh" git clone -q "$BRAIN_REMOTE" "$vault" 2>/dev/null; then
      log "Cloned the Brain vault from $BRAIN_REMOTE"
    else
      rm -rf "$vault" 2>/dev/null
    fi
  fi

  mkdir -p "$vault/projects" "$vault/knowledge" "$vault/_agent"
  if [[ ! -e $vault/INDEX.md ]]; then
    cat >"$vault/INDEX.md" <<'INDEX'
# Brain

The Brain. Everything here is written by Claude from conversations; nothing is a source you edit.
`projects/<slug>/` holds `state.md` (current status), `decisions.md`, `log.md` (written by hooks), and
`topics/` (one page per durable how/why, each with a one-line `summary:` in its frontmatter).
`knowledge/` holds lessons that hold across projects. This file is the catalog: one line per page,
grouped under Projects and Knowledge.

## Projects

## Knowledge
INDEX
    log "Created the Brain vault at $vault"
  fi

  [[ -n $BRAIN_REMOTE ]] && command -v git >/dev/null || return 0
  # per-machine Obsidian settings (and the plugin data that may hold credentials) stay out of git;
  # the append-only notes merge by union, so two machines adding lines never conflict
  [[ -e $vault/.gitignore ]] || printf '%s\n' '.obsidian/' '.trash/' '.DS_Store' '*.sync-conflict-*' >"$vault/.gitignore"
  [[ -e $vault/.gitattributes ]] || printf '%s\n' 'log.md merge=union' 'decisions.md merge=union' >"$vault/.gitattributes"
  grep -qxF 'projects/*/memory/MEMORY.md merge=union' "$vault/.gitattributes" \
    || { [[ -z $(tail -c 1 "$vault/.gitattributes") ]] || echo >>"$vault/.gitattributes"; echo 'projects/*/memory/MEMORY.md merge=union' >>"$vault/.gitattributes"; }

  if [[ ! -e $vault/.git ]]; then
    git -C "$vault" init -q -b main
    git -C "$vault" remote add origin "$BRAIN_REMOTE"
  fi
  if ! git -C "$vault" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    # no commits yet: join the server's history if it has one. If the server can't be reached, stop here
    # without a commit of our own (a root commit made offline would never merge with the server's);
    # the next ./bootstrap.sh retries, and the hooks do nothing until then.
    if ! refs="$(GIT_SSH_COMMAND="$ssh" git -C "$vault" ls-remote origin 2>/dev/null)"; then
      log "WARNING: couldn't reach $BRAIN_REMOTE (no SSH access yet?), so the Brain vault stays local; rerun ./bootstrap.sh once it works."
      return 0
    fi
    if [[ -n $refs ]]; then
      GIT_SSH_COMMAND="$ssh" git -C "$vault" fetch -q origin main 2>/dev/null || { log "WARNING: couldn't fetch the Brain vault; rerun ./bootstrap.sh."; return 0; }
      if [[ -z $(find "$vault/projects" "$vault/knowledge" -type f 2>/dev/null | head -n 1) ]]; then
        git -C "$vault" checkout -q -f -B main origin/main
        git -C "$vault" branch -q --set-upstream-to=origin/main main 2>/dev/null || true
        log "Brain vault joined the history on $BRAIN_REMOTE"
      else
        log "WARNING: $vault has notes and so does $BRAIN_REMOTE; merge them by hand (git -C $vault)."
        return 1
      fi
    else
      git -C "$vault" add -A
      git -C "$vault" -c commit.gpgsign=false commit -q -m "brain: first commit from $(hostname -s)" || true
    fi
  fi
  if ! GIT_SSH_COMMAND="$ssh" git -C "$vault" push -q -u origin HEAD 2>/dev/null; then
    log "WARNING: couldn't push the Brain vault to $BRAIN_REMOTE (offline, or no SSH access). The hooks retry."
  fi
}

# The hooks that give a session its project's memory and log what git saw at the end. Replaces any
# earlier brain-* entry and leaves every other hook (Herdr's, say) alone. The old file is kept once.
install_claude_hooks() {
  local settings="$HOME/.claude/settings.json" dir="$HOME/.claude/hooks" tmp
  command -v jq >/dev/null || { log "WARNING: jq is missing, so the Claude hooks weren't added."; return 1; }
  [[ -x $dir/brain-start.sh && -x $dir/brain-end.sh && -x $dir/brain-sync.sh && -x $dir/brain-prompt.sh ]] || { log "WARNING: $dir/brain-*.sh aren't linked yet."; return 1; }
  mkdir -p "$HOME/.claude"
  [[ -f $settings ]] || echo '{}' >"$settings"
  [[ -e $settings.pre-brain ]] || cp "$settings" "$settings.pre-brain"

  tmp="$(mktemp)"
  jq --arg start "bash $dir/brain-start.sh" --arg end "bash $dir/brain-end.sh" --arg sync "bash $dir/brain-sync.sh" --arg prompt "bash $dir/brain-prompt.sh" '
    def without_brain: map(select(([.hooks[]?.command] | join(" ")) | contains("brain-") | not));
    .hooks //= {}
    | .hooks.SessionStart = ((.hooks.SessionStart // []) | without_brain)
        + [{matcher: "^(startup|resume|clear|compact)$", hooks: [{type: "command", command: $start, timeout: 10}]}]
    | .hooks.SessionEnd = ((.hooks.SessionEnd // []) | without_brain)
        + [{hooks: [{type: "command", command: $end, timeout: 5}]}]
    | .hooks.PreCompact = ((.hooks.PreCompact // []) | without_brain)
        + [{hooks: [{type: "command", command: $end, timeout: 5}]}]
    | .hooks.PostToolUse = ((.hooks.PostToolUse // []) | without_brain)
        + [{matcher: "^(Write|Edit|MultiEdit|Bash)$", hooks: [{type: "command", command: $sync, timeout: 5}]}]
    | .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) | without_brain)
        + [{hooks: [{type: "command", command: $prompt, timeout: 5}]}]' "$settings" >"$tmp" \
    && mv "$tmp" "$settings" && log "Claude hooks: project memory at session start, git log at session end, notes pushed within seconds of a write, other machines' notes noticed at each prompt."
}

# Skills from other people that overlap or that I don't reach for: listed by name only, so their
# descriptions leave the context of every turn (they still run when invoked by name). The list is
# common/.claude/skill-overrides.json; it is merged into ~/.claude/settings.json. skillOverrides does
# not apply to plugin skills: those are switched off in /plugin.
install_skill_overrides() {
  local settings="$HOME/.claude/settings.json" list="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/common/.claude/skill-overrides.json" tmp
  [[ -f $list && -f $settings ]] || return 0
  tmp="$(mktemp)"
  jq --slurpfile new "$list" '.skillOverrides = ((.skillOverrides // {}) + $new[0])' "$settings" >"$tmp" \
    && mv "$tmp" "$settings" && log "Claude skills: overlapping third-party skills listed by name only."
}

# RTK (https://github.com/rtk-ai/rtk) shrinks the output of git, go, ls and other commands before Claude
# reads it. Pinned to one release and checked against that release's checksums, and only the Apache-2.0
# "rtk-oss" build: not the RTK Proxy daemon (it would sit in the middle of the API traffic), and its
# telemetry stays off (the default). The hook is `rtk hook claude`, a PreToolUse hook on Bash that fails
# open: if rtk is missing or anything goes wrong the command runs unchanged. To take it out, delete the
# PreToolUse entry whose command ends in "rtk hook claude" from ~/.claude/settings.json.
# NOT called automatically: run it yourself once you have read the note in docs/brain.md.
RTK_VERSION="1.1.0"

install_rtk() {
  local target tmp want have settings="$HOME/.claude/settings.json" bin="$HOME/.local/bin/rtk"
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) target=aarch64-apple-darwin ;;
    Darwin-x86_64) target=x86_64-apple-darwin ;;
    Linux-x86_64) target=x86_64-unknown-linux-musl ;;
    Linux-aarch64 | Linux-arm64) target=aarch64-unknown-linux-gnu ;;
    *) log "WARNING: no RTK build for $(uname -s) $(uname -m), skipping."; return 1 ;;
  esac
  command -v jq >/dev/null || { log "WARNING: jq is missing, so RTK wasn't set up."; return 1; }

  have="$("$bin" --version 2>/dev/null | awk '{print $2}')"
  if [[ $have != "$RTK_VERSION" ]]; then
    local base="https://github.com/rtk-ai/rtk/releases/download/v$RTK_VERSION"
    tmp="$(mktemp -d)"
    log "Installing RTK $RTK_VERSION (rtk-oss, $target)..."
    curl -fsSL -o "$tmp/rtk.tar.gz" "$base/rtk-oss-$target.tar.gz" \
      && curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt" || { rm -rf "$tmp"; return 1; }
    want="$(awk -v f="rtk-oss-$target.tar.gz" '$2 == f {print $1}' "$tmp/checksums.txt")"
    have="$( (shasum -a 256 "$tmp/rtk.tar.gz" 2>/dev/null || sha256sum "$tmp/rtk.tar.gz") | awk '{print $1}')"
    if [[ -z $want || $have != "$want" ]]; then
      log "WARNING: RTK's checksum didn't match, not installing it."
      rm -rf "$tmp"
      return 1
    fi
    tar -xzf "$tmp/rtk.tar.gz" -C "$tmp" rtk && mkdir -p "$HOME/.local/bin" && install -m 755 "$tmp/rtk" "$bin"
    rm -rf "$tmp"
  fi

  [[ -f $settings ]] || echo '{}' >"$settings"
  [[ -e $settings.pre-rtk ]] || cp "$settings" "$settings.pre-rtk"
  tmp="$(mktemp)"
  jq --arg cmd "$bin hook claude" '
    .hooks //= {}
    | .hooks.PreToolUse = ((.hooks.PreToolUse // [])
        | map(select(([.hooks[]?.command] | join(" ")) | contains("rtk hook claude") | not)))
        + [{matcher: "Bash", hooks: [{type: "command", command: $cmd}]}]' "$settings" >"$tmp" \
    && mv "$tmp" "$settings" && log "RTK $RTK_VERSION: Bash output is filtered before Claude reads it."
}

# Anthropic's code-intelligence plugins: Claude looks symbols up through the language server and sees type
# errors after an edit, instead of grepping and reading files. They need gopls and
# typescript-language-server on PATH (both from mise, common/.config/mise/conf.d). Safe to repeat; a
# plugin that is already installed is left as it is. Needs `claude` (mise installs it).
install_lsp_plugins() {
  command -v claude >/dev/null || { log "WARNING: claude isn't on PATH yet, so the LSP plugins weren't installed."; return 1; }
  local plugin out status=0
  for plugin in gopls-lsp typescript-lsp; do
    out="$(claude plugin install "$plugin@claude-plugins-official" 2>&1)" || { log "WARNING: $plugin: $(printf '%s' "$out" | tail -n 1)"; status=1; }
  done
  [[ $status == 0 ]] && log "Claude LSP plugins: gopls-lsp and typescript-lsp."
  return $status
}
