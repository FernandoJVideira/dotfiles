#!/usr/bin/env bash
# Library sourced by brain-start.sh (needs brain_ssh from brain-lib.sh): warns when the dotfiles repo that
# holds these hooks is behind its remote, since a machine keeps running old hooks until it pulls and
# reruns ./bootstrap.sh. Reads existing refs only; the fetch that refreshes them runs detached.

brain_dotfiles_behind() {
  local dir info repo gitdir stamp n t=()
  dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
  info="$(git -C "$dir" rev-parse --show-toplevel --absolute-git-dir 2>/dev/null)" || return 0
  repo="${info%%$'\n'*}" gitdir="${info#*$'\n'}"
  # rev-list fails without an upstream, which also keeps us from fetching for a repo with no remote
  n="$(git -C "$repo" rev-list --count 'HEAD..@{u}' 2>/dev/null)" || return 0
  stamp="$gitdir/brain-update.stamp"
  if [[ ! -e $stamp ]] || [[ -n $(find "$stamp" -mmin +360 2>/dev/null) ]]; then
    : >"$stamp" 2>/dev/null || true
    command -v timeout >/dev/null && t=(timeout 20)
    GIT_SSH_COMMAND="$(brain_ssh 5)" \
      nohup ${t[@]+"${t[@]}"} git -C "$repo" fetch -q >/dev/null 2>&1 </dev/null &
    disown 2>/dev/null || true
  fi

  [[ $n =~ ^[0-9]+$ && $n -gt 0 ]] || return 0
  printf 'The dotfiles repo is %s commit%s behind its remote: pull it and rerun ./bootstrap.sh to update these hooks (%s).' \
    "$n" "$([[ $n -eq 1 ]] || echo s)" "$repo"
}
