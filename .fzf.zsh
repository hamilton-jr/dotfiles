# Bootstrap

if [[ ! "$PATH" == */home/jun/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/jun/.fzf/bin"
fi

# Alias preview cache
fzf_refresh_alias_cache() {
  local cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/fzf-preview
  mkdir -p "$cache_dir"
  alias -L >| "$cache_dir/aliases.zsh"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd fzf_refresh_alias_cache
fzf_refresh_alias_cache

# fzf base integration
source <(fzf --zsh)

# Core options
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS="--layout=reverse --height 80% --style full \
  --preview 'fzf-preview.sh {}' \
  --preview-window=right:50% \
  --bind 'focus:transform-header:file --brief {}'"

# Completion and widget options
export FZF_COMPLETION_OPTS="--preview 'fzf-preview.sh {}' --preview-window=down:40%"
export FZF_ALT_C_OPTS="--no-preview --header= --bind 'focus:change-header:'"
export FZF_CTRL_R_OPTS="--style minimal --no-preview --preview-window=hidden --info=hidden --bind 'focus:ignore'"

# Command-specific completion overrides
_fzf_comprun() {
  local command=$1
  shift

  if [[ $command == unalias || $command == unset ]]; then
    if [ -n "${TMUX_PANE-}" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "${FZF_TMUX_OPTS-}" ]; }; then
      if [ -n "${FZF_TMUX_OPTS-}" ]; then
        fzf-tmux ${(Q)${(Z+n+)FZF_TMUX_OPTS}} -- "$@" --header= --bind 'focus:change-header:'
      else
        fzf-tmux -d ${FZF_TMUX_HEIGHT:-40%} -- "$@" --header= --bind 'focus:change-header:'
      fi
    else
      fzf "$@" --header= --bind 'focus:change-header:'
    fi
    return
  fi

  if [ -n "${TMUX_PANE-}" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "${FZF_TMUX_OPTS-}" ]; }; then
    if [ -n "${FZF_TMUX_OPTS-}" ]; then
      fzf-tmux ${(Q)${(Z+n+)FZF_TMUX_OPTS}} -- "$@"
    else
      fzf-tmux -d ${FZF_TMUX_HEIGHT:-40%} -- "$@"
    fi
  else
    fzf "$@"
  fi
}

# Custom search helpers
fzf-rg() {
  rg --hidden --glob "!.git/*" --line-number --no-heading --color=always "$@" \
    | fzf --ansi --delimiter : \
          --header= \
          --preview 'bat --style=numbers --color=always --line-range {2}::4 --highlight-line {2} {1}' \
          --preview-window=down:40% \
          --bind 'focus:change-header:' \
          --bind 'enter:execute(nano +{2} {1})'
}

# Key bindings
bindkey -s '^F' 'fzf-rg '
