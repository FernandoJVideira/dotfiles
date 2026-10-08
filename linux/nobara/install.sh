#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"

# Install zsh and set it as the default shell (mirrors linux/arch/install.sh)
log "Installing zsh..."
sudo dnf install -y zsh
sudo chsh -s "$(which zsh)" "$USER"

log "Installing git..."
sudo dnf install -y git

# Omadora (my fork, nobara branch) provides the Hyprland session, the Quickshell
# shell and their packages. It goes in before the dotfiles are symlinked so my
# own configs win over its defaults. HTTPS, since a fresh machine has no SSH key
# yet. A first install runs its installer; an existing checkout is only fast-
# forwarded (update it afterwards with `omactl update`).
OMADORA_DIR="$HOME/.local/share/omadora"
OMADORA_REPO_URL="${OMADORA_REPO_URL:-https://github.com/FernandoJVideira/omadora.git}"
OMADORA_REF="${OMADORA_REF:-nobara}"
if [[ -d "$OMADORA_DIR/.git" ]]; then
  log "Updating Omadora..."
  git -C "$OMADORA_DIR" pull --ff-only \
    || log "WARNING: couldn't fast-forward Omadora - resolve it in $OMADORA_DIR by hand."
else
  log "Cloning Omadora ($OMADORA_REF)..."
  mkdir -p "$(dirname "$OMADORA_DIR")"
  git clone --branch "$OMADORA_REF" "$OMADORA_REPO_URL" "$OMADORA_DIR"
  log "Running the Omadora installer..."
  bash "$OMADORA_DIR/install.sh"
fi

# Hyprland + quickshell runtime deps, dnf side. UNTESTED - no Fedora/Nobara
# box was available while writing this; treat every package name here as a
# starting point to debug with `dnf search`, not a known-good list. Some of
# these (quickshell, gum, hyprpicker, the nerd-fonts package) may need a COPR
# repo that isn't identified yet.
log "Installing Hyprland and quickshell runtime dependencies..."
sudo dnf install -y --skip-unavailable \
  hyprland quickshell xdg-desktop-portal-hyprland \
  wireplumber pipewire gnome-keyring jq gum wl-clipboard slurp hyprpicker \
  wtype brightnessctl bluez networkmanager qrencode libnotify \
  jetbrains-mono-nerd-fonts
for pkg in hyprland quickshell xdg-desktop-portal-hyprland wl-clipboard slurp hyprpicker; do
  rpm -q "$pkg" &>/dev/null || log "WARNING: $pkg not installed - check for a COPR."
done

log "Symlinking Nobara-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

# NVIDIA-only extras live in a sibling tree so an AMD/Intel machine never gets
# them. nvidia-settings-load needs an X server and fails on every Wayland login.
if lspci 2>/dev/null | grep -E "VGA|3D|Display" | grep -qi nvidia || [[ -d /proc/driver/nvidia ]]; then
  log "NVIDIA GPU detected - symlinking NVIDIA-specific dotfiles..."
  symlink_dotfiles "$SCRIPT_DIR/../nobara-nvidia"
fi

# Install workstation tools (mirrors linux/arch/install.sh's "go
# element-desktop" + zed; Ghostty is deliberately not installed here - kitty is
# the terminal on this machine). go is in Fedora's own repos; Zed isn't - its
# project docs point at the Terra repo for Fedora.
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
log "Installing workstation tools (Zed, Go)..."
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
sudo dnf install -y --skip-unavailable zed golang spotify-launcher discord

# The shared zsh config (common/.config/zsh) assumes these exist: fzf (+ fzf-tab),
# zoxide (`z`/`j`), fd (fzf file source), bat (previews), fastfetch (runs at shell
# start).
sudo dnf install -y --skip-unavailable gh   # GitHub CLI, in Fedora's own repos
rpm -q gh &>/dev/null || log "WARNING: gh not installed."

# Crash watcher deps too: libnotify (notify-send), gdb (backtraces for the
# diagnose-crash skill). There's no systemd-coredump package on current Fedora -
# it was folded into `systemd` itself (confirmed live: dnf reports "No match for
# argument"). dnf5 aborts the WHOLE transaction on an unavailable name unless
# --skip-unavailable is given, so use it: one bad name then just warns below
# instead of taking every other package (and this script, under set -e) with it.
sudo dnf install -y --skip-unavailable fzf zoxide fd-find bat fastfetch jq libnotify gdb
for pkg in fzf zoxide fd-find bat fastfetch jq libnotify gdb; do
  rpm -q "$pkg" &>/dev/null || log "WARNING: $pkg not installed - the zsh config expects it."
done

if ! rpm -q zed &>/dev/null || ! rpm -q spotify-launcher &>/dev/null || ! rpm -q discord &>/dev/null; then
  log "WARNING: zed, spotify-launcher and/or discord still not installed - check 'cat /etc/yum.repos.d/terra.repo' and 'dnf search zed' by hand."
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
# Arch side. Covers neovim, tmux, and node (Vue/Nuxt work) - all present in
# mise's registry under their plain names.
if [[ ! -x "$HOME/.local/bin/mise" ]]; then
  log "Installing mise..."
  curl https://mise.run | sh
fi
log "Installing neovim, tmux, and node via mise..."
"$HOME/.local/bin/mise" use --global neovim tmux node

# claude-code is a separate call from the group above: its exact registry
# short name is less certain than neovim/tmux/node, and mise's failure mode
# for one bad name in a multi-tool `use` call isn't verified either - keeping
# it isolated means a wrong name here can't take neovim/tmux/node down with it.
log "Installing Claude Code CLI via mise..."
if ! "$HOME/.local/bin/mise" use --global claude-code; then
  log "WARNING: 'mise use --global claude-code' failed - run 'mise registry | grep -i claude' by hand to find the right name."
fi

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

# Crash watcher: follows systemd-coredump entries in the journal and pops a
# "Process crashed" notification with a "Diagnose with Claude" action. The
# scripts in ~/.local/bin and the unit were just symlinked above. Reading the
# system journal needs wheel/adm/systemd-journal - the service would
# otherwise fail in a retry loop.
if ! command -v coredumpctl >/dev/null || ! grep -q systemd-coredump /proc/sys/kernel/core_pattern; then
  log "WARNING: systemd-coredump doesn't look active (coredumpctl missing or kernel.core_pattern doesn't pipe to it) - the crash watcher will have nothing to report."
fi
if ! id -nG | tr ' ' '\n' | grep -qxE 'wheel|adm|systemd-journal'; then
  log "WARNING: $USER isn't in wheel/adm/systemd-journal, so the crash watcher can't read the journal - run: sudo usermod -aG systemd-journal $USER (then log out and in)."
fi
if systemctl --user enable --now crash-watch.service; then
  log "Crash watcher running (mute a program with: nobara-crash-mute <program>)."
else
  log "WARNING: could not enable crash-watch (no user systemd session?) - run: systemctl --user enable --now crash-watch.service from a desktop session."
fi

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../../common/install.sh"

# Themed starship prompt: needs the shared symlinks (script + template) from above
log "Rendering the starship prompt for the current theme..."
"$HOME/.local/bin/starship-theme-sync" || log "WARNING: starship-theme-sync failed - the prompt keeps its static colors."
