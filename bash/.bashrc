# shellcheck shell=bash
# Per-machine settings go in ~/.bashrc.local, sourced near the end.

path_prepend() {
  [ -d "$1" ] || return
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.local/bin"
export PATH
unset -f path_prepend

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim VISUAL=nvim
  export MANPAGER='nvim +Man!'
else
  export EDITOR=vi VISUAL=vi
fi
export LESS='-R -i -F -X'
# NOTE: not in a tracked ~/.npmrc -- npm login writes tokens into that file.
export NPM_CONFIG_PREFIX="$HOME/.local"
if [ -f "$HOME/.config/ripgrep/config" ]; then
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
fi
if [ -n "${TMUX:-}" ]; then
  export COLORTERM=truecolor
fi

# Everything below is for interactive shells only.
case $- in
  *i*) ;;
  *) return ;;
esac

shopt -s histappend checkwinsize globstar
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
case ";${PROMPT_COMMAND:-};" in
  *';history -a;'*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

# What Debian's skel .bashrc provided; Arch's /etc/bash.bashrc already loads
# completion.
if [ -z "${BASH_COMPLETION_VERSINFO:-}" ] && ! shopt -oq posix; then
  for f in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
    # shellcheck source=/dev/null
    [ -r "$f" ] && . "$f" && break
  done
fi
if command -v lesspipe >/dev/null 2>&1; then
  eval "$(SHELL=/bin/sh lesspipe)"
fi
if command -v dircolors >/dev/null 2>&1; then
  if [ -r "$HOME/.dircolors" ]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    eval "$(dircolors -b)"
  fi
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
if command -v nvim >/dev/null 2>&1; then
  alias v=nvim
fi

# Debian and Ubuntu rename both; the aliases keep one name everywhere.
bat_cmd=$(command -v bat || command -v batcat)
fd_cmd=$(command -v fd || command -v fdfind)
[ "${bat_cmd##*/}" = batcat ] && alias bat=batcat
[ "${fd_cmd##*/}" = fdfind ] && alias fd=fdfind

if command -v fzf >/dev/null 2>&1; then
  # NOTE: fzf --bash needs 0.48; Ubuntu 24.04 ships 0.44, which has only the
  # example script.
  if fzf_init=$(fzf --bash 2>/dev/null); then
    eval "$fzf_init"
  elif [ -r /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    # shellcheck source=/dev/null
    . /usr/share/doc/fzf/examples/key-bindings.bash
  fi
  unset fzf_init
  if [ -n "$fd_cmd" ]; then
    export FZF_DEFAULT_COMMAND="${fd_cmd##*/} --type f"
  elif command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='rg --files'
  fi
  export FZF_DEFAULT_OPTS="--color=bg+:#283457,bg:#1a1b26,border:#27a1b9,fg:#c0caf5\
,gutter:#1a1b26,header:#ff9e64,hl+:#2ac3de,hl:#2ac3de,info:#545c7e,marker:#ff007c\
,pointer:#ff007c,prompt:#2ac3de,query:#c0caf5,scrollbar:#27a1b9,separator:#ff9e64\
,spinner:#ff007c"
fi
unset bat_cmd fd_cmd

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# Arch, then Debian/Ubuntu.
for f in /usr/share/git/completion/git-prompt.sh /usr/lib/git-core/git-sh-prompt; do
  # shellcheck source=/dev/null
  [ -r "$f" ] && . "$f" && break
done
unset f

# ANSI colours, not RGB: tmux's pane-colours turns them into tokyonight's.
if declare -F __git_ps1 >/dev/null; then
  PS1='\[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[35m\]$(__git_ps1 " (%s)")\[\e[0m\]\n\$ '
else
  PS1='\[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\]\n\$ '
fi

if [ -r "$HOME/.bashrc.local" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.bashrc.local"
fi

# Last, so ~/.bashrc.local can set TMUX_AUTO_ATTACH=0 to turn this off.
if [ -n "${SSH_CONNECTION:-}" ] && [ -z "${TMUX:-}" ] && [ -t 0 ] &&
  [ "${TMUX_AUTO_ATTACH:-1}" != 0 ] && command -v tmux >/dev/null 2>&1 &&
  [ -x "$HOME/.config/tmux/sessions/server.sh" ]; then
  exec "$HOME/.config/tmux/sessions/server.sh"
fi
