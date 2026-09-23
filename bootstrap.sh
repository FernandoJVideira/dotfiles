#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Darwin)
    "$SCRIPT_DIR/macos/install.sh"
    ;;
  Linux)
    os_id=$(awk -F= '/^ID=/{gsub(/"/,"",$2); print tolower($2)}' /etc/os-release 2>/dev/null)
    os_id_like=$(awk -F= '/^ID_LIKE=/{gsub(/"/,"",$2); print tolower($2)}' /etc/os-release 2>/dev/null)
    if [[ "$os_id" == "nobara" || "$os_id_like" == *fedora* ]]; then
      "$SCRIPT_DIR/linux/nobara/install.sh"
    else
      "$SCRIPT_DIR/linux/arch/install.sh"
    fi
    ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac
