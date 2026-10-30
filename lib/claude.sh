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
