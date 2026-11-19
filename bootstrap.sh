#!/bin/zsh
# Single entry point. Every step can be re-run: anything already done is skipped.
#   ./bootstrap.sh              all steps, in order
#   ./bootstrap.sh link hooks   only the selected steps
#   ./bootstrap.sh --macos      also run macos.sh (macOS preferences) after the steps

setopt err_exit no_unset pipe_fail

REPO=${0:A:h}            # the script's own directory, wherever it is called from
STEPS=(clt brew link runtimes hooks)

LINK_PKGS=()             # package names given after the `link` step

usage() {
  print "Usage: ./bootstrap.sh [--help] [--macos] [step...]"
  print "Steps (default order): ${STEPS[*]}"
  print "  link [package...]   link only the given packages (default: everything under home/)"
  print "  --macos             also run macos.sh at the end (Dock, Finder, trackpad preferences)"
}

say() { print -P "%F{green}==>%f $*"; }

# Xcode Command Line Tools: git, compilers.
step_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    say "clt: already installed, skipped"
    return 0
  fi
  xcode-select --install
  print -u2 "clt: the installer window is open; run ./bootstrap.sh again when it finishes."
  return 1
}

# Native Homebrew (/opt/homebrew) and everything in the Brewfile.
step_brew() {
  local brew=/opt/homebrew/bin/brew
  if [[ ! -x $brew ]]; then
    say "brew: installing Homebrew (/opt/homebrew)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # brew bundle adopts apps that already exist in /Applications (--adopt) by itself.
  # --no-upgrade: only installs what is missing, so a second run changes nothing. To update: `brew upgrade`.
  $brew bundle --no-upgrade --file="$REPO/Brewfile"
  # The installer leaves share/ group-writable; compinit then flags it as insecure and prompts on every start.
  chmod go-w /opt/homebrew/share
  say "brew: Brewfile done"
}

# Symlinks the files under home/<package>/ into the target (default ~).
# An existing file or foreign symlink at the target is never deleted; it is moved to a backup directory.
step_link() {
  local target=${${DOTFILES_TARGET:-$HOME}:A}       # :A resolves symlinks such as /var → /private/var (stow needs absolute paths)
  local pkgdir=${${DOTFILES_PACKAGES_DIR:-$REPO/home}:A}
  local backup=${DOTFILES_BACKUP_DIR:-$target/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}
  local stow=${commands[stow]:-/opt/homebrew/bin/stow}
  local -a pkgs=($LINK_PKGS)
  (( ${#pkgs} )) || pkgs=($pkgdir/*(/N:t))

  local pkg src rel dst backed_up=0
  for pkg in $pkgs; do
    if [[ ! -d $pkgdir/$pkg ]]; then
      print -u2 "link: no such package: $pkg"
      return 1
    fi
    for src in ${(f)"$(find "$pkgdir/$pkg" \( -type f -o -type l \) ! -name .DS_Store)"}; do
      rel=${src#$pkgdir/$pkg/}
      dst=$target/$rel
      [[ -e $dst || -L $dst ]] || continue
      # Already ours: a direct symlink, or reached through a folded parent directory that points into the package.
      # A folded one is not backed up; --restow --no-folding below unfolds it.
      [[ ${dst:A} == ${src:A} ]] && continue
      mkdir -p "$backup/${rel:h}"
      mv "$dst" "$backup/$rel"
      say "link: backed up ~/${rel} → $backup/$rel"
      backed_up=1
    done
    # --no-folding: directories such as ~/.config stay real, so other apps never write into the repo.
    $stow --no-folding --restow --ignore='\.DS_Store' -d "$pkgdir" -t "$target" "$pkg"
    say "link: $pkg"
  done
  (( backed_up )) && say "link: old files are in $backup"
  return 0
}

# Language versions: mise (Node, pnpm, Go, Bun; ~/.config/mise/config.toml) and uv (Python).
# On a fresh Mac /opt/homebrew/bin may not be on PATH yet, so the paths are spelled out.
step_runtimes() {
  /opt/homebrew/bin/mise install
  /opt/homebrew/bin/uv python install --default   # --default: also puts python and python3 in ~/.local/bin
  if [[ -x /opt/homebrew/bin/nvim ]]; then /opt/homebrew/bin/nvim --headless +qa; fi   # plugins and parsers (home/nvim)
  say "runtimes: mise, uv and nvim done"
}

# Enables the repo's git hooks (gitleaks).
step_hooks() {
  git -C "$REPO" config core.hooksPath .githooks
  say "hooks: core.hooksPath = .githooks"
}

main() {
  local -a selected=()
  local arg macos=0
  for arg in "$@"; do
    case $arg in
      -h|--help) usage; return 0 ;;
      --macos) macos=1 ;;
      *)
        if (( ${STEPS[(Ie)$arg]} )); then
          selected+=$arg
        elif [[ ${selected[-1]:-} == link ]]; then   # arguments after `link` that are not steps are package names
          LINK_PKGS+=$arg
        else
          print -u2 "Unknown step: $arg"
          usage >&2
          return 2
        fi ;;
    esac
  done
  (( ${#selected} )) || selected=($STEPS)

  local step
  for step in $selected; do
    step_$step
  done
  if (( macos )); then "$REPO/macos.sh"; fi
}

main "$@"
