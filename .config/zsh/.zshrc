# Load shared path/aliases/env (shared files are bash/zsh compatible).
[ -f "$HOME/.config/shell/pathrc" ] && . "$HOME/.config/shell/pathrc"
[ -f "$HOME/.config/shell/aliasrc" ] && . "$HOME/.config/shell/aliasrc"
[ -f "$HOME/.config/shell/envrc" ] && . "$HOME/.config/shell/envrc"

# Zsh options
setopt appendhistory
setopt autopushd
setopt completeinword
setopt pushdignoredups
setopt extendedhistory
setopt histignoredups
setopt histignorespace
setopt histnostore
setopt histreduceblanks
setopt incappendhistory
setopt notify
setopt sharehistory
setopt shwordsplit
setopt nonomatch
unsetopt flow_control
unsetopt list_beep

# Auto-start tmux only on interactive TTY sessions.
if [[ -z "$TMUX" ]] && cmd-exists tmux && [[ -t 0 ]]; then
  exec tmux new -As "stuff"
fi

# Prompt
if cmd-exists starship; then
  eval "$(starship init zsh)"
fi

# fzf integration (zsh)
if cmd-exists fzf; then
  eval "$(fzf --zsh | sed 's/\^T/\^X/g')"
fi

# History (XDG)
[ -d "${XDG_STATE_HOME}/zsh" ] || mkdir -p "${XDG_STATE_HOME}/zsh"
HISTFILE="${XDG_STATE_HOME}/zsh/history"
HISTSIZE=10000000
SAVEHIST=10000000

# Make `time` output closer to bash
TIMEFMT=$'\nreal\t%*E\nuser\t%*U\nsys\t%*S\nmaxmem\t%M MB\nfaults\t%F'

# Keybindings
bindkey -e

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^o' edit-command-line

# Clipboard integration (macOS only for now)
if is-darwin; then
  if cmd-exists pbcopy; then
    pbcopy-as-kill-line() {
      zle kill-line
      print -nr -- "$CUTBUFFER" | pbcopy
    }
    zle -N pbcopy-as-kill-line
    bindkey '^K' pbcopy-as-kill-line
  fi

  if cmd-exists pbpaste; then
    pbpaste-as-yank() {
      emulate -L zsh
      local sys_clip
      sys_clip="$(pbpaste)"
      if [[ "$sys_clip" != "$CUTBUFFER" ]]; then
        killring=("$CUTBUFFER" "${(@)killring[1,-2]}")
        CUTBUFFER="$sys_clip"
      fi
      zle yank
    }
    zle -N pbpaste-as-yank
    bindkey '^Y' pbpaste-as-yank
  fi
fi

# Debug helper: show current buffers/killring
show-buffers() {
  local nl=$'\n' kr
  typeset -T kr KR ' '
  typeset +g -a buffers
  KR=($killring)
  buffers+="      Pre: ${PREBUFFER:-$nl}"
  buffers+="  Buffer: $BUFFER$nl"
  buffers+="     Cut: $CUTBUFFER$nl"
  buffers+="       L: $LBUFFER$nl"
  buffers+="       R: $RBUFFER$nl"
  buffers+="Killring: ( $kr )$nl"
  zle -M "$buffers"
}
zle -N show-buffers
bindkey "^[o" show-buffers

# Completions
if [ -n "${HOMEBREW_PREFIX-}" ] && [ -d "${HOMEBREW_PREFIX}/share/zsh-completions" ]; then
  fpath=( "${HOMEBREW_PREFIX}/share/zsh-completions" $fpath )
fi

[ -d "${XDG_CACHE_HOME}/zsh" ] || mkdir -p "${XDG_CACHE_HOME}/zsh"
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump"
zstyle ":completion:*:commands" rehash 1
zstyle ":completion:*:default" menu select=1

# Autosuggestions (Homebrew-provided)
if [ -n "${HOMEBREW_PREFIX-}" ] && \
   [ -r "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  . "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Syntax highlighting (must be sourced at the end of .zshrc)
zle_highlight=( region:bg=11 )
if [ -n "${HOMEBREW_PREFIX-}" ] && \
   [ -r "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  . "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
