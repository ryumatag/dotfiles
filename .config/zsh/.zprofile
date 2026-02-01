# Load shared path and environment (idempotent).
[ -f "$HOME/.config/shell/pathrc" ] && . "$HOME/.config/shell/pathrc"
[ -f "$HOME/.config/shell/envrc" ] && . "$HOME/.config/shell/envrc"


# Auto-start tmux on login shells attached to a TTY.
#
# I think this should probably live in .zprofile (not .zshrc), since exec
# replaces the shell and would otherwise abort the rest of interactive
# initialization.
if [[ -z "$TMUX" ]] && cmd-exists tmux && [[ -t 0 ]]; then
  exec tmux new -As "stuff"
fi
