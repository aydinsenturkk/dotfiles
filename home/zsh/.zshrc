# Interactive shell. Each tool loads only if it is installed, so a fresh Mac starts without errors.

# History and options
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks
setopt extended_history   # timestamps; the existing history uses this format, so they survive when the file is rewritten
setopt interactive_comments no_beep
bindkey -e   # emacs keys (Ctrl+A/E/R); zsh would pick vi mode because EDITOR=nvim contains "vi"

# Completion: compinit once. Full scan at most once a day; other starts use the cache (-C).
[[ -d $HOMEBREW_PREFIX/share/zsh-completions ]] && fpath=($HOMEBREW_PREFIX/share/zsh-completions $fpath)
autoload -Uz compinit
() {
  local dump=$HOME/.cache/zsh/zcompdump
  [[ -d ${dump:h} ]] || mkdir -p ${dump:h}
  local -a fresh=($dump(N.mh-24))
  if (( $#fresh )); then
    compinit -C -d $dump
  else
    compinit -d $dump && touch $dump
  fi
}
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # lowercase input also matches uppercase
zstyle ':completion:*' menu select

# Tools
# fzf's script prints "can't change option: zle" without a terminal (`zsh -ilc`, e.g. VS Code reading the env).
[[ -n $TTY ]] && (( $+commands[fzf] )) && source <(fzf --zsh)  # Ctrl+R: search history
(( $+commands[zoxide] ))   && eval "$(zoxide init zsh)"        # z <dir>
(( $+commands[mise] ))     && eval "$(mise activate zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Plugins; syntax-highlighting must load last.
for f in $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
         $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r $f ]] && source $f
done
unset f

source ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh

# Machine-specific settings and secret values; not in the repo (mode 600).
# `if` form: without the file, startup must not end with status 1.
if [[ -r $HOME/.zshrc.local ]]; then source $HOME/.zshrc.local; fi
