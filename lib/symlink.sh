#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

symlink_dotfiles(){

    local dir="$1"
    shift
    local file
    local -a excludes=()
    local ex
    # extra args: paths relative to $dir whose files are skipped
    for ex in "$@"; do
        ex="${ex%/}"
        excludes+=(-not -path "$dir/$ex" -not -path "$dir/$ex/*")
    done

    while IFS= read -r -d '' file; do
        local relative_path="${file#"$dir"/}"
        local target="$HOME/$relative_path"

        mkdir -p "$(dirname "$target")"

        log "Linking $target -> $file"

        ln -sf "$file" "$target"
    done < <(find "$dir" -type f -not -name "install.sh" -not -name "macos-defaults.sh" -not -name "configure-monitors.sh" -not -name ".DS_Store" ${excludes[@]+"${excludes[@]}"} -print0)
}

unlink_dotfiles(){

    local dir="$1"
    shift
    local file
    local -a excludes=()
    local ex
    # extra args: paths relative to $dir whose files are skipped
    for ex in "$@"; do
        ex="${ex%/}"
        excludes+=(-not -path "$dir/$ex" -not -path "$dir/$ex/*")
    done

    while IFS= read -r -d '' file; do
        local relative_path="${file#"$dir"/}"
        local target="$HOME/$relative_path"

        if [[ -L "$target" ]]; then
            log "Unlinking $target (was -> $file)"
            rm -f "$target"
        fi
    done < <(find "$dir" -type f -not -name "install.sh" -not -name "macos-defaults.sh" -not -name "configure-monitors.sh" -not -name ".DS_Store" ${excludes[@]+"${excludes[@]}"} -print0)
}
