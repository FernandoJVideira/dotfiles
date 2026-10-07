#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

OMARSHELL_REPO="${OMARSHELL_REPO:-https://github.com/FernandoJVideira/omarshell.git}"
OMARSHELL_DIR="${OMARSHELL_DIR:-$HOME/.local/share/omarshell}"

# Clones/updates omarshell and sources its env-bootstrap into THIS shell too,
# so the rest of the calling install.sh can use omarshell-* commands right away
# instead of only after the next login.
install_omarshell_repo() {
  if [[ -d "$OMARSHELL_DIR/.git" ]]; then
    log "Updating omarshell..."
    git -C "$OMARSHELL_DIR" pull
  else
    log "Cloning omarshell..."
    git clone "$OMARSHELL_REPO" "$OMARSHELL_DIR"
  fi
  source "$OMARSHELL_DIR/bin/lib/env-bootstrap"
}

# Wires OMARCHY_PATH/PATH into future graphical sessions two ways: uwsm's own
# env.d (read before Hyprland starts, when uwsm launches the session) and
# systemd's environment.d (read by any pam_systemd login session regardless
# of uwsm - needed on distros where Hyprland is started directly by the
# display manager). Harmless to have both; only one will actually apply.
setup_omarshell_session_env() {
  log "Wiring OMARCHY_PATH into future graphical sessions..."

  mkdir -p "$HOME/.config/uwsm/env.d" "$HOME/.config/environment.d"

  sed "s|__OMARSHELL_PATH__|$OMARSHELL_DIR|g" \
    "$OMARSHELL_DIR/integration/uwsm-env.d-omarshell.template" \
    >"$HOME/.config/uwsm/env.d/10-omarshell"

  cat >"$HOME/.config/environment.d/omarshell.conf" <<EOF
OMARCHY_PATH=$OMARSHELL_DIR
PATH=$OMARSHELL_DIR/bin:\${PATH}
EOF
}

# hyprland.lua (dotfiles-managed) hard-requires hypr.input/bindings/looknfeel
# as personal-override modules. Omarchy's own package normally seeds these via
# /etc/skel; without that package we have to seed them ourselves. Only fills
# in whatever a distro's own dotfiles didn't already symlink - never
# overwrites an existing file.
seed_hypr_personal_overrides() {
  local dir="$HOME/.config/hypr"
  mkdir -p "$dir"

  [[ -f "$dir/input.lua" ]] || cat >"$dir/input.lua" <<'EOF'
-- Personal input overrides. See https://wiki.hypr.land/Configuring/Basics/Variables/#input
EOF

  [[ -f "$dir/bindings.lua" ]] || cat >"$dir/bindings.lua" <<'EOF'
-- Personal keybinding overrides. See: omarchy menu keybindings --print
EOF

  [[ -f "$dir/looknfeel.lua" ]] || cat >"$dir/looknfeel.lua" <<'EOF'
-- Personal look'n'feel overrides. See https://wiki.hypr.land/Configuring/Basics/Variables/
EOF
}
