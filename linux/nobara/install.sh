#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"

# illogical-impulse (end-4/dots-hyprland) is the Hyprland+Quickshell base end4-pC
# builds on top of - its own installer already knows how to detect Fedora-family
# distros (Nobara includes) and install everything it needs via dnf, so we lean
# on it instead of hand-rolling a package list here.
ILLOGICAL_IMPULSE_DIR="$HOME/.local/share/illogical-impulse"
ILLOGICAL_IMPULSE_REPO="https://github.com/end-4/dots-hyprland.git"

# Our fork, for the Claude Code AI backend and any other customizations.
END4_PC_REPO="https://github.com/FernandoJVideira/end4-pC.git"
END4_PC_DIR="$HOME/.config/quickshell/end4-pC"

# Install zsh and set it as the default shell (mirrors linux/arch/install.sh)
log "Installing zsh..."
sudo dnf install -y zsh
sudo chsh -s "$(which zsh)" "$USER"

log "Installing git (needed to fetch illogical-impulse and end4-pC)..."
sudo dnf install -y git

if [[ -d "$ILLOGICAL_IMPULSE_DIR/.git" ]]; then
  log "Updating illogical-impulse..."
  git -C "$ILLOGICAL_IMPULSE_DIR" pull
else
  log "Cloning illogical-impulse..."
  git clone "$ILLOGICAL_IMPULSE_REPO" "$ILLOGICAL_IMPULSE_DIR"
fi

# illogical-impulse's own distro detector (sdata/lib/dist-determine.sh) only
# does an exact match against ID_LIKE=="fedora". Nobara reports
# ID_LIKE="rhel centos fedora" (multi-value), which misses that check and
# falls through to its Nix-based fallback installer - still WIP upstream and
# not what we want. It reads a REPO_ROOT/os-release override file first, if
# present, so write one with ID_LIKE corrected to force the dnf-based path.
log "Overriding illogical-impulse's distro detection for Nobara's multi-value ID_LIKE..."
sed 's/^ID_LIKE=.*/ID_LIKE="fedora"/' /etc/os-release > "$ILLOGICAL_IMPULSE_DIR/os-release"

# ./setup install is illogical-impulse's full (re)install flow - it resets
# its own config files, including ~/.config/hypr/hyprland/variables.lua and,
# apparently, ~/.config/quickshell/ itself (confirmed live: rerunning it wiped
# end4-pC's clone out from under a working setup, with no crash, just
# Quickshell silently unable to find "end4-pC" and falling back to defaults).
# Only run the full installer once; on a rerun, everything below this point
# (workstation tools, end4-pC clone/pull, the qsConfig and terminal patches,
# symlinks) is independently idempotent and re-verifies/repairs itself
# without needing a full reinstall. To pull upstream illogical-impulse
# updates deliberately, run "$ILLOGICAL_IMPULSE_DIR/setup" exp-update by hand.
if [[ -f "$HOME/.config/hypr/hyprland/variables.lua" ]]; then
  log "illogical-impulse already set up - skipping full reinstall (rerun with FORCE_II_REINSTALL=1 to override)..."
  [[ -n "${FORCE_II_REINSTALL:-}" ]] && "$ILLOGICAL_IMPULSE_DIR/setup" install
else
  log "Running illogical-impulse's installer (installs Hyprland, Quickshell, and every other dependency end4-pC needs)..."
  "$ILLOGICAL_IMPULSE_DIR/setup" install
fi

# Install workstation tools (mirrors linux/arch/install.sh's "go
# element-desktop ghostty" + zed). go is in Fedora's own repos; Ghostty and
# Zed aren't - both projects' own docs point at the Terra repo for Fedora.
#
# Nobara's own `nobara-repos` package already owns and permanently claims
# /etc/yum.repos.d/terra.repo (confirmed live via the exact rpm conflict
# error), pre-enabled with its own gpgkey/metalink - Terra's upstream
# terra-release package installs that exact same path, so it will ALWAYS
# conflict here and must never be installed on Nobara. If the file is
# missing (e.g. manually deleted at some point, also confirmed live),
# restore it by reinstalling nobara-repos, not by installing terra-release.
# For non-Nobara Fedora-family systems without nobara-repos, fall back to
# the upstream bootstrap.
log "Installing workstation tools (Ghostty, Zed, Go)..."
if [[ ! -f /etc/yum.repos.d/terra.repo ]]; then
  if rpm -q nobara-repos &>/dev/null; then
    log "Restoring Nobara's own terra.repo (owned by nobara-repos)..."
    sudo dnf reinstall -y nobara-repos
  else
    sudo dnf install -y --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" terra-release
  fi
fi
# spotify-launcher (also from Terra) is a small client that fetches Spotify's
# official package itself on first run, since Spotify isn't in Fedora's repos.
# discord is also packaged in Terra (Fedora's own repos can't ship it).
sudo dnf install -y ghostty zed golang spotify-launcher discord

# The shared zsh config (common/.config/zsh) assumes these exist: fzf (+ fzf-tab),
# zoxide (`z`/`j`), fd (fzf file source), bat (previews), fastfetch (runs at shell
# start). illogical-impulse only brings eza/starship (via its COPRs), not these.
sudo dnf install -y fzf zoxide fd-find bat fastfetch jq
for pkg in fzf zoxide fd-find bat fastfetch jq; do
  rpm -q "$pkg" &>/dev/null || log "WARNING: $pkg not installed - the zsh config expects it."
done

if ! rpm -q ghostty &>/dev/null || ! rpm -q zed &>/dev/null || ! rpm -q spotify-launcher &>/dev/null || ! rpm -q discord &>/dev/null; then
  log "WARNING: ghostty, zed, spotify-launcher and/or discord still not installed - check 'cat /etc/yum.repos.d/terra.repo' and 'dnf search ghostty zed' by hand."
fi

# Proton Pass CLI (Arch gets it from the AUR, macOS from Homebrew). No Fedora
# package exists; Proton's own installer is the documented route - it drops
# pass-cli in ~/.local/bin (no sudo), verifies a SHA256, and needs curl + jq.
if [[ ! -x "$HOME/.local/bin/pass-cli" ]]; then
  log "Installing Proton Pass CLI..."
  curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
fi

# Brave Origin (Arch: brave-origin-bin from the AUR, then set as default browser).
# It isn't in Brave's dnf repo (that only carries brave-browser); stable Origin
# RPMs are published on the brave-browser GitHub releases, so pick the newest
# non-prerelease one. Two checks before installing: the published SHA256 must
# match (hard fail), and dnf must verify the RPM's own signature against Brave's
# key (localpkg_gpgcheck; unset by default for local files). Either failing skips
# Brave with a warning instead of aborting the rest of the script.
if ! rpm -q brave-origin &>/dev/null; then
  log "Installing Brave Origin..."
  brave_tmp="$(mktemp -d)"
  brave_url="$(curl -fsSL 'https://api.github.com/repos/brave/brave-browser/releases?per_page=100' \
    | jq -r '[.[] | select(.prerelease==false) | .assets[] | select(.name | test("^brave-origin-[0-9.]+-1\\.x86_64\\.rpm$")) | .browser_download_url][0] // empty')"
  if [[ -z "$brave_url" ]]; then
    log "WARNING: couldn't find a stable Brave Origin RPM on GitHub - skipping Brave."
  elif curl -fsSL -o "$brave_tmp/brave-origin.rpm" "$brave_url" \
      && curl -fsSL -o "$brave_tmp/brave-origin.sha256" "$brave_url.sha256" \
      && [[ "$(sha256sum "$brave_tmp/brave-origin.rpm" | awk '{print $1}')" == "$(awk '{print $1}' "$brave_tmp/brave-origin.sha256")" ]]; then
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf install -y --setopt=localpkg_gpgcheck=1 "$brave_tmp/brave-origin.rpm" \
      || log "WARNING: Brave Origin failed its signature check or install - skipped."
  else
    log "WARNING: Brave Origin download or SHA256 check failed - skipped."
  fi
  rm -rf "$brave_tmp"
fi

# The RPM ships two desktop files; brave-origin.desktop is the one Arch's package
# uses too. Guarded so a skipped install doesn't try to make a missing app default.
if [[ -f /usr/share/applications/brave-origin.desktop ]]; then
  log "Setting Brave Origin as the default browser..."
  xdg-settings set default-web-browser brave-origin.desktop \
    || log "WARNING: xdg-settings couldn't set the default browser (no desktop session?)."
fi

# mise (https://mise.jdx.dev) manages dev tool versions instead of relying on
# whatever's frozen in Fedora's repos - matches Omarchy's own approach on the
# Arch side, which mise-manages its coding-agent CLI stubs the same way (see
# manual/17-ai.md in the omarchy repo). Covers neovim, tmux, and node
# (Vue/Nuxt work) - all present in mise's registry under their plain names.
if [[ ! -x "$HOME/.local/bin/mise" ]]; then
  log "Installing mise..."
  curl https://mise.run | sh
fi
log "Installing neovim, tmux, and node via mise..."
"$HOME/.local/bin/mise" use --global neovim tmux node

# claude-code is a separate call from the group above: its exact registry
# short name is less certain than neovim/tmux/node (only cross-checked
# against the registry site's search, not a live `mise registry` listing),
# and mise's failure mode for one bad name in a multi-tool `use` call isn't
# verified either - keeping it isolated means a wrong name here can't take
# neovim/tmux/node down with it.
log "Installing Claude Code CLI via mise..."
if ! "$HOME/.local/bin/mise" use --global claude-code; then
  log "WARNING: 'mise use --global claude-code' failed - run 'mise registry | grep -i claude' by hand to find the right name."
fi

log "Symlinking Nobara-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

# Proton Pass SSH agent (SSH_AUTH_SOCK already points at its socket via the
# shared .zshenv). The unit logs in with a personal access token read from
# ~/.config/proton-pass-cli/pat - a secret, so this script can't create it:
# enable the unit always, but only start it once that file exists (a start
# without it fails ExecStartPre, which would abort this script under set -e).
mkdir -p -m 700 "$HOME/.ssh"
if systemctl --user enable proton-pass-agent.service; then
  if [[ -f "$HOME/.config/proton-pass-cli/pat" ]]; then
    log "Starting the Proton Pass SSH agent..."
    systemctl --user restart proton-pass-agent.service || log "WARNING: proton-pass-agent failed to start - check: journalctl --user -u proton-pass-agent"
  else
    log "Proton Pass agent enabled but NOT started: put your personal access token in ~/.config/proton-pass-cli/pat (same as on Arch), then run: systemctl --user start proton-pass-agent.service"
  fi
else
  log "WARNING: could not enable proton-pass-agent (no user systemd session?) - run: systemctl --user enable --now proton-pass-agent.service from a desktop session."
fi

mkdir -p "$(dirname "$END4_PC_DIR")"
if [[ -d "$END4_PC_DIR/.git" ]]; then
  log "Updating end4-pC..."
  git -C "$END4_PC_DIR" pull
else
  log "Cloning end4-pC..."
  git clone "$END4_PC_REPO" "$END4_PC_DIR"
fi

VARIABLES_LUA="$HOME/.config/hypr/hyprland/variables.lua"
if [[ -f "$VARIABLES_LUA" ]] && grep -q 'hl\.env("qsConfig", "ii")' "$VARIABLES_LUA"; then
  log "Setting end4-pC as the default Quickshell config..."
  sed -i 's/hl\.env("qsConfig", "ii")/hl.env("qsConfig", "end4-pC")/' "$VARIABLES_LUA"
fi

# apps.terminal drives the launcher's "run in terminal" and "sudo <cmd>"
# actions (services/LauncherSearch.qml in end4-pC/illogical-impulse).
# Reverted back to the upstream default (kitty -1) after trying Ghostty as
# default - Ghostty stays installed and available, just not the default.
# appearance.wallpaperTheming.enableTerminal stays on regardless of which
# terminal is default: it's the generic live-OSC-theming toggle
# (scripts/colors/applycolor.sh's apply_term(), which handles kitty and any
# other open terminal), not something specific to either terminal.
SHELL_CONFIG="$HOME/.config/illogical-impulse/config.json"
if [[ -f "$SHELL_CONFIG" ]]; then
  log "Reverting the launcher's terminal app to kitty, keeping live terminal theming on..."
  sudo dnf install -y jq
  jq '.apps.terminal = "kitty -1" | .appearance.wallpaperTheming.enableTerminal = true' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp" && mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"
else
  log "illogical-impulse config.json not found yet (created on first Quickshell launch) - skipping apps.terminal/terminal theming, rerun this script after logging into Hyprland once."
fi

# illogical-impulse's kitty.conf sets `shell fish`, so kitty windows open fish and
# never load this repo's zsh config (aliases, prompt, fzf-tab...). zsh is the
# login shell here (chsh above), so point kitty at it. Patched in place rather
# than replacing the file, so ii's keybinds and theme include stay intact;
# --follow-symlinks in case ii links it instead of copying. Only affects
# NEW kitty windows.
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
if [[ -f "$KITTY_CONF" ]] && grep -q '^shell fish' "$KITTY_CONF"; then
  log "Pointing kitty at zsh instead of fish so the zsh aliases/prompt load..."
  sed -i --follow-symlinks 's/^shell fish$/shell zsh/' "$KITTY_CONF"
fi

# Custom Hyprland overrides, in the "custom" folder illogical-impulse's own
# hyprland.lua sources on top of its defaults (dotfiles-update-friendly -
# survives ./setup install / exp-update reruns, unlike editing the upstream
# files directly): pt keyboard layout. (SUPER+Return's `terminal` var
# override was removed here too - its upstream default fallback chain
# already resolves to kitty since foot isn't installed, so no override is
# needed to get kitty back.)
HYPR_CUSTOM_DIR="$HOME/.config/hypr/custom"
mkdir -p "$HYPR_CUSTOM_DIR"

CUSTOM_VARIABLES_LUA="$HYPR_CUSTOM_DIR/variables.lua"
if [[ -f "$CUSTOM_VARIABLES_LUA" ]] && grep -q '^terminal = "ghostty"$' "$CUSTOM_VARIABLES_LUA"; then
  log "Removing the SUPER+Return terminal override (reverting to the upstream default, kitty)..."
  sed -i '/^terminal = "ghostty"$/d' "$CUSTOM_VARIABLES_LUA"
fi

# SUPER+W runs illogical-impulse's `browser` variable, whose fallback chain lists
# 'brave' but not Origin's binary (brave-origin-stable in its RPM), so override it.
if [[ -x /usr/bin/brave-origin-stable ]]; then
  if [[ -f "$CUSTOM_VARIABLES_LUA" ]] && grep -q '^browser = ' "$CUSTOM_VARIABLES_LUA"; then
    sed -i 's|^browser = .*|browser = "brave-origin-stable"|' "$CUSTOM_VARIABLES_LUA"
  elif [[ -f "$CUSTOM_VARIABLES_LUA" ]]; then
    echo 'browser = "brave-origin-stable"' >> "$CUSTOM_VARIABLES_LUA"
  else
    log "Setting Brave Origin as the SUPER+W browser..."
    printf -- '-- Personal Hyprland variable overrides (see ~/.config/hypr/hyprland/variables.lua for defaults)\nbrowser = "brave-origin-stable"\n' > "$CUSTOM_VARIABLES_LUA"
  fi
fi

CUSTOM_GENERAL_LUA="$HYPR_CUSTOM_DIR/general.lua"
if [[ ! -f "$CUSTOM_GENERAL_LUA" ]] || ! grep -q 'kb_layout' "$CUSTOM_GENERAL_LUA"; then
  log "Setting keyboard layout to pt..."
  cat >> "$CUSTOM_GENERAL_LUA" <<'EOF'
hl.config({
    input = {
        kb_layout = "pt"
    }
})
EOF
fi

# Only relaunch Quickshell if we're actually inside a Hyprland session
# ($HYPRLAND_INSTANCE_SIGNATURE is set by Hyprland for every process it spawns).
# Quickshell speaks Wayland's layer-shell protocol, which KDE's compositor
# (KWin) also implements - running this unconditionally from a KDE session
# (Nobara's default) would render end4-pC's bar as a floating overlay on top
# of a live KDE desktop, with none of Hyprland's own behavior actually running.
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  log "Reloading Hyprland (picks up the custom terminal/keyboard overrides)..."
  hyprctl reload
  log "(Re)starting Quickshell with end4-pC..."
  killall qs 2>/dev/null || true
  qs -c end4-pC > /dev/null 2>&1 & disown
else
  log "Not in a Hyprland session - skipping Hyprland reload/Quickshell relaunch. Log out and pick 'Hyprland' at the SDDM login screen to use it."
fi

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../../common/install.sh"
