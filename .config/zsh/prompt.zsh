# Setup prompt with gitstatus (preferred) + ultra-light vcs_info fallback.

setopt prompt_subst
autoload -Uz add-zsh-hook

# Colors

PROMPT_CLR_BK='%F{8}'     # bright-black
PROMPT_CLR_CY='%F{cyan}'  # cyan
PROMPT_CLR_RD='%F{red}'   # red
PROMPT_CLR_BL='%F{blue}'  # blue
PROMPT_CLR_RST='%f%k'     # reset

# Core segments

__is_ssh() { [[ -n "$SSH_CONNECTION$SSH_CLIENT$SSH_TTY" ]]; }

__time_segment() {
  print -nr -- "${PROMPT_CLR_BK}[%D{%H:%M}]${PROMPT_CLR_RST} "
}

__hostname_segment() {
  local h="${HOST%%.*}"
  print -nr -- "${PROMPT_CLR_BK}@${h}${PROMPT_CLR_RST}"
}

__username_segment() {
  if (( EUID == 0 )); then
    print -nr -- "${PROMPT_CLR_RD}%B${USER}%b${PROMPT_CLR_RST}"
  else
    print -nr -- "${PROMPT_CLR_BL}${USER}${PROMPT_CLR_RST}"
  fi
}

# Truncate path to last N segments, with leading "…/" if truncated.
__truncate_last_n_segments() {
  local path="$1" n="$2" trunc_sym="…/"
  local -a segs
  segs=(${(s:/:)path})
  segs=(${segs:#})  # drop empty segments
  local count=${#segs[@]}
  if (( count > n )); then
    print -nr -- "${trunc_sym}${(j:/:)segs[-$n,-1]}"
  else
    print -nr -- "${(j:/:)segs}"
  fi
}

__directory_segment() {
  local prefix="${PROMPT_CLR_BK}::${PROMPT_CLR_RST}"
  local style="${PROMPT_CLR_CY}"

  # Fast path: when gitstatus is active, avoid calling git entirely.
  # VCS_STATUS_WORKDIR is the repo root.
  if (( __USE_GITSTATUS )) && [[ "$VCS_STATUS_RESULT" == ok-sync ]] \
    && [[ -n "$VCS_STATUS_WORKDIR" ]]; then
    local root="$VCS_STATUS_WORKDIR"
    local root_name="${root:t}"

    local rel="${PWD#$root}"
    if [[ -z "$rel" || "$rel" == "/" ]]; then
      print -nr -- "${prefix}${style}${root_name}${PROMPT_CLR_RST}"
      return 0
    fi

    rel="${rel#/}"
    local rel_trunc="$(__truncate_last_n_segments "$rel" 3)"
    print -nr -- "${prefix}${style}${root_name}/${rel_trunc}${PROMPT_CLR_RST}"
    return 0
  fi

  # Fallback: in git repo (no gitstatus), show repo root name + relative path.
  local root
  if root=$(command git rev-parse --show-toplevel 2>/dev/null); then
    local rel root_name
    root_name="${root:t}"

    rel="${PWD#$root}"
    if [[ -z "$rel" || "$rel" == "/" ]]; then
      print -nr -- "${prefix}${style}${root_name}${PROMPT_CLR_RST}"
      return 0
    fi

    rel="${rel#/}"
    local rel_trunc="$(__truncate_last_n_segments "$rel" 3)"
    print -nr -- "${prefix}${style}${root_name}/${rel_trunc}${PROMPT_CLR_RST}"
    return 0
  fi

  # Outside repo: show ~-based path (truncate to last 3 segments).
  local p="$PWD"
  [[ -n "$HOME" && "$p" == "$HOME"* ]] && p="~${p#$HOME}"
  [[ "$p" == /* ]] && p="${p#/}"
  local p_trunc="$(__truncate_last_n_segments "$p" 3)"
  print -nr -- "${prefix}${style}${p_trunc}${PROMPT_CLR_RST}"
}

__character_segment() {
  if (( __PROMPT_LAST_STATUS == 0 )); then
    print -nr -- " ${PROMPT_CLR_RD}|${PROMPT_CLR_RST} "
  else
    print -nr -- " ${PROMPT_CLR_RD}¦${PROMPT_CLR_RST} "
  fi
}

# Git segment: gitstatus preferred, vcs_info fallback

: "${XDG_DATA_HOME:=$HOME/.local/share}"
GITSTATUS_DIR="$XDG_DATA_HOME/zsh/plugins/gitstatus"
GITSTATUS_PLUGIN_ZSH="$GITSTATUS_DIR/gitstatus.plugin.zsh"

typeset -g __USE_GITSTATUS=0
typeset -g __GIT_PROMPT_STR=""
# Cache the last git root we detected via filesystem checks.
# This is used to avoid calling gitstatus_query when we're clearly outside a
# repo.
typeset -g __GITSTATUS_ROOT=""

# Fast git root detection without spawning git.
# Walk up parent directories looking for ".git" (dir or file for
# worktrees/submodules).
__git_root_fast() {
  local dir="$PWD"
  while [[ -n "$dir" && "$dir" != "/" ]]; do
    if [[ -e "$dir/.git" ]]; then
      print -r -- "$dir"
      return 0
    fi
    dir="${dir:h}"
  done
  return 1
}

# Initialize gitstatus once at load time.
#
# On re-sourcing, explicitly stop any existing instance first to avoid
# duplicate background processes or stale state.
__gitstatus_init() {
  [[ -f "$GITSTATUS_PLUGIN_ZSH" ]] || return 1
  source "$GITSTATUS_PLUGIN_ZSH" || return 1

  # Ensure a clean restart when this file is re-sourced.
  gitstatus_stop 'DOT' 2>/dev/null || true
  gitstatus_start -s -1 -u -1 -c -1 -d -1 'DOT' || return 1

  __USE_GITSTATUS=1
  return 0
}

__gitstatus_update() {
  __GIT_PROMPT_STR=""
  (( __USE_GITSTATUS )) || return 0

  # Avoid calling gitstatus_query when we're outside a git repo.
  # First, reuse cached root if PWD is still under it.
  local root=""
  if [[ -n "$__GITSTATUS_ROOT" && "$PWD" == "$__GITSTATUS_ROOT"(|/*) ]]; then
    root="$__GITSTATUS_ROOT"
  else
    root="$(__git_root_fast 2>/dev/null)" || root=""
    __GITSTATUS_ROOT="$root"
  fi

  # Not in a repo: skip query and clear stale gitstatus state so other segments
  # (e.g. directory display) won't accidentally treat us as in-repo.
  if [[ -z "$root" ]]; then
    VCS_STATUS_RESULT=""
    VCS_STATUS_WORKDIR=""
    return 0
  fi

  gitstatus_query 'DOT' || return 0
  [[ "$VCS_STATUS_RESULT" == ok-sync ]] || return 0

  local ref="${VCS_STATUS_LOCAL_BRANCH:-${VCS_STATUS_TAG:-@${VCS_STATUS_COMMIT}}}"
  ref="${ref//\%/%%}"  # escape % for prompt expansion

  local marks=""
  (( VCS_STATUS_NUM_UNSTAGED  )) && marks+="!"
  (( VCS_STATUS_NUM_STAGED    )) && marks+="+"
  (( VCS_STATUS_NUM_UNTRACKED )) && marks+="?"

  __GIT_PROMPT_STR="${ref}${marks}"
}

# Fallback: vcs_info (branch + staged/unstaged only; intentionally no untracked for speed)
autoload -Uz vcs_info 2>/dev/null || true
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '!'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '%b%u%c'
zstyle ':vcs_info:git:*' actionformats '%b|%a%u%c'

__vcs_info_update() {
  vcs_info 2>/dev/null || true
  __GIT_PROMPT_STR="${vcs_info_msg_0_}"
}

__git_segment() {
  [[ -n "$__GIT_PROMPT_STR" ]] || return 0
  print -nr -- " ${PROMPT_CLR_CY}(${__GIT_PROMPT_STR})${PROMPT_CLR_RST}"
}

# Prompt assembly

__build_prompt() {
  local s=""
  s+="$(__time_segment)"

  if __is_ssh; then
    s+="$(__username_segment)"
    s+="${PROMPT_CLR_BK}@${PROMPT_CLR_RST}"
    s+="$(__hostname_segment)"
  else
    s+="$(__username_segment)"
  fi

  s+="$(__directory_segment)"
  s+="$(__git_segment)"
  s+="$(__character_segment)"
  print -nr -- "$s"
}

# Initialize gitstatus once at load time (no auto-clone here).
__gitstatus_init || __USE_GITSTATUS=0

__prompt_precmd() {
  __PROMPT_LAST_STATUS=$?

  if (( __USE_GITSTATUS )); then
    __gitstatus_update
  else
    __vcs_info_update
  fi

  PROMPT="$(__build_prompt)"
}

__prompt_exit() {
  if (( __USE_GITSTATUS )); then
    gitstatus_stop 'DOT' 2>/dev/null || true
  fi
}

# Hooks must not accumulate across re-sourcing. Remove existing hooks first,
# then re-add them to guarantee exactly one registration even after multiple
# reloads.
add-zsh-hook -d precmd __prompt_precmd 2>/dev/null || true
add-zsh-hook -d zshexit __prompt_exit 2>/dev/null || true
add-zsh-hook precmd __prompt_precmd
add-zsh-hook zshexit __prompt_exit
