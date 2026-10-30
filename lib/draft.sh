#!/usr/bin/env bash
# Installs the latest release of my "draft" scaffolding CLI (git.fernandovideira.com) to
# ~/.local/bin/draft on macOS (arm64) and Linux (amd64); the releases have no other builds.
#
# Installs when draft is missing or older than the latest release, and leaves a copy that is
# already up to date alone wherever it lives (a `go install` in ~/go/bin, for instance). Rerunning
# the installer is how a machine picks up a new release.
#
# The releases publish no checksums, so the download is trusted over TLS from my own server and
# checked by running it: it has to report the release's version. If a release ever ships a
# checksums file (an asset named *checksums.txt or SHA256SUMS), it is verified and a mismatch
# installs nothing.
#
# Every step handles its own failure instead of relying on `set -e`: bash turns errexit off
# inside a function that's called as `install_draft || ...`.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

DRAFT_API="https://git.fernandovideira.com/api/v1/repos/FernandoJVideira/draft/releases/latest"
DRAFT_BIN="$HOME/.local/bin/draft"

_draft_asset_name() {
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) echo draft_darwin_arm64 ;;
    Linux-x86_64 | Linux-amd64) echo draft_linux_amd64 ;;
    *) return 1 ;;
  esac
}

_draft_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# the version a draft binary reports ("Draft CLI version: v0.2.3" -> v0.2.3): -v, else the older `version` subcommand; empty if it can't run
_draft_version() {
  local arg v
  for arg in -v version; do
    v="$("$1" "$arg" 2>/dev/null | grep -Eo 'v[0-9]+(\.[0-9]+)*' | head -1)"
    [[ -n $v ]] && { printf '%s\n' "$v"; return 0; }
  done
  return 0
}

_draft_fetch_and_install() {
  local name=$1 tmp=$2 tag url sums_url expected got

  curl -fsSL -o "$tmp/release.json" "$DRAFT_API" || {
    log "WARNING: couldn't fetch draft's release info - skipping draft."
    return 1
  }
  tag="$(jq -r '.tag_name // empty' "$tmp/release.json")"
  url="$(jq -r --arg n "$name" '.assets[]? | select(.name == $n) | .browser_download_url' "$tmp/release.json" | head -1)"
  if [[ -z $tag || -z $url ]]; then
    log "WARNING: no draft release asset named $name - skipping."
    return 1
  fi

  local installed
  installed="$(command -v draft >/dev/null 2>&1 && _draft_version "$(command -v draft)" || true)"
  if [[ -n $installed && $(printf '%s\n%s\n' "$installed" "$tag" | sort -V | tail -1) == "$installed" ]]; then
    log "draft $installed is already installed (latest release: $tag)."
    return 0
  fi

  log "Installing draft $tag (${installed:+was $installed, }$name)..."
  curl -fsSL -o "$tmp/draft" "$url" || {
    log "WARNING: couldn't download draft $tag - skipping."
    return 1
  }

  sums_url="$(jq -r '[.assets[]? | select(.name | test("checksums\\.txt$|SHA256SUMS$"; "i")) | .browser_download_url][0] // empty' "$tmp/release.json")"
  if [[ -n $sums_url ]]; then
    curl -fsSL -o "$tmp/sums" "$sums_url" || {
      log "WARNING: couldn't download draft's checksums - not installing an unverified download."
      return 1
    }
    expected="$(awk -v n="$name" '$2 == n || $2 == "*" n {print $1}' "$tmp/sums" | head -1)"
    got="$(_draft_sha256 "$tmp/draft")"
    if [[ -z $expected || $expected != "$got" ]]; then
      log "WARNING: draft's SHA256 doesn't match the published one - not installing."
      return 1
    fi
  fi

  chmod +x "$tmp/draft"
  if [[ "$(_draft_version "$tmp/draft")" != "$tag" ]]; then
    log "WARNING: the downloaded draft doesn't report $tag - not installing."
    return 1
  fi

  mkdir -p "$(dirname "$DRAFT_BIN")"
  install -m 755 "$tmp/draft" "$DRAFT_BIN" || {
    log "WARNING: couldn't write $DRAFT_BIN."
    return 1
  }
  log "draft $tag installed to $DRAFT_BIN."
}

install_draft() {
  local name tmp rc
  name="$(_draft_asset_name)" || {
    log "No draft release for $(uname -s)/$(uname -m) - skipping draft."
    return 0
  }
  for tool in curl jq sort; do
    command -v "$tool" >/dev/null 2>&1 || {
      log "WARNING: $tool is needed to install draft - skipping."
      return 1
    }
  done

  tmp="$(mktemp -d)"
  _draft_fetch_and_install "$name" "$tmp"
  rc=$?
  rm -rf "$tmp"
  return $rc
}
