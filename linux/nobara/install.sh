#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"
source "$SCRIPT_DIR/../../lib/monitors.sh"

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
export OMADORA_PATH="$OMADORA_DIR"
export PATH="$OMADORA_DIR/bin:$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

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
  jetbrains-mono-nerd-fonts hack-nerd-fonts
for pkg in hyprland quickshell xdg-desktop-portal-hyprland wl-clipboard slurp hyprpicker hack-nerd-fonts; do
  rpm -q "$pkg" &>/dev/null || log "WARNING: $pkg not installed - check for a COPR."
done

log "Symlinking Nobara-specific dotfiles..."
symlink_dotfiles "$SCRIPT_DIR"

# Monitor layout: the fastest monitor becomes the primary at 0x0, the rest chain
# to its right. Written into the (symlinked) monitors.lua and into the plasmalogin
# login screen. Needs a running Hyprland to read the mode lists, so on a first
# install from a TTY it is skipped - re-run this script from the desktop.
log "Detecting monitors..."
MONITORS="$(detect_monitors || true)"
sync_hypr_monitors "$SCRIPT_DIR/.config/hypr/monitors.lua" "$MONITORS" || true
sync_plasmalogin_monitors "$MONITORS" || true

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

# Helium (browser) comes from Nobara's own repo. Steam and Heroic are in Terra;
# they're only installed when you say yes, same as the gaming prompt on Arch.
sudo dnf install -y --skip-unavailable helium-bin
if command -v gum >/dev/null && gum confirm "Set up gaming tools too (Steam, Heroic)?"; then
  log "Installing gaming tools..."
  sudo dnf install -y --skip-unavailable steam heroic-games-launcher
fi

# Flatpak apps (no rpm for these): LocalSend and GPU Screen Recorder. Nobara can have
# flathub configured in both the system and user scopes, which makes a bare
# `flatpak install flathub ...` refuse to run non-interactively, so say --system.
log "Installing Flatpak apps (LocalSend, GPU Screen Recorder)..."
sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
  && sudo flatpak install --system -y --noninteractive flathub org.localsend.localsend_app com.dec05eba.gpu_screen_recorder \
  || log "WARNING: Flatpak apps failed to install - run: sudo flatpak install --system flathub org.localsend.localsend_app com.dec05eba.gpu_screen_recorder"

# OpenDeck (Stream Deck controller; the AUR package on Arch). Upstream's own
# installer picks the .rpm from GitHub Releases on Fedora-family systems and
# installs the udev rules. It asks a few questions (Wine, Node.js, launch) on
# /dev/tty, so this step is interactive. Skipped once opendeck is installed.
if ! command -v opendeck >/dev/null; then
  log "Installing OpenDeck..."
  curl -sSL https://raw.githubusercontent.com/nekename/OpenDeck/main/install_opendeck.sh | bash \
    || log "WARNING: OpenDeck install failed - re-run: curl -sSL https://raw.githubusercontent.com/nekename/OpenDeck/main/install_opendeck.sh | bash"
fi

# The shared zsh config (common/.config/zsh) assumes these exist: fzf (+ fzf-tab),
# zoxide (`z`/`j`), fd (fzf file source), bat (previews), fastfetch (runs at shell
# start).
sudo dnf install -y --skip-unavailable gh   # GitHub CLI, in Fedora's own repos
rpm -q gh &>/dev/null || log "WARNING: gh not installed."

# .NET SDK (Fedora's own repos): Zed's C# extension; the macOS Brewfile has the dotnet-sdk cask
sudo dnf install -y --skip-unavailable dotnet-sdk-10.0
rpm -q dotnet-sdk-10.0 &>/dev/null || log "WARNING: dotnet-sdk-10.0 not installed - check 'dnf search dotnet-sdk'."

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
# Arch side. Covers neovim, tmux, node and pnpm (Vue/Nuxt work) - all present in
# mise's registry under their plain names.
if [[ ! -x "$HOME/.local/bin/mise" ]]; then
  log "Installing mise..."
  curl https://mise.run | sh
fi
log "Installing neovim, tmux, node, and pnpm via mise..."
"$HOME/.local/bin/mise" use --global neovim tmux node pnpm

# claude-code is a separate call from the group above: its exact registry
# short name is less certain than neovim/tmux/node, and mise's failure mode
# for one bad name in a multi-tool `use` call isn't verified either - keeping
# it isolated means a wrong name here can't take neovim/tmux/node down with it.
log "Installing Claude Code CLI via mise..."
if ! "$HOME/.local/bin/mise" use --global claude-code; then
  log "WARNING: 'mise use --global claude-code' failed - run 'mise registry | grep -i claude' by hand to find the right name."
fi

# Herdr (terminal multiplexer for coding agents): `hdev` opens a project as Neovim + Claude Code in it
log "Installing Herdr via mise..."
if ! "$HOME/.local/bin/mise" use --global herdr; then
  log "WARNING: 'mise use --global herdr' failed - run 'mise registry | grep -i herdr' by hand to find the right name."
fi

# Bootloader: BIOS+GRUB -> UEFI+Limine (see linux/nobara-boot/limine-migrate.sh). `auto` picks
# whichever phase applies: phase 1 repartitions the boot disk (asks you to type YES first),
# phase 2 runs after you've switched the firmware to UEFI and booted Limine. On an already
# migrated machine it just refreshes the menu theme and the kernel hook. A failure here
# never aborts the rest of the install.
log "Setting up the Limine bootloader..."
sudo dnf install -y --skip-unavailable gdisk dosfstools rsync efibootmgr limine
sudo "$SCRIPT_DIR/../nobara-boot/limine-migrate.sh" auto \
  || log "WARNING: limine-migrate.sh auto failed - run it by hand: sudo linux/nobara-boot/limine-migrate.sh prepare|finish"

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

# Omadora preferences: Claude as the default agent and the idle
# screensaver off. Both are plain state files; omadora-default-agent would also
# launch the agent, and `omactl toggle screensaver` flips instead of setting.
log "Applying Omadora preferences..."
mkdir -p "$HOME/.config/omadora/defaults" "$HOME/.local/state/omadora/toggles"
echo claude >"$HOME/.config/omadora/defaults/agent"
touch "$HOME/.local/state/omadora/toggles/screensaver-off"
# The matte-black theme is re-applied so kitty's and starship's themed files exist.
theme="$(cat "$HOME/.config/omadora/current/theme.name" 2>/dev/null || echo matte-black)"
# First run only: start from matte-black instead of Omadora's own default theme; later
# runs keep whatever theme was picked since.
theme_marker="$HOME/.local/state/dotfiles/theme-initialised"
if [[ ! -f "$theme_marker" ]]; then
  theme=matte-black
  mkdir -p "$(dirname "$theme_marker")" && touch "$theme_marker"
fi
omactl theme set "$theme" \
  || log "WARNING: theme re-apply failed - run: omactl theme set matte-black from the desktop."

# Themed starship prompt: needs the shared symlinks (script + template) from above
log "Rendering the starship prompt for the current theme..."
"$HOME/.local/bin/starship-theme-sync" || log "WARNING: starship-theme-sync failed - the prompt keeps its static colors."

# Zed's theme follows the OS theme too (same shared-symlinks dependency)
log "Rendering the Zed theme for the current theme..."
"$HOME/.local/bin/zed-theme-sync" || log "WARNING: zed-theme-sync failed - Zed has no 'Desktop Theme' until the next theme change."
log "Zed installs its extensions (settings.json) the first time it starts - run zed-extensions-check afterwards to confirm."
