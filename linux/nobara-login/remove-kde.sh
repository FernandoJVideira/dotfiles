#!/usr/bin/env bash
# Drop KDE Plasma from Nobara and log in through a Quickshell greeter instead of Plasma Login Manager.
# Opt-in and in two steps, so a bad login screen never costs you the desktop:
#
#   remove-kde.sh greeter    install greetd + cage + the Quickshell greeter and make greetd the login
#                            manager (Plasma Login Manager stays installed, just disabled). Reboot after.
#   remove-kde.sh remove     once you are logged in through greetd: preview, then remove KDE Plasma, its
#                            apps and the default apps Nobara ships. [--kde-only] keeps the other apps.
#   remove-kde.sh rollback   make Plasma Login Manager the login manager again.
#   remove-kde.sh status
#
# Always keeps the Nobara packages (nobara-*), Hyprland and Quickshell, the gaming stack and KWallet
# (Omadora's secret service). dnf is told to protect them and the preview is checked for them too.
# UNTESTED on a live Nobara box: read the dnf preview before typing REMOVE.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/log.sh"

GREETER_DIR=/usr/local/share/dotfiles-greeter
PROTECTED_FILE=/etc/dnf/protected.d/dotfiles-nobara.conf

die() { printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

not_in_plasma() {
  [[ ${XDG_CURRENT_DESKTOP:-} != *KDE* ]] \
    || die "you are in a Plasma session. Log into Omadora (Hyprland) first and run this from there."
}

# Packages to remove, matched against what is installed. Globs allowed.
KDE_PACKAGES=(
  'plasma-*' 'kwin*' 'kscreen*' kscreenlocker kdeplasma-addons kinfocenter kmenuedit khelpcenter
  kde-gtk-config kde-settings-plasma kde-settings-pulseaudio bluedevil 'polkit-kde*' 'kde-connect*'
  'kdeconnect*' kdnssd krdp kio-admin audiocd-kio kde-inotify-survey kdebugsettings kjournald
  kdegraphics-thumbnailers ffmpegthumbs kdenetwork-filesharing 'akonadi*' 'kaccounts-*'
  signon-kwallet-extension kwebkitpart kf6-baloo-file flatpak-kcm colord-kde kde-partitionmanager
  'kwalletmanager*' ksshaskpass
  dolphin 'dolphin-*' konsole kate kwrite okular gwenview ark spectacle kcalc kcharselect kfind
  filelight kdialog elisa-player kdenlive
)
# The default apps of the Nobara KDE image that this setup replaces or doesn't use
# (OnlyOffice for LibreOffice, mpv for VLC, Brave Origin for Brave). Gaming tools stay.
DEFAULT_APPS=(
  'libreoffice*' inkscape blender obs-studio prismlauncher mariadb-server mariadb-embedded
  calamares mediawriter 'vlc*' brave-browser firefox
)
# Never removed: dnf protects them, and a preview that would take one is refused.
KEEP_PACKAGES=(
  'nobara-*' greetd cage 'hyprland*' 'quickshell*' uwsm xfce-polkit NetworkManager 'pipewire*' wireplumber
  sudo systemd 'kernel*' 'dnf*' flatpak kitty zsh git steam lutris 'heroic*' gamescope 'wine*'
  mangohud goverlay protonplus 'umu-launcher' timeshift falcond inputplumber '*kwallet*'
)

installed() { rpm -qa --qf '%{NAME}\n' | sort -u; }

# names from the installed set matching any of the given globs
matching() {
  local name pat
  while IFS= read -r name; do
    for pat in "$@"; do
      # shellcheck disable=SC2053
      [[ $name == $pat ]] && { printf '%s\n' "$name"; break; }
    done
  done < <(installed)
}

# Names of kwalletmanager and signon-kwallet-extension are GUI/Plasma pieces, not the secret service
keep_names() {
  matching "${KEEP_PACKAGES[@]}" | grep -vxE 'kwalletmanager.*|signon-kwallet-extension' || true
}

cmd_status() {
  printf 'display manager: %s\n' "$(systemctl is-enabled display-manager.service 2>/dev/null || echo unknown) ($(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || echo none))"
  for p in greetd cage plasma-login-manager plasma-desktop; do
    printf '%-22s %s\n' "$p" "$(rpm -q "$p" 2>/dev/null | head -n 1)"
  done
  [[ -n ${XDG_SESSION_ID:-} ]] && printf 'this session came from: %s\n' "$(loginctl show-session "$XDG_SESSION_ID" -p Service --value 2>/dev/null)"
  return 0
}

cmd_greeter() {
  not_in_plasma
  log "Installing greetd and cage..."
  sudo dnf install -y greetd cage
  for p in greetd cage quickshell; do rpm -q "$p" &>/dev/null || die "$p is not installed"; done

  log "Installing the Quickshell greeter into $GREETER_DIR..."
  sudo install -d -o "$(id -un)" -g "$(id -gn)" "$GREETER_DIR"
  cp "$SCRIPT_DIR/greeter/shell.qml" "$GREETER_DIR/shell.qml"
  "$HOME/.local/bin/greeter-theme-sync" 2>/dev/null \
    || bash "$SCRIPT_DIR/../nobara/.local/bin/greeter-theme-sync" \
    || die "couldn't render the greeter theme (is a theme applied? omactl theme set <name>)"
  [[ -f $GREETER_DIR/Theme.qml ]] || die "$GREETER_DIR/Theme.qml is missing"
  chmod -R a+rX "$GREETER_DIR"

  local greeter_user=greetd
  getent passwd greetd >/dev/null || greeter_user=greeter
  log "Configuring greetd (greeter runs as $greeter_user)..."
  [[ -f /etc/greetd/config.toml && ! -f /etc/greetd/config.toml.dotfiles-backup ]] \
    && sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.dotfiles-backup
  sudo install -d /etc/greetd
  sudo tee /etc/greetd/config.toml >/dev/null <<TOML
[terminal]
vt = 1

[default_session]
command = "cage -s -- env QT_WAYLAND_DISABLE_WINDOWDECORATION=1 quickshell -p $GREETER_DIR"
user = "$greeter_user"
TOML

  # KWallet is Omadora's secret service on Nobara: unlock it at login like Plasma Login Manager does
  local kwallet_pam
  kwallet_pam=$(ls /usr/lib64/security/pam_kwallet5.so /usr/lib/security/pam_kwallet5.so 2>/dev/null | head -n 1 || true)
  if [[ -n $kwallet_pam && -f /etc/pam.d/greetd ]] && ! sudo grep -q pam_kwallet5 /etc/pam.d/greetd; then
    log "Letting greetd unlock KWallet at login..."
    printf '%s\n' \
      'auth       optional    pam_kwallet5.so' \
      'session    optional    pam_kwallet5.so auto_start' | sudo tee -a /etc/pam.d/greetd >/dev/null
  elif [[ -z $kwallet_pam ]]; then
    log "WARNING: pam_kwallet5.so not found - KWallet will ask for its password after login."
  fi

  log "Making greetd the login manager (Plasma Login Manager stays installed, disabled)..."
  sudo systemctl disable plasmalogin.service 2>/dev/null || true
  sudo systemctl enable --force greetd.service
  cat <<MSG

Done. Reboot to try the new login screen.

If it doesn't show up (black screen, no prompt):
  Ctrl+Alt+F3, log in on the text console, then:  $SCRIPT_DIR/remove-kde.sh rollback  &&  reboot

Once you are logged in through it, run:  $SCRIPT_DIR/remove-kde.sh remove
MSG
}

cmd_rollback() {
  log "Restoring Plasma Login Manager..."
  rpm -q plasma-login-manager &>/dev/null || sudo dnf install -y plasma-login-manager
  sudo systemctl disable greetd.service 2>/dev/null || true
  sudo systemctl enable --force plasmalogin.service
  log "Done. Reboot."
}

# Protect what must stay: dnf then refuses a transaction that would remove any of it.
write_protected() {
  keep_names | sudo tee "$PROTECTED_FILE" >/dev/null
}

# Package names a dnf preview would remove (first column of the Removing sections)
preview_names() {
  awk 'NF >= 3 && $2 ~ /^(x86_64|noarch|i686|aarch64)$/ {print $1}' <<<"$1" | sort -u
}

check_preview() {
  local output="$1" hit
  hit=$(comm -12 <(preview_names "$output") <(keep_names | sort -u))
  if [[ -n $hit ]]; then
    printf '\033[31mThe preview would remove packages that must stay:\033[0m\n%s\n' "$hit" >&2
    return 1
  fi
}

# preview a dnf transaction, refuse it if it touches a protected package, ask, then run it
run_transaction() {
  local label="$1"; shift
  local preview
  preview=$(sudo dnf "$@" --assumeno 2>&1 || true)
  printf '%s\n' "$preview"
  check_preview "$preview" || die "$label aborted: nothing was removed."
  printf '\nType REMOVE to run this %s: ' "$label"
  local answer; read -r answer
  [[ $answer == REMOVE ]] || { log "Skipped $label."; return 1; }
  sudo dnf "$@" -y
}

cmd_remove() {
  not_in_plasma
  local from=""
  [[ -n ${XDG_SESSION_ID:-} ]] && from=$(loginctl show-session "$XDG_SESSION_ID" -p Service --value 2>/dev/null || true)
  [[ $from == greetd ]] \
    || die "this session wasn't started by greetd (it came from '${from:-unknown}'). Run '$0 greeter', reboot and log in through it first."
  rpm -q greetd &>/dev/null || die "greetd isn't installed"

  local patterns=("${KDE_PACKAGES[@]}")
  [[ ${1:-} == --kde-only ]] || patterns+=("${DEFAULT_APPS[@]}")
  mapfile -t packages < <(matching "${patterns[@]}" | grep -vxFf <(keep_names) || true)
  ((${#packages[@]})) || { log "Nothing left to remove."; return 0; }

  log "${#packages[@]} packages selected:"
  printf '  %s\n' "${packages[@]}"
  write_protected

  run_transaction "removal" remove "${packages[@]}" || return 0

  log "The Plasma libraries it leaves behind (Qt/KF6) are mostly still needed by Quickshell and other apps."
  printf 'Also remove packages nothing needs any more? Preview first [y/N]: '
  local answer; read -r answer
  [[ $answer =~ ^[Yy] ]] && { run_transaction "autoremove" autoremove || true; }
  log "Done. Plasma is gone; the login screen is the Quickshell greeter."
}

case "${1:-status}" in
greeter) cmd_greeter ;;
remove) shift; cmd_remove "$@" ;;
rollback) cmd_rollback ;;
status) cmd_status ;;
*) die "usage: $0 greeter | remove [--kde-only] | rollback | status" ;;
esac
