#!/usr/bin/env bash
# Installs the Spicetify CLI to ~/.spicetify on macOS and Linux (x86_64 everywhere, arm64
# on macOS), the same prefix the official install script uses and that .zshenv already
# has on PATH.
#
# One installer for every OS, like lib/miniconda.sh: Arch has it in the AUR, Fedora and
# Terra don't package it, Homebrew has it but would sit next to an existing ~/.spicetify.
# The release tarball is checked against the SHA256 GitHub publishes for each asset (same
# origin as the download, so this catches corruption/truncation, not a compromised
# release). No digest found or a mismatch means nothing is installed.
#
# Only installs: a Spicetify that is already there is left alone (it updates itself with
# `spicetify upgrade`). Spotify itself, and the first `spicetify apply`, are not done
# here: apply needs Spotify to have been started once; spicetify-theme-sync handles it.
#
# Every step handles its own failure instead of relying on `set -e`: bash turns errexit
# off inside a function that's called as `install_spicetify || ...`.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

SPICETIFY_ROOT="$HOME/.spicetify"
SPICETIFY_API="https://api.github.com/repos/spicetify/cli/releases/latest"

_spicetify_asset_suffix() {
  local os arch
  case "$(uname -s)" in
    Darwin) os=darwin ;;
    Linux) os=linux ;;
    *) return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64 | amd64) arch=amd64 ;;
    arm64 | aarch64)
      # releases ship a Linux build for amd64 only
      [[ $os == darwin ]] || return 1
      arch=arm64
      ;;
    *) return 1 ;;
  esac
  echo "$os-$arch.tar.gz"
}

_spicetify_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

_spicetify_fetch_and_install() {
  local suffix=$1 tmp=$2 asset url expected actual

  curl -fsSL -o "$tmp/release.json" "$SPICETIFY_API" || {
    log "WARNING: couldn't fetch Spicetify's release info - skipping Spicetify."
    return 1
  }
  # asset name, download URL and SHA256 of the build for this OS/arch
  asset="$(jq -r --arg s "$suffix" '.assets[] | select(.name | endswith($s)) | [.name, .browser_download_url, (.digest // "")] | @tsv' "$tmp/release.json" | head -1)"
  if [[ -z $asset ]]; then
    log "WARNING: no Spicetify release asset for $suffix - skipping."
    return 1
  fi
  url="$(printf '%s' "$asset" | cut -f2)"
  expected="$(printf '%s' "$asset" | cut -f3)"
  expected="${expected#sha256:}"
  if [[ ! $expected =~ ^[0-9a-f]{64}$ ]]; then
    log "WARNING: no published SHA256 for the Spicetify release - not installing an unverified download."
    return 1
  fi

  log "Downloading $(printf '%s' "$asset" | cut -f1)..."
  curl -fsSL -o "$tmp/spicetify.tar.gz" "$url" || {
    log "WARNING: couldn't download Spicetify - skipping."
    return 1
  }
  actual="$(_spicetify_sha256 "$tmp/spicetify.tar.gz")"
  if [[ $actual != "$expected" ]]; then
    log "WARNING: SHA256 mismatch for Spicetify (expected $expected, got $actual) - not installing."
    return 1
  fi

  mkdir -p "$SPICETIFY_ROOT" && tar -xzf "$tmp/spicetify.tar.gz" -C "$SPICETIFY_ROOT" || {
    log "WARNING: couldn't unpack Spicetify into $SPICETIFY_ROOT."
    return 1
  }
  chmod +x "$SPICETIFY_ROOT/spicetify"
  log "Spicetify installed to $SPICETIFY_ROOT."
  return 0
}

install_spicetify() {
  if [[ -x "$SPICETIFY_ROOT/spicetify" ]] || command -v spicetify >/dev/null 2>&1; then
    log "Spicetify already installed."
    return 0
  fi

  local suffix tmp rc
  suffix="$(_spicetify_asset_suffix)" || {
    log "WARNING: no Spicetify build for $(uname -s)/$(uname -m) - skipping."
    return 1
  }
  command -v jq >/dev/null 2>&1 || {
    log "WARNING: jq is needed to read Spicetify's release info - skipping Spicetify."
    return 1
  }
  tmp="$(mktemp -d)" || return 1
  _spicetify_fetch_and_install "$suffix" "$tmp"
  rc=$?
  rm -rf "$tmp"
  return $rc
}
