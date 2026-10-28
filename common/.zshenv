export ZDOTDIR="$HOME/.config/zsh"
# Terminals that set their own ZDOTDIR (kitty's shell integration) make zsh skip
# $ZDOTDIR/.zshenv, so load it from here. When ZDOTDIR is already ours at startup,
# zsh reads that file directly and never gets here, so it is not sourced twice.
[[ -r $ZDOTDIR/.zshenv ]] && source "$ZDOTDIR/.zshenv"
