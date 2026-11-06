#!/usr/bin/env bash
# Plain Fedora (44+). Starting point: a minimal/core install, a user with sudo, network.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/symlink.sh"
source "$SCRIPT_DIR/../../lib/log.sh"
source "$SCRIPT_DIR/../../lib/skein.sh"
source "$SCRIPT_DIR/../../lib/monitors.sh"
source "$SCRIPT_DIR/../../lib/secrets.sh"
source "$SCRIPT_DIR/../../lib/profile.sh"
source "$SCRIPT_DIR/../../lib/static-theme.sh"
source "$SCRIPT_DIR/../../lib/grub.sh"
source "$SCRIPT_DIR/../../lib/fedora-gaming.sh"
source "$SCRIPT_DIR/../../lib/fedora-eac.sh"

# Skein or apps only; bootstrap.sh asks, a direct run reuses the saved choice
resolve_profile

# Install zsh and set it as the default shell (mirrors linux/arch/install.sh)
log "Installing zsh..."
sudo dnf install -y zsh
sudo chsh -s "$(command -v zsh)" "$USER"

log "Installing git..."
sudo dnf install -y git

# RPM Fusion and the other third-party repos must be in before any desktop tool (mpv needs RPM Fusion).
fedora_repos_setup

# Skein (my fork, nobara branch) provides the Hyprland session, the Quickshell
# shell and their packages. It goes in before the dotfiles are symlinked so my
# own configs win over its defaults. HTTPS, since a fresh machine has no SSH key
# yet. A first install runs its installer; an existing checkout is only fast-
# forwarded (update it afterwards with `skeinctl update`).
if ! is_apps_profile; then
  SKEIN_DIR="$HOME/.local/share/skein"
  SKEIN_REPO_URL="${SKEIN_REPO_URL:-https://github.com/FernandoJVideira/skein.git}"
  # the fork's "nobara" branch carries all my work and installs on plain Fedora too (rename pending)
  SKEIN_REF="${SKEIN_REF:-nobara}"
  # a machine that still has Omadora's checkout: move it to Skein's name and ref first
  migrate_skein_checkout "$SKEIN_DIR" "$SKEIN_REPO_URL" "$SKEIN_REF"
  if [[ -d "$SKEIN_DIR/.git" ]]; then
    log "Updating Skein..."
    git -C "$SKEIN_DIR" pull --ff-only \
      || log "WARNING: couldn't fast-forward Skein - resolve it in $SKEIN_DIR by hand."
  else
    log "Cloning Skein ($SKEIN_REF)..."
    mkdir -p "$(dirname "$SKEIN_DIR")"
    git clone --branch "$SKEIN_REF" "$SKEIN_REPO_URL" "$SKEIN_DIR"
    log "Running the Skein installer..."
    # The dotfiles installer finishes the setup, so Skein must not reboot the machine mid-run.
    export SKEIN_NO_REBOOT=1
    bash "$SKEIN_DIR/install.sh"
  fi
  # config, state and cache directories, and the old user units (before the dotfiles are linked into them)
  "$SKEIN_DIR/libexec/skein-migrate-names" || log "WARNING: skein-migrate-names failed - see above."
  export SKEIN_PATH="$SKEIN_DIR"
else
  log "Apps profile: skipping Skein."
fi
if is_apps_profile; then
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
else
  export PATH="$SKEIN_DIR/bin:$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
fi

# Terra (Zed, Discord, Spotify, Helium, nerd fonts, gaming tools) must be in before the dependency installs below (the nerd fonts come from it).
if [[ ! -f /etc/yum.repos.d/terra.repo ]]; then
  sudo dnf install -y --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" terra-release
fi

# Hyprland + quickshell runtime deps, dnf side. UNTESTED - no Fedora
# box was available while writing this; treat every package name here as a
# starting point to debug with `dnf search`, not a known-good list. Some of
# these (quickshell, gum, hyprpicker, the nerd-fonts package) may need a COPR
# repo that isn't identified yet.
if ! is_apps_profile; then
  log "Installing Hyprland and quickshell runtime dependencies..."
  sudo dnf install -y --skip-unavailable \
    hyprland quickshell xdg-desktop-portal-hyprland slurp hyprpicker wtype brightnessctl \
    wireplumber pipewire gnome-keyring gnome-keyring-pam bluez networkmanager qrencode
else
  log "Apps profile: skipping the Hyprland and Quickshell desktop packages."
fi
log "Installing the generic runtime tools..."
sudo dnf install -y --skip-unavailable jq gum wl-clipboard libnotify libwebp-tools jetbrainsmono-nerd-fonts hack-nerd-fonts
if ! is_apps_profile; then
  for pkg in hyprland quickshell xdg-desktop-portal-hyprland slurp hyprpicker gnome-keyring-pam; do
    rpm -q "$pkg" &>/dev/null || log "WARNING: $pkg not installed - check for a COPR."
  done
fi
for pkg in wl-clipboard hack-nerd-fonts; do
  rpm -q "$pkg" &>/dev/null || log "WARNING: $pkg not installed - check for a COPR."
done

log "Symlinking Fedora-specific dotfiles..."
# the apps profile leaves out the Hyprland and Skein parts
distro_excl=()
common_excl=()
if is_apps_profile; then
  distro_excl=(.config/hypr .config/skein .config/systemd/user/hyprland-session.target .config/xdg-terminals.list)
  common_excl=(.config/hypr .config/skein .local/bin/capslock-mode .config/fontconfig)
fi
symlink_dotfiles "$SCRIPT_DIR" "${distro_excl[@]}"
# what both Linux distros share (Caps Lock as Super, see linux/common/.config/hypr/capslock.lua)
symlink_dotfiles "$SCRIPT_DIR/../common" "${common_excl[@]}"

# Monitor layout: the fastest monitor becomes the primary at 0x0, the rest chain
# to its right. Written into the (symlinked) monitors.lua. Needs a running Hyprland to read the mode lists, so on a first
# install from a TTY it is skipped - re-run this script from the desktop.
if ! is_apps_profile; then
  log "Detecting monitors..."
  MONITORS="$(detect_monitors || true)"
  sync_hypr_monitors "$SCRIPT_DIR/.config/hypr/monitors.lua" "$MONITORS" || true
else
  log "Apps profile: skipping the monitor layout."
fi

# NVIDIA-only extras live in a sibling tree so an AMD/Intel machine never gets
# them. nvidia-settings-load needs an X server and fails on every Wayland login.
if lspci 2>/dev/null | grep -E "VGA|3D|Display" | grep -qi nvidia || [[ -d /proc/driver/nvidia ]]; then
  log "NVIDIA GPU detected - symlinking NVIDIA-specific dotfiles..."
  symlink_dotfiles "$SCRIPT_DIR/../fedora-nvidia"
fi

# The login screen lives in Skein (libexec/skein-greeter). The Skein installer sets it up on a first
# install; this covers a machine that already had Skein.
if ! is_apps_profile; then
  if [[ ! -f /usr/local/share/skein-greeter/shell.qml ]]; then
    log "Installing the Quickshell login screen..."
    "$SKEIN_DIR/libexec/skein-greeter" install \
      || log "WARNING: the greeter didn't install - run: skein-greeter install"
  fi
else
  log "Apps profile: skipping the login screen."
fi
# links from when these two lived in this repo
for stale in "$HOME/.local/bin/greeter-theme-sync" "$HOME/.config/skein/hooks/theme-set.d/greeter-sync"; do
  [[ -L $stale ]] && rm -f "$stale"
done

# Install workstation tools (mirrors linux/arch/install.sh's "go
# element-desktop" + zed; Ghostty is deliberately not installed here - kitty is
# the terminal on this machine). go is in Fedora's own repos; Zed isn't - its
# project docs point at the Terra repo for Fedora.
log "Installing workstation tools (Zed)..."
# spotify-launcher (also from Terra) is a small client that fetches Spotify's
# official package itself on first run, since Spotify isn't in Fedora's repos.
# discord is also packaged in Terra (Fedora's own repos can't ship it).
sudo dnf install -y --skip-unavailable zed spotify-launcher discord

# Helium (browser). Not in every repo set, so a miss only warns.
sudo dnf install -y --skip-unavailable helium-browser-bin
rpm -q helium-browser-bin &>/dev/null || log "WARNING: helium-browser-bin not installed - check the repos for it."
# Gaming (Steam, Heroic, ...) and the NVIDIA driver each ask and handle their own warnings.
fedora_gaming_setup
fedora_nvidia_setup

# Flatpak apps (no rpm for these): LocalSend, GPU Screen Recorder, OnlyOffice and Obsidian (the Brain vault, docs/brain.md). A box can have
# flathub configured in both the system and user scopes, which makes a bare
# `flatpak install flathub ...` refuse to run non-interactively, so say --system.
log "Installing Flatpak apps (LocalSend, GPU Screen Recorder, OnlyOffice, Obsidian)..."
sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
  && sudo flatpak install --system -y --noninteractive flathub org.localsend.localsend_app com.dec05eba.gpu_screen_recorder org.onlyoffice.desktopeditors md.obsidian.Obsidian \
  || log "WARNING: Flatpak apps failed to install - run: sudo flatpak install --system flathub org.localsend.localsend_app com.dec05eba.gpu_screen_recorder org.onlyoffice.desktopeditors md.obsidian.Obsidian"

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
# start). Crash watcher deps too: libnotify (notify-send), gdb (backtraces for the
# diagnose-crash skill). There's no systemd-coredump package on current Fedora -
# it was folded into `systemd` itself (confirmed live: dnf reports "No match for
# argument"). dnf5 aborts the WHOLE transaction on an unavailable name unless
# --skip-unavailable is given, so use it: one bad name then just warns below
# instead of taking every other package (and this script, under set -e) with it.
sudo dnf install -y --skip-unavailable fzf zoxide fd-find bat fastfetch jq libnotify gdb ShellCheck
for pkg in fzf zoxide fd-find bat fastfetch jq libnotify gdb ShellCheck; do
  rpm -q "$pkg" &>/dev/null || log "WARNING: $pkg not installed - the zsh config expects it."
done

if ! rpm -q zed &>/dev/null || ! rpm -q spotify-launcher &>/dev/null || ! rpm -q discord &>/dev/null; then
  log "WARNING: zed, spotify-launcher and/or discord still not installed - check 'cat /etc/yum.repos.d/terra.repo' and 'dnf search zed' by hand."
fi

# ani-cli: not in Fedora's or Terra's repos, so the COPR its README points at (builds for Fedora 43
# to 45). It plays with mpv, which comes from RPM Fusion free (fedora_repos_setup).
if ! rpm -q ani-cli &>/dev/null; then
  log "Installing ani-cli and mpv..."
  sudo dnf copr enable -y derisis13/ani-cli \
    && sudo dnf install -y --skip-unavailable mpv ani-cli \
    || log "WARNING: couldn't install ani-cli - check 'dnf copr list' and 'dnf search mpv' (RPM Fusion must be enabled)."
fi

# Cloudflare WARP: no Fedora or Terra package, so Cloudflare's own RPM repo, written the way
# https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo has it (gpgcheck on; dnf imports
# Cloudflare's key from gpgkey on the first install). It serves Fedora 43 and 44 only, so
# skip_if_unavailable keeps a release it doesn't serve from breaking every other dnf run.
# Registering, which asks you to accept Cloudflare's terms, is left to you:
# warp-cli registration new, then warp-cli connect.
if ! rpm -q cloudflare-warp &>/dev/null; then
  log "Installing Cloudflare WARP..."
  sudo tee /etc/yum.repos.d/cloudflare-warp.repo >/dev/null <<'REPO'
[cloudflare-warp-stable]
name=cloudflare-warp-stable
baseurl=https://pkg.cloudflareclient.com/rpm/$releasever
enabled=1
type=rpm
gpgcheck=1
gpgkey=https://pkg.cloudflareclient.com/pubkey.gpg
skip_if_unavailable=True
REPO
  sudo dnf install -y --skip-unavailable cloudflare-warp \
    || log "WARNING: couldn't install Cloudflare WARP - check 'cat /etc/yum.repos.d/cloudflare-warp.repo' and 'dnf search cloudflare-warp'."
fi
if rpm -q cloudflare-warp &>/dev/null; then
  sudo systemctl enable --now warp-svc.service \
    || log "WARNING: couldn't start warp-svc - check: journalctl -u warp-svc"
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
    # brave-origin requires brave-keyring, which only Brave's own repo carries
    [[ -f /etc/yum.repos.d/brave-browser.repo ]] \
      || sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo dnf install -y --setopt=localpkg_gpgcheck=1 "$brave_tmp/brave-origin.rpm" \
      || log "WARNING: Brave Origin failed its signature check or install - skipped."
  else
    log "WARNING: Brave Origin download or SHA256 check failed - skipped."
  fi
  rm -rf "$brave_tmp"
fi

# The RPM ships two desktop files; brave-origin.desktop is the one Arch's package
# uses too. Guarded so a skipped install doesn't try to make a missing app default.
if ! is_apps_profile; then
  if [[ -f /usr/share/applications/brave-origin.desktop ]]; then
    log "Setting Brave Origin as the default browser..."
    xdg-settings set default-web-browser brave-origin.desktop \
      || log "WARNING: xdg-settings couldn't set the default browser (no desktop session?)."
  fi
else
  log "Apps profile: leaving the default browser alone."
fi

# mise (https://mise.jdx.dev) manages the dev tools (Go, Node, Java, .NET, Neovim, Herdr, Claude
# Code...) instead of whatever's frozen in Fedora's repos, matching Omarchy's approach on the Arch
# side. Only mise itself is installed here; common/install.sh installs the tools from the shared
# list in common/.config/mise/conf.d, plus tmux from this OS's own conf.d.
if [[ ! -x "$HOME/.local/bin/mise" ]]; then
  log "Installing mise..."
  curl https://mise.run | sh
fi

# GRUB menu theme (Tokyo Night, same look as the Limine menu on Arch).
if ! is_apps_profile; then
  grub_setup || log "WARNING: GRUB theme setup failed - run grub_setup by hand"
else
  log "Apps profile: skipping the GRUB theme."
fi

# Proton Pass SSH agent (SSH_AUTH_SOCK already points at its socket, set by the zsh startup file
# and by environment.d for the whole session). The unit logs in with a personal access token read from the login keyring
# (secret-tool); a token left in the old ~/.config/proton-pass-cli/pat is moved there. The unit is
# enabled always, but only started once the keyring holds the token (a start without a token fails
# ExecStartPre, which would abort this script under set -e). The instructions are printed at the end.
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
create_secret_templates
if systemctl --user enable proton-pass-agent.service; then
  if pat_ready; then
    log "Starting the Proton Pass SSH agent..."
    systemctl --user restart proton-pass-agent.service || log "WARNING: proton-pass-agent failed to start - check: journalctl --user -u proton-pass-agent"
  else
    log "Proton Pass agent enabled but NOT started: the token is not in the keyring yet (instructions at the end)."
  fi
else
  log "WARNING: could not enable proton-pass-agent (no user systemd session?) - run: systemctl --user enable --now proton-pass-agent.service from a desktop session."
fi

# A second agent serves the "Deploy" vault on its own socket (the vue-ui-kit deploy key); the main
# one serves only "SSH". It needs the token to have access to that vault (docs/guide.md).
if systemctl --user enable proton-pass-deploy-agent.service; then
  if pat_ready; then
    systemctl --user restart proton-pass-deploy-agent.service || log "WARNING: proton-pass-deploy-agent failed to start - check: journalctl --user -u proton-pass-deploy-agent"
  fi
else
  log "WARNING: could not enable proton-pass-deploy-agent (no user systemd session?) - run: systemctl --user enable --now proton-pass-deploy-agent.service from a desktop session."
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
  log "Crash watcher running (mute a program with: crash-mute <program>)."
else
  log "WARNING: could not enable crash-watch (no user systemd session?) - run: systemctl --user enable --now crash-watch.service from a desktop session."
fi

log "Running shared dotfiles installer..."
"$SCRIPT_DIR/../../common/install.sh"

if ! is_apps_profile; then
  # Skein preferences: Claude as the default agent and the idle
  # screensaver off. Both are plain state files; skein-default-agent would also
  # launch the agent, and `skeinctl toggle screensaver` flips instead of setting.
  log "Applying Skein preferences..."
  mkdir -p "$HOME/.config/skein/defaults" "$HOME/.local/state/skein/toggles"
  echo claude >"$HOME/.config/skein/defaults/agent"
  touch "$HOME/.local/state/skein/toggles/screensaver-off"
else
  log "Apps profile: skipping the Skein preferences."
fi

if is_apps_profile; then
  apply_static_theme || log "WARNING: the static theme failed - run: apply_static_theme (lib/static-theme.sh)."
else
  remove_static_theme
  # The matte-black theme is re-applied so kitty's and starship's themed files exist.
  theme="$(cat "$HOME/.config/skein/current/theme.name" 2>/dev/null || echo matte-black)"
  # First run only: start from matte-black instead of Skein's own default theme; later
  # runs keep whatever theme was picked since.
  theme_marker="$HOME/.local/state/dotfiles/theme-initialised"
  if [[ ! -f "$theme_marker" ]]; then
    theme=matte-black
    mkdir -p "$(dirname "$theme_marker")" && touch "$theme_marker"
  fi
  skeinctl theme set "$theme" \
    || log "WARNING: theme re-apply failed - run: skeinctl theme set matte-black from the desktop."

  # Themed starship prompt: needs the shared symlinks (script + template) from above
  log "Rendering the starship prompt for the current theme..."
  "$HOME/.local/bin/starship-theme-sync" || log "WARNING: starship-theme-sync failed - the prompt keeps its static colors."

  # Zed's theme follows the OS theme too (same shared-symlinks dependency)
  log "Rendering the Zed theme for the current theme..."
  "$HOME/.local/bin/zed-theme-sync" || log "WARNING: zed-theme-sync failed - Zed has no 'Desktop Theme' until the next theme change."
fi
log "Zed installs its extensions (settings.json) the first time it starts - run zed-extensions-check afterwards to confirm."

# Easy Anti-Cheat boot entry: enrolls its Secure Boot keys (handles its own prompts and warnings).
fedora_eac_setup
log "Done. Reboot now to finish: pick the login screen session, then confirm the MOK key enrolment."
