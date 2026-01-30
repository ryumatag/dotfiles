# do not read any subsequent global startup files
unsetopt global_rcs

prependpath() {
  paths="$1"
  toadd="$2"
  case ":$paths:" in
    *:"$toadd":*)
      echo "$paths"
      ;;
    *)
      echo "$toadd${paths:+:$paths}"
      ;;
  esac
}

typeset -U PATH MANPATH

# obtain default PATH and MANPATH from /etc/{paths,manpaths,paths.d/*,manpaths.d/*}
#if [ -x /usr/libexec/path_helper ]; then
#  eval "$(/usr/libexec/path_helper -s)"
#fi

# system
PATH="$(prependpath "$PATH" /sbin)"
PATH="$(prependpath "$PATH" /bin)"
PATH="$(prependpath "$PATH" /usr/sbin)"
PATH="$(prependpath "$PATH" /usr/bin)"
PATH="$(prependpath "$PATH" /usr/local/sbin)"
PATH="$(prependpath "$PATH" /usr/local/bin)"
PATH="$(prependpath "$PATH" /usr/local/go/bin)"

# homebrew
if [ -r "/opt/homebrew" ]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

  for bindir in "${HOMEBREW_PREFIX}/opt/"*"/libexec/gnubin"; do
    PATH="$(prependpath "$PATH" "$bindir")"
  done
  PATH="$(prependpath "$PATH" "${HOMEBREW_PREFIX}/sbin")"
  PATH="$(prependpath "$PATH" "${HOMEBREW_PREFIX}/bin")"

  for mandir in "${HOMEBREW_PREFIX}/opt/"*"/libexec/gnuman"; do
    MANPATH="$(prependpath "$MANPATH": "$mandir")"
  done
  MANPATH="$(prependpath "$MANPATH": "${HOMEBREW_PREFIX}/share/man")"
fi

# home
PATH=$(prependpath "$PATH" "$HOME/.local/bin")
PATH=$(prependpath "$PATH" "$HOME/.local/share/go/bin")
PATH=$(prependpath "$PATH" "$HOME/.cargo/bin")

export PATH MANPATH

# XDG Base Directory specification
export XDG_CONFIG_HOME="$HOME/.config"     # user-specific configurations
export XDG_CACHE_HOME="$HOME/.cache"       # user-specific non-essential (cached) data
export XDG_DATA_HOME="$HOME/.local/share"  # user-specific data files
export XDG_STATE_HOME="$HOME/.local/state" # user-specific state files (log, history, etc.)

# terminfo
export TERMINFO_DIRS="${XDG_DATA_HOME}/terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}"

# editor
export EDITOR=nvim

# disable less history
export LESSHISTFILE=-

export GOPATH="$XDG_DATA_HOME/go"

if cmd-exists starship; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
  export STARSHIP_CACHE="${XDG_CACHE_HOME}/starship"
fi

if cmd-exists bat; then
  export BAT_THEME="base16"
fi

if cmd-exists fzf; then
  export FZF_TMUX_OPTS="-p 80%"
  export FZF_DEFAULT_COMMAND="fd --type file --follow"
  export FZF_DEFAULT_OPTS="
    --color='dark,gutter:-1,pointer:red'
    --multi
    --height=40%
    --border='sharp'
  "
fi

[ -r "${ZDOTDIR}/.zshenv.local" ] && . "${ZDOTDIR}/.zshenv.local"
