# Only aliases that are actually used. oh-my-zsh's git aliases never showed up in the shell history,
# so they are left out; git commands are typed in full.

if (( $+commands[eza] )); then
  alias ls='eza'
  alias ll='eza -l --git'
  alias tree='eza --tree'
fi
if (( $+commands[bat] )); then alias cat='bat --paging=never'; fi
if (( $+commands[nvim] )); then alias vim='nvim'; fi   # stock vim stays at /usr/bin/vim (and vimtutor)
