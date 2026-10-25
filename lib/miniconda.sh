#!/usr/bin/env bash
# Installs Miniconda to ~/miniconda3 on macOS and Linux (x86_64 / arm64).
#
# Anaconda's own installer on every OS, rather than Homebrew's cask or a distro
# package: those land in different places (Caskroom, /opt, ...), and the same
# prefix everywhere is what lets the shell config in common/.config/zsh/.zshenv
# be universal. Batch mode (-b) never edits shell rc files - that's `conda init`,
# deliberately not run, since .zshenv owns the config.
#
# The download is checked against the SHA256 Anaconda publishes on its index page
# (same origin as the installer, so this catches corruption/truncation, not a
# compromised Anaconda). No hash found or a mismatch means nothing is installed.
#
# Every step handles its own failure instead of relying on `set -e`: bash turns
# errexit off inside a function that's called as `install_miniconda || ...`.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

MINICONDA_ROOT="$HOME/miniconda3"
MINICONDA_BASE_URL="https://repo.anaconda.com/miniconda"

_miniconda_installer_name() {
  local os arch
  case "$(uname -s)" in
    Darwin) os=MacOSX ;;
    Linux) os=Linux ;;
    *) return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64 | amd64) arch=x86_64 ;;
    arm64 | aarch64)
      if [[ $os == MacOSX ]]; then arch=arm64; else arch=aarch64; fi
      ;;
    *) return 1 ;;
  esac
  echo "Miniconda3-latest-$os-$arch.sh"
}

_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

_miniconda_fetch_and_run() {
  local name=$1 tmp=$2 expected actual

  curl -fsSL -o "$tmp/index.html" "$MINICONDA_BASE_URL/" || {
    log "WARNING: couldn't fetch Anaconda's installer index (needed for the SHA256) - skipping Miniconda."
    return 1
  }
  expected="$(sed -n "/href=\"$name\"/,/<\/tr>/p" "$tmp/index.html" | grep -o -E '[0-9a-f]{64}' | head -1)"
  if [[ -z $expected ]]; then
    log "WARNING: no published SHA256 found for $name - not installing an unverified installer."
    return 1
  fi

  log "Downloading $name..."
  curl -fsSL -o "$tmp/installer.sh" "$MINICONDA_BASE_URL/$name" || {
    log "WARNING: couldn't download $name - skipping Miniconda."
    return 1
  }
  actual="$(_sha256 "$tmp/installer.sh")"
  if [[ $actual != "$expected" ]]; then
    log "WARNING: SHA256 mismatch for $name (expected $expected, got $actual) - not installing."
    return 1
  fi

  log "Installing Miniconda to $MINICONDA_ROOT..."
  if ! bash "$tmp/installer.sh" -b -p "$MINICONDA_ROOT" >"$tmp/install.log" 2>&1; then
    log "WARNING: the Miniconda installer failed:"
    tail -5 "$tmp/install.log" >&2
    # install_miniconda only gets here when the prefix didn't exist beforehand,
    # so whatever is there is our partial install - remove it so a rerun retries
    rm -rf "$MINICONDA_ROOT"
    return 1
  fi
  # Not accepted on the user's behalf: it's a legal agreement, their call.
  log "Miniconda installed. Before conda can install from Anaconda's default channels it needs their Terms of Service accepted - yours to decide:"
  log "  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main"
  log "  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r"
  log "  (or skip the defaults: conda config --add channels conda-forge && conda config --set channel_priority strict)"
  return 0
}

install_miniconda() {
  if [[ -x "$MINICONDA_ROOT/bin/conda" ]]; then
    log "Miniconda already installed at $MINICONDA_ROOT."
    return 0
  fi
  if [[ -e "$MINICONDA_ROOT" ]]; then
    log "WARNING: $MINICONDA_ROOT exists but has no conda binary - leaving it alone, skipping Miniconda."
    return 1
  fi

  local name tmp rc
  name="$(_miniconda_installer_name)" || {
    log "WARNING: no Miniconda installer for $(uname -s)/$(uname -m) - skipping."
    return 1
  }
  tmp="$(mktemp -d)" || return 1
  _miniconda_fetch_and_run "$name" "$tmp"
  rc=$?
  rm -rf "$tmp"
  return $rc
}
