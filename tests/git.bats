load test_helper

setup() {
  setup_tmp_home
  link_into_tmp git
  export HOME=$TMP_HOME
}

teardown() { teardown_tmp_home; }

@test "identity and defaults" {
  [ "$(git config --global user.name)" = "Aydın Şentürk" ]
  [[ "$(git config --global user.email)" == *@* ]]
  [ "$(git config --global init.defaultBranch)" = "main" ]
  [ "$(git config --global push.autoSetupRemote)" = "true" ]
}

@test "GitHub credentials go through gh" {
  for host in github.com gist.github.com; do
    [ "$(git config --global --get-all credential.https://$host.helper | tail -1)" = "!gh auth git-credential" ]
  done
}

@test "no GCM or Azure leftovers and no absolute paths" {
  [ -f "$REPO/home/git/.config/git/config" ]   # without the file grep fails too; don't let the test pass for nothing
  run grep -iE 'credential-manager|azure|/usr/local|/opt/homebrew' "$REPO/home/git/.config/git/config"
  [ "$status" -ne 0 ]
}

@test "global ignore excludes .DS_Store and Claude Code local files" {
  r=$TMP_HOME/repo; git init -q "$r"
  mkdir -p "$r/.claude"; touch "$r/.DS_Store" "$r/.claude/settings.local.json"
  git -C "$r" check-ignore -q .DS_Store
  git -C "$r" check-ignore -q .claude/settings.local.json
}

@test "git config --global keeps the symlink" {
  before=$(cat "$REPO/home/git/.config/git/config")
  git config --global dotfiles.test 1
  [ -L "$TMP_HOME/.config/git/config" ]
  git config --global --remove-section dotfiles
  [ "$(cat "$REPO/home/git/.config/git/config")" = "$before" ]   # the repo file is back to its original content
}

@test "global ignore excludes machine-local mise files" {
  r=$TMP_HOME/repo; git init -q "$r"
  touch "$r/mise.local.toml" "$r/.mise.local.toml"
  git -C "$r" check-ignore -q mise.local.toml
  git -C "$r" check-ignore -q .mise.local.toml
}
