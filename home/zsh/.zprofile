# Login shell: Homebrew environment and PATH.
# `zsh -l` started by GUI apps (Fork's git hooks, IDE tasks) reads this file, not .zshrc.

if [[ -x ${HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew ]]; then
  eval "$(${HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew shellenv)"
fi

typeset -U path   # every entry once
path=(
  $HOME/.local/bin
  $HOME/go/bin                                          # binaries from `go install`
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/libpq/bin}    # psql, pg_dump (keg-only); ahead of anything in /usr/local
  $path
)
[[ -r $HOME/.cargo/env ]] && source $HOME/.cargo/env    # rustup
path=($^path(N-/))   # drop directories that don't exist

# mise shims: shells that never read .zshrc still find mise's Node.
if (( $+commands[mise] )); then eval "$(mise activate zsh --shims)"; fi

# OrbStack: docker, kubectl, orb commands and completions. OrbStack manages init.zsh.
# Keep the line exactly as OrbStack wrote it; if it changes, OrbStack may not recognize it and add it again.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
