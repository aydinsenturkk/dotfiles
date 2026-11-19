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

@test "merge, rebase and diff defaults" {
  [ "$(git config --global pull.rebase)" = "true" ]
  [ "$(git config --global rebase.autoStash)" = "true" ]
  [ "$(git config --global fetch.prune)" = "true" ]
  [ "$(git config --global rerere.enabled)" = "true" ]
  [ "$(git config --global diff.algorithm)" = "histogram" ]
  [ "$(git config --global diff.colorMoved)" = "default" ]
  [ "$(git config --global merge.conflictStyle)" = "zdiff3" ]
  [ "$(git config --global branch.sort)" = "-committerdate" ]
}

@test "delta is the pager" {
  [ "$(git config --global core.pager)" = "delta" ]
  [ "$(git config --global interactive.diffFilter)" = "delta --color-only" ]
  [ "$(git config --global delta.navigate)" = "true" ]
  [ "$(git config --global delta.line-numbers)" = "true" ]
  [ "$(git config --global delta.dark)" = "true" ]
}

@test "piped git diff has no color codes (what Claude Code and other tools see)" {
  r=$TMP_HOME/repo; git init -q "$r"
  echo one > "$r/f"; git -C "$r" add f; git -C "$r" -c user.name=t -c user.email=t@t commit -qm init
  echo two > "$r/f"
  out=$(git -C "$r" diff | cat)
  [[ $out == *two* ]] || { echo "no diff: $out"; false; }
  [[ $out != *$'\e'* ]] || { echo "color codes in piped output"; false; }
}
