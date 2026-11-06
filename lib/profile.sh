#!/usr/bin/env bash
# Linux install profile: "skein" (the Skein desktop, dynamic themes) or "apps" (only the apps, CLI
# tools and configs; the existing desktop stays, static One Dark theme). resolve_profile sets and
# exports DOTFILES_PROFILE and saves it, so later runs don't ask again. Order: the environment, the
# saved file, an existing Skein checkout, the question (only with --ask and a terminal), skein.

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

profile_file() {
  echo "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/profile"
}

resolve_profile() {
  local ask=false file saved="" answer=""
  [[ ${1:-} == --ask ]] && ask=true
  file="$(profile_file)"

  if [[ -n ${DOTFILES_PROFILE:-} ]]; then
    if [[ $DOTFILES_PROFILE != skein && $DOTFILES_PROFILE != apps ]]; then
      log "ERROR: DOTFILES_PROFILE must be skein or apps, not '$DOTFILES_PROFILE'."
      exit 1
    fi
  else
    [[ -f $file ]] && saved="$(tr -d '[:space:]' <"$file")"
    if [[ $saved == skein || $saved == apps ]]; then
      DOTFILES_PROFILE=$saved
    elif [[ -d $HOME/.local/share/skein/.git ]]; then
      DOTFILES_PROFILE=skein
    elif $ask && { : </dev/tty; } 2>/dev/null; then
      {
        echo
        echo "Install profile:"
        echo "  1) skein - the Skein desktop (Hyprland + Quickshell) with dynamic themes"
        echo "  2) apps  - only the apps, CLI tools and configs; your desktop stays, static One Dark theme"
      } >/dev/tty
      while :; do
        IFS= read -r -p "Profile [1]: " answer </dev/tty 2>/dev/tty || { answer=1; break; }
        case "${answer,,}" in
          ""|1|s|skein) DOTFILES_PROFILE=skein; break ;;
          2|a|apps) DOTFILES_PROFILE=apps; break ;;
          *) echo "Answer 1 (skein) or 2 (apps)." >/dev/tty ;;
        esac
      done
    else
      DOTFILES_PROFILE=skein
    fi
  fi

  export DOTFILES_PROFILE
  mkdir -p "$(dirname "$file")"
  echo "$DOTFILES_PROFILE" >"$file"
  log "Install profile: $DOTFILES_PROFILE"
}

is_apps_profile() {
  [[ ${DOTFILES_PROFILE:-} == apps ]]
}
