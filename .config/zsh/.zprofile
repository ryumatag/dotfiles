# Load shared path and environment (idempotent).
[ -f "$HOME/.config/shell/pathrc" ] && . "$HOME/.config/shell/pathrc"
[ -f "$HOME/.config/shell/envrc" ] && . "$HOME/.config/shell/envrc"
