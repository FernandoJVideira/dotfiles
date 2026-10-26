#!/usr/bin/env bash
# One-time cleanup for machines set up before the dev tools moved to mise (see lib/mise.sh):
# uninstalls the system packages that mise now provides, the ones that are installed. Run it
# before ./bootstrap.sh, which installs the same tools with mise.
#
#   ./mise-migration-cleanup.sh [--dry-run] [--yes]
#
#   Arch / CachyOS    go, github-cli, dotnet-sdk              (pacman)
#   Nobara / Fedora   golang, gh, dotnet-sdk-10.0             (dnf)
#
# --dry-run shows what would be removed, dependencies included, and removes nothing. --yes skips
# this script's own question only: pacman and dnf still ask before they remove anything, and
# neither is ever forced. Packages that something else needs are skipped (pacman) or listed in
# the transaction for you to refuse (dnf). Neovim and tmux are left alone: Omarchy owns them on
# Arch, and Fedora's tmux and Neovim were already replaced by mise's.
set -euo pipefail

dry_run=0
assume_yes=0
for arg in "$@"; do
  case $arg in
    --dry-run | -n) dry_run=1 ;;
    --yes | -y) assume_yes=1 ;;
    *) echo "usage: $0 [--dry-run] [--yes]" >&2; exit 2 ;;
  esac
done

# shellcheck disable=SC1091
source "${OS_RELEASE_FILE:-/etc/os-release}" 2>/dev/null || { echo "no /etc/os-release: this is for Arch and Fedora-based Linux." >&2; exit 1; }
case " ${ID:-} ${ID_LIKE:-} " in
  *" fedora "*) family=fedora ;;
  *" arch "*) family=arch ;;
  *) echo "Not Arch or Fedora based (${ID:-unknown}). macOS machines don't need this." >&2; exit 1 ;;
esac

if [[ $family == arch ]]; then
  candidates=(go github-cli dotnet-sdk)
else
  candidates=(golang gh dotnet-sdk-10.0)
fi

installed=()
for p in "${candidates[@]}"; do
  if [[ $family == arch ]]; then
    pacman -Qq "$p" >/dev/null 2>&1 && installed+=("$p")
  else
    rpm -q "$p" >/dev/null 2>&1 && installed+=("$p")
  fi
done

if [[ ${#installed[@]} -eq 0 ]]; then
  echo "Nothing to uninstall: none of ${candidates[*]} are installed."
  exit 0
fi

to_remove=()
skipped=()
if [[ $family == arch ]]; then
  for p in "${installed[@]}"; do
    if pacman -Rs --print --print-format '%n' "$p" >/dev/null 2>&1; then
      to_remove+=("$p")
    else
      echo "Skipping $p: other installed packages need it (pacman -Qi $p)."
      skipped+=("$p")
    fi
  done
  [[ ${#to_remove[@]} -gt 0 ]] || { echo "Nothing can be removed safely."; exit 1; }
  echo "pacman would remove (with dependencies nothing else needs):"
  pacman -Rs --print --print-format '  %n %v' "${to_remove[@]}"
else
  to_remove=("${installed[@]}")
  echo "dnf would remove (its transaction is the full list; refuse it if it shows anything you want to keep):"
  sudo dnf remove --assumeno "${to_remove[@]}" 2>&1 | sed 's/^/  /' || true
fi

if [[ $dry_run == 1 ]]; then
  echo "(dry run: nothing was removed)"
  exit 0
fi

if [[ $assume_yes == 0 ]]; then
  read -r -p "Uninstall ${to_remove[*]}? [y/N] " answer
  [[ $answer == [yY]* ]] || { echo "Cancelled."; exit 1; }
fi

status=0
if [[ $family == arch ]]; then
  sudo pacman -Rs "${to_remove[@]}" || status=1
else
  sudo dnf remove "${to_remove[@]}" || status=1
fi

echo
[[ $status == 0 ]] && echo "Done." || echo "The uninstall didn't finish (see above)."
[[ ${#skipped[@]} -gt 0 ]] && echo "Skipped: ${skipped[*]}"
echo "Next: ./bootstrap.sh installs these tools with mise."
exit $status
