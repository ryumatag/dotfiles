# Shared path/env are needed even for non-interactive shells.
[ -f "$HOME/.config/shell/pathrc" ] && . "$HOME/.config/shell/pathrc"
[ -f "$HOME/.config/shell/envrc" ] && . "$HOME/.config/shell/envrc"

# If not running interactively, don't do anything more.
if ! [[ -o interactive ]]; then
  return
fi

# Aliases are interactive-only to avoid surprising behavior in `zsh -c ...`.
[ -f "$HOME/.config/shell/aliasrc" ] && . "$HOME/.config/shell/aliasrc"

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

# SIGUSR1-triggered config reload (deferred).
#
# Strategy:
# - The signal trap only marks a reload request.
# - The actual reload runs at the next prompt (precmd), when it's safe.
#   This avoids breaking foreground apps (nvim/ssh/less/etc).
#
# The actual reload is performed by __prompt_precmd in prompt.zsh.
(( ${+__ZRELOAD_PENDING} ))     || typeset -g __ZRELOAD_PENDING=0
(( ${+__ZRELOAD_IN_PROGRESS} )) || typeset -g __ZRELOAD_IN_PROGRESS=0

__zreload_apply() {
  (( __ZRELOAD_IN_PROGRESS )) && return 0
  __ZRELOAD_IN_PROGRESS=1
  {
    . "$ZDOTDIR/.zshrc"
  } always {
    __ZRELOAD_IN_PROGRESS=0
  }
}

TRAPUSR1() {
  __ZRELOAD_PENDING=1
}

# Prompt (defines __prompt_precmd and registers precmd hook)
[ -f "$ZDOTDIR/prompt.zsh" ] && . "$ZDOTDIR/prompt.zsh"

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
