#!/usr/bin/env bash
# Claude Code setup that isn't a plain symlink: the Brain vault skeleton, and the hook entries in
# ~/.claude/settings.json. The files themselves come from common/.claude (symlinked by symlink_dotfiles).

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# ~/Brain (or $BRAIN_DIR): an Obsidian-style vault with one folder of notes per project. Only created
# when missing; nothing that is already there is touched. See docs/brain.md.
create_brain_vault() {
  local vault="${BRAIN_DIR:-$HOME/Brain}"
  mkdir -p "$vault/projects" "$vault/knowledge" "$vault/_agent"
  if [[ ! -e $vault/INDEX.md ]]; then
    cat >"$vault/INDEX.md" <<'INDEX'
# Brain

One line per project and per knowledge note. Machine-written notes live in `projects/<slug>/`
(`state.md`, `decisions.md`, `log.md`); your own notes go in `knowledge/` or anywhere else.

## Projects

## Knowledge
INDEX
    log "Created the Brain vault at $vault"
  fi
}

# The hooks that give a session its project's memory and log what git saw at the end. Replaces any
# earlier brain-* entry and leaves every other hook (Herdr's, say) alone. The old file is kept once.
install_claude_hooks() {
  local settings="$HOME/.claude/settings.json" dir="$HOME/.claude/hooks" tmp
  command -v jq >/dev/null || { log "WARNING: jq is missing, so the Claude hooks weren't added."; return 1; }
  [[ -x $dir/brain-start.sh && -x $dir/brain-end.sh ]] || { log "WARNING: $dir/brain-*.sh aren't linked yet."; return 1; }
  mkdir -p "$HOME/.claude"
  [[ -f $settings ]] || echo '{}' >"$settings"
  [[ -e $settings.pre-brain ]] || cp "$settings" "$settings.pre-brain"

  tmp="$(mktemp)"
  jq --arg start "bash $dir/brain-start.sh" --arg end "bash $dir/brain-end.sh" '
    def without_brain: map(select(([.hooks[]?.command] | join(" ")) | contains("brain-") | not));
    .hooks //= {}
    | .hooks.SessionStart = ((.hooks.SessionStart // []) | without_brain)
        + [{matcher: "^(startup|resume|clear|compact)$", hooks: [{type: "command", command: $start, timeout: 10}]}]
    | .hooks.SessionEnd = ((.hooks.SessionEnd // []) | without_brain)
        + [{hooks: [{type: "command", command: $end, timeout: 5}]}]
    | .hooks.PreCompact = ((.hooks.PreCompact // []) | without_brain)
        + [{hooks: [{type: "command", command: $end, timeout: 5}]}]' "$settings" >"$tmp" \
    && mv "$tmp" "$settings" && log "Claude hooks: project memory at session start, git log at session end."
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
