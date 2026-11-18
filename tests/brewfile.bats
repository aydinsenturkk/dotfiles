load test_helper

@test "Brewfile parses" {
  run brew bundle list --file="$REPO/Brewfile" --all; [ "$status" -eq 0 ]
}

@test "dropped tools are not in the Brewfile" {
  [ -f "$REPO/Brewfile" ]   # without the file grep fails too; don't let the test pass for nothing
  for p in '"pyenv"' '"rbenv"' '"ruby-build"' '"nvm"' '"node"' '"node@' '"python@' '"ruby"' '"openssl@1.1"' \
           miniconda docker colima minikube git-credential-manager aerospace iterm2 '^vscode ' '"mysql"' '"postgresql@' '"redis"'; do
    run grep -E "$p" "$REPO/Brewfile"; [ "$status" -ne 0 ] || { echo "found: $p"; false; }
  done
}

@test "core tools are in the Brewfile" {
  for p in stow gitleaks bats-core mise uv starship eza bat fd fzf zoxide ripgrep gh cocoapods \
           zsh-autosuggestions zsh-syntax-highlighting zsh-completions ghostty orbstack tableplus; do
    grep -qE "^(brew|cask) \"$p\"" "$REPO/Brewfile" || { echo "missing: $p"; false; }
  done
}

@test "Homebrew share dir is not group-writable (compinit audit)" {
  # If it is group-writable, compinit flags the directory as insecure and prompts on every start.
  [ -z "$(find /opt/homebrew/share -maxdepth 0 -perm -g+w)" ]
}

@test "bootstrap brew installs missing packages without upgrading" {
  # A second run must change nothing; updating is an explicit `brew upgrade`.
  grep -qE '^[[:space:]]*\$brew bundle .*--no-upgrade' "$REPO/bootstrap.sh"
}
