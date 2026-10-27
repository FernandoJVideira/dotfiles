# ~/.config/zsh/.zshenv

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- Starship ----------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"
# Colors follow the current theme (rendered by starship-theme-sync from the theme-set
# hook: Linux's skeinctl, macOS's `theme` command); falls back to the static file until
# the first theme is set
[[ -f "$HOME/.local/state/starship/starship.toml" ]] && export STARSHIP_CONFIG="$HOME/.local/state/starship/starship.toml"

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
export PATH=$PATH:$HOME/.spicetify

# ---------- Miniconda ----------
# Installed by lib/miniconda.sh to the same prefix on every OS, so this block is
# universal. It replaces the `conda init` block, which belongs in .zshrc and is
# written by conda itself. Two parts:
#  - condabin on PATH (a plain assignment, free): `conda` is reachable from
#    scripts and tools too, not only from interactive zsh.
#  - the shell hook that makes `conda activate` work is loaded on first use.
#    Generating it runs Python (~0.2s) and .zshenv is read by *every* zsh,
#    scripts included, so doing it eagerly would tax them all. The hook ends
#    with an unconditional `conda activate base`; CONDA_AUTO_ACTIVATE=false
#    turns that off so the first `conda` call doesn't silently put conda's
#    Python ahead of everything. Activate when you want one. (Only this name:
#    also setting the older CONDA_AUTO_ACTIVATE_BASE makes conda 26 abort with
#    MultipleKeysError, so the hook never loads.)
export CONDA_ROOT="$HOME/miniconda3"
if [[ -d "$CONDA_ROOT/condabin" ]]; then
  export PATH="$CONDA_ROOT/condabin:$PATH"
  conda() {
    unfunction conda
    eval "$(CONDA_AUTO_ACTIVATE=false "$CONDA_ROOT/bin/conda" shell.zsh hook)"
    conda "$@"
  }
fi


# ---------- SSH (Proton Pass agent) ----------
export SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"
