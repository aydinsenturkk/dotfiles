# Acceptance tests: run against the real HOME.
load test_helper

# A clean login shell like the one Ghostty opens: launchd's PATH, starting in HOME.
# Nothing from the calling session's environment leaks in.
real_shell() {
  ( cd "$HOME" && env -i HOME="$HOME" USER="$USER" TERM=xterm-256color LC_ALL=en_US.UTF-8 \
      PATH=/usr/bin:/bin:/usr/sbin:/sbin GIT_TERMINAL_PROMPT=0 /bin/zsh "$@" )
}

@test "startup is under 200 ms" {
  real_shell -il -c exit
  ms=$(real_shell -c 'zmodload zsh/datetime; s=$EPOCHREALTIME; repeat 5 { /bin/zsh -il -c exit }; print $(( (EPOCHREALTIME-s)*200 ))')
  echo "measured: $ms ms"
  (( ${ms%.*} < 200 ))
}

@test "interactive startup prints nothing to stderr" {
  run --separate-stderr real_shell -il -c exit
  [ "$status" -eq 0 ]
  [ -z "$stderr" ] || { echo "stderr: $stderr"; false; }
}

@test "Homebrew is native" {
  run real_shell -il -c 'brew config'
  [[ "$output" == *"HOMEBREW_PREFIX: /opt/homebrew"* ]]
  [[ "$output" == *"Rosetta 2: false"* ]]
}

@test "dev binaries are arm64" {
  # -i: mise activate gives the real install path (not the shim)
  for b in node go gh git rustc cargo docker; do
    p=$(real_shell -il -c "whence -p $b" 2>/dev/null)
    a=$(lipo -archs "$(readlink -f "$p")" 2>/dev/null)
    [[ "$a" == *arm64* ]] || { echo "$b → $p [$a]"; false; }
  done
  p=$(real_shell -il -c 'uv python find' 2>/dev/null)
  [[ "$(lipo -archs "$(readlink -f "$p")")" == *arm64* ]] || { echo "python → $p"; false; }
}

@test "Intel Homebrew is removed" {
  [ ! -e /usr/local/bin/brew ]
  [ ! -d /usr/local/Homebrew ]
}

@test "every variable in zshrc.local is loaded and the file is mode 600" {
  [ "$(stat -f %Lp "$HOME/.zshrc.local")" = 600 ]
  # Only names are read (never values); the names are not written in the repo.
  names=($(grep -oE '^[[:space:]]*export[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$HOME/.zshrc.local" | awk '{print $2}'))
  [ "${#names[@]}" -gt 0 ]
  for n in "${names[@]}"; do
    run real_shell -il -c "print \${+$n}"
    [ "$output" = 1 ] || { echo "not loaded: $n"; false; }
  done
}

@test "git uses the XDG config and gh for GitHub" {
  [ ! -e "$HOME/.gitconfig" ]   # if present, it shadows the XDG config
  run real_shell -il -c 'git config --show-origin user.email'
  [[ "$output" == *"/.config/git/config"* ]] || { echo "$output"; false; }
  # Count lines only; the token is never printed.
  run real_shell -il -c "printf 'protocol=https\nhost=github.com\n\n' | git credential fill 2>/dev/null | grep -c '^password='"
  [ "$output" = 1 ]
}

@test "bootstrap link a second time changes nothing" {
  before=$(ls -1 "$HOME/.dotfiles-backup" 2>/dev/null | wc -l)
  run "$REPO/bootstrap.sh" link
  [ "$status" -eq 0 ]
  [ "$(ls -1 "$HOME/.dotfiles-backup" 2>/dev/null | wc -l)" -eq "$before" ]
  brew bundle check --no-upgrade --file="$REPO/Brewfile"   # outdated is fine: bootstrap never upgrades
}

@test "no secrets in repo history" {
  run gitleaks git "$REPO" --redact --no-banner
  [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "docker runs on OrbStack" {
  run real_shell -il -c 'docker context show'
  [ "$output" = orbstack ] || { echo "context: $output"; false; }
  run real_shell -il -c 'docker run --rm hello-world'
  [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "docker compose and buildx do not depend on Docker Desktop" {
  # Docker Desktop's ~/.docker/cli-plugins links pointed into Docker.app; after removing it, OrbStack's must remain.
  for p in docker-compose docker-buildx; do
    t=$(readlink "$HOME/.docker/cli-plugins/$p" || true)
    [[ "$t" != /Applications/Docker.app/* ]] || { echo "$p → $t"; false; }
  done
  real_shell -il -c 'docker compose version && docker buildx version' >/dev/null
}

@test "python and python3 come from uv" {
  for b in python python3; do
    p=$(real_shell -il -c "whence -p $b" 2>/dev/null)
    [[ "$p" == "$HOME/.local/bin/"* ]] || { echo "$b → ${p:-none}"; false; }
  done
}

@test "secret names from this machine appear nowhere in the repo history" {
  # Names are read from this machine at test time and never listed in the repo. Values are never read.
  names=($(grep -oE '^[[:space:]]*export[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$HOME/.zshrc.local" | awk '{print $2}'))
  names+=($(cd "$HOME" && ls -A | grep -E 'token|-key$|\.pem$'))
  names+=($(ls "$HOME/.ssh" | grep -vE '^(known_hosts.*|config|authorized_keys|agent)$' | grep -v '\.pub$'))
  [ "${#names[@]}" -gt 0 ]
  hist=$(git -C "$REPO" log --all -p)
  bad=0; for n in "${names[@]}"; do grep -qF -- "$n" <<<"$hist" && { echo "in history: $n"; bad=1; }; done
  [ "$bad" -eq 0 ]
}

@test "Ghostty reads the repo config from the macOS default location" {
  f="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  [ -L "$f" ] || { echo "not a symlink; an editor opened via Cmd+, may have replaced it"; false; }
  [ "$(realpath "$f")" = "$(realpath "$REPO/home/ghostty/Library/Application Support/com.mitchellh.ghostty/config.ghostty")" ]
  # Ghostty reads and merges all of these; if one exists, a setting silently lives outside the dotfiles.
  # (-L: a dangling old symlink counts too.)
  for p in "$HOME/.config/ghostty/config" "$HOME/.config/ghostty/config.ghostty" \
           "$HOME/Library/Application Support/com.mitchellh.ghostty/config"; do
    [ ! -e "$p" ] && [ ! -L "$p" ] || { echo "second config file: $p"; false; }
  done
  /Applications/Ghostty.app/Contents/MacOS/ghostty +show-config 2>/dev/null | grep -qxF 'theme = GitHub Dark Default'
}
