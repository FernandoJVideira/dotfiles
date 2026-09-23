# mise (https://mise.jdx.dev) manages node/neovim/tmux/etc. versions on
# Nobara instead of whatever's frozen in Fedora's repos. Guarded on the
# binary existing so this is a no-op before nobara/install.sh has run.
[[ -x "$HOME/.local/bin/mise" ]] && eval "$("$HOME/.local/bin/mise" activate zsh)"
