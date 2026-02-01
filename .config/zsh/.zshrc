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

# Prompt
[ -f "$ZDOTDIR/prompt.zsh" ] && . "$ZDOTDIR/prompt.zsh"

# Reload interactive zsh configuration on SIGUSR1.
# This enables mass-reloading all running zsh instances (e.g. under tmux)
# without manually sourcing in each pane.
if [[ -o interactive ]]; then
  TRAPUSR1() {
    # Re-source the main zsh config.
    source "$ZDOTDIR/.zshrc"

    # If we're in ZLE, refresh prompt state and redraw.
    # * __prompt_precmd updates gitstatus/vcs_info + PROMPT, but may be
    #   undefined if prompt.zsh wasn't loaded for some reason; guard it.
    # * reset-prompt redraws the current prompt immediately.
    if [[ -n ${+ZLE} ]]; then
      (( ${+functions[__prompt_precmd]} )) && __prompt_precmd 2>/dev/null || true
      zle reset-prompt
    fi
  }
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
fpath=( "${XDG_DATA_HOME}/zsh/completions" $fpath )
if [ -n "${HOMEBREW_PREFIX-}" ] && [ -d "${HOMEBREW_PREFIX}/share/zsh-completions" ]; then
  fpath=( "${HOMEBREW_PREFIX}/share/zsh-completions" $fpath )
elif [ -d /opt/homebrew/share/zsh-completions ]; then
  fpath=( /opt/homebrew/share/zsh-completions $fpath )
elif [ -d /usr/local/share/zsh-completions ]; then
  fpath=( /usr/local/share/zsh-completions $fpath )
fi

zstyle ':completion:*' completer _complete _prefix _files
zstyle ':completion:*' menu select=1
zstyle ':completion:*:descriptions' format 'completing %d:'
zstyle ':completion:*' group-name ''
zstyle ":completion:*:commands" rehash 1

_zcompdump="${XDG_CACHE_HOME}/zsh/zcompdump"
[ -d "${_zcompdump:h}" ] || mkdir -p "${_zcompdump:h}"
autoload -Uz compinit
# Use cached completion dump if it's newer than 24h; else regenerate.
# Exit behavior:
# * regenerate: compinit -d (writes dump)
# * cache ok  : compinit -C -d (skip recomp if possible)
if [[ ! -f "$_zcompdump" ]]; then
  compinit -d "$_zcompdump"
else
  # GNU stat: %Y = mtime as epoch seconds
  _mtime=$(stat -c %Y "$_zcompdump" 2>/dev/null) || _mtime=0

  if (( EPOCHSECONDS - _mtime >= 86400 )); then
    compinit -d "$_zcompdump"
  else
    compinit -C -d "$_zcompdump"
  fi
fi

# Autosuggestions
for plugin in \
  "${XDG_DATA_HOME}/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh} \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
do
  if [ -r "$plugin" ]; then
    . "$plugin"
    break
  fi
done

# Syntax highlighting
zle_highlight=( region:bg=11 )
for plugin in \
  "${XDG_DATA_HOME}/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh} \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  if [ -r "$plugin" ]; then
    . "$plugin"
    break
  fi
done
