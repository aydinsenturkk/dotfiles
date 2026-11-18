load test_helper

@test "README describes every bootstrap step" {
  [ -f "$REPO/README.md" ]
  for s in clt brew link runtimes hooks --macos; do
    grep -q -- "$s" "$REPO/README.md" || { echo "missing: $s"; false; }
  done
}

@test "README names no secret files or variables" {
  [ -f "$REPO/README.md" ]
  run grep -nE '_SECRET|_TOKEN|_API_KEY|\.[a-z0-9-]+-(token|key)([^a-z]|$)|\.pem|\.ssh/[A-Za-z0-9_]+|ghp_|ctx7sk-' "$REPO/README.md"
  [ "$status" -ne 0 ] || { echo "$output"; false; }
}

@test "README fits on one page (at most 120 lines)" {
  [ -f "$REPO/README.md" ]
  [ "$(wc -l < "$REPO/README.md")" -le 120 ]
}

@test "README fresh-Mac steps install CLT before cloning and open a new terminal" {
  c=$(grep -n 'xcode-select --install' "$REPO/README.md" | head -1 | cut -d: -f1)
  g=$(grep -nE 'git clone|gh repo clone' "$REPO/README.md" | head -1 | cut -d: -f1)
  [ -n "$c" ] && [ -n "$g" ] && [ "$c" -lt "$g" ] || { echo "CLT: $c, clone: $g"; false; }
  grep -qi 'new terminal window' "$REPO/README.md"
}

@test "README explains per-project AWS profiles" {
  grep -q 'AWS_PROFILE' "$REPO/README.md"
  grep -q 'mise.local.toml' "$REPO/README.md"
}

@test "LICENSE is MIT" {
  grep -q 'MIT License' "$REPO/LICENSE"
  grep -q 'Copyright (c) 2026' "$REPO/LICENSE"
}

@test "README tells readers to fork and edit before using it" {
  grep -qi 'fork' "$REPO/README.md"
  grep -q 'home/git/.config/git/config' "$REPO/README.md"
}

@test "README gives a test command that is safe on any Mac" {
  grep -qF 'bats tests/{repo,link,zsh,git,readme,brewfile}.bats' "$REPO/README.md"
  grep -qi 'real `~`' "$REPO/README.md"
}

@test "docs never suggest a brew bundle that upgrades" {
  # `brew bundle` upgrades by default; the repo's rule is install-only, upgrades are explicit.
  run grep -nE 'brew bundle --file' "$REPO/README.md" "$REPO/Brewfile"
  [ "$status" -ne 0 ] || { echo "$output"; false; }
}

@test "README states the macOS requirement" {
  grep -q 'macOS 15' "$REPO/README.md"
}
