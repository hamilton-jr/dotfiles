#!/usr/bin/env zsh
#
# Preview para fzf: variáveis, aliases, diretórios, arquivos de texto, binários e imagens
#

if [[ $# -ne 1 ]]; then
  >&2 echo "usage: $0 ITEM"
  exit 1
fi

item=${1/#\~\//$HOME/}
center=0
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/fzf-preview
alias_cache=$cache_dir/aliases.zsh

supports_sixel() {
  [[ $TERM == *sixel* ]] \
    || [[ $TERM_PROGRAM == WezTerm ]]
}

is_windows_terminal() {
  [[ -n $WT_SESSION ]]
}

preview_file() {
  local target=$1
  local highlight_line=${2:-0}
  local type
  local dim
  local cols
  local lines
  local pixel_width
  local pixel_height

  type=$(file --brief --dereference --mime -- "$target")

  if [[ ! $type =~ image/ ]]; then
    if [[ $type =~ binary ]]; then
      file "$target"
      return
    fi

    bat --style="${BAT_STYLE:-numbers}" --color=always --pager=never --highlight-line="$highlight_line" -- "$target"
    return
  fi

  dim=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}
  if [[ $dim == x ]]; then
    dim=$(stty size < /dev/tty | awk '{print $2 "x" $1}')
  fi

  cols=${dim%%x*}
  lines=${dim##*x}
  pixel_width=$(( cols * 8 ))
  pixel_height=$(( lines * 16 ))

  if command -v magick > /dev/null && supports_sixel; then
    magick "$target" -auto-orient -thumbnail "${pixel_width}x${pixel_height}>" sixel:-
    echo
  elif command -v magick > /dev/null && command -v chafa > /dev/null && is_windows_terminal; then
    if magick "$target" -auto-orient -thumbnail "${pixel_width}x${pixel_height}>" png:- | chafa -s "$dim" -; then
      echo
    else
      chafa -s "$dim" "$target"
      echo
    fi
  elif command -v chafa > /dev/null; then
    chafa -s "$dim" "$target"
    echo
  elif command -v imgcat > /dev/null; then
    imgcat -W "${dim%%x*}" -H "${dim##*x}" "$target"
  else
    file "$target"
  fi
}

# Arquivo com linha (ex: file:lineno)
if [[ $item =~ ^(.+):([0-9]+)\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
  item=${BASH_REMATCH[1]}
  center=${BASH_REMATCH[2]}
elif [[ $item =~ ^(.+):([0-9]+):[0-9]+\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
  item=${BASH_REMATCH[1]}
  center=${BASH_REMATCH[2]}
fi

# Variável de ambiente
if [[ -n ${(P)item} ]]; then
  echo "\e[1;32m$item\e[0m=\e[1;33m${(P)item}\e[0m"
  exit 0
fi

# Diretório
if [[ -d $item ]]; then
  echo "📂 Conteúdo do diretório: $item"
  eza -lah --group-directories-first --icons --color=always "$item"
  exit 0
fi

# Arquivo existente
if [[ -f $item ]]; then
  preview_file "$item" "${center:-0}"
  exit 0
fi

# Alias
alias_definition=
if [[ -r $alias_cache ]]; then
  while IFS= read -r line; do
    if [[ $line == "alias $item="* ]] || [[ $line == "alias -- $item="* ]]; then
      alias_definition=$line
      break
    fi
  done < "$alias_cache"
fi

if [[ -n $alias_definition ]]; then
  alias_value=${alias_definition#*=}
  alias_value=${alias_value#\'}
  alias_value=${alias_value%\'}
  echo "\e[1;35m$item\e[0m → \e[36m$alias_value\e[0m"
  exit 0
fi

# Builtin, comando externo ou palavra reservada
if command_info=$(whence -v -- "$item" 2>/dev/null); then
  echo "\e[1;34m$command_info\e[0m"
  if command_path=$(whence -p -- "$item" 2>/dev/null); then
    if [[ -n $command_path && -f $command_path && -r $command_path ]]; then
      echo
      preview_file "$command_path"
    fi
  fi
  exit 0
fi

# Se não for arquivo legível
if [[ ! -f $item ]]; then
  echo "Item não reconhecido: $item"
  exit 0
fi

preview_file "$item" "${center:-0}"

