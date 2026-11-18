load test_helper

setup() {
  setup_tmp_home
  PKGS=$(mktemp -d); export DOTFILES_PACKAGES_DIR=$PKGS
  mkdir -p "$PKGS/demo/.config/demo"
  echo new > "$PKGS/demo/.democonf"
  echo conf > "$PKGS/demo/.config/demo/conf"
}

teardown() {
  teardown_tmp_home
  [[ "$PKGS" == "${TMPDIR:-/tmp}"* ]] && rm -rf "$PKGS"
  return 0
}

@test "files are linked as symlinks" {
  run "$REPO/bootstrap.sh" link demo; [ "$status" -eq 0 ]
  [ -L "$TMP_HOME/.democonf" ]; [ "$(cat "$TMP_HOME/.democonf")" = "new" ]
}

@test "directories are not folded" {
  "$REPO/bootstrap.sh" link demo
  [ -d "$TMP_HOME/.config" ]; [ ! -L "$TMP_HOME/.config" ]; [ ! -L "$TMP_HOME/.config/demo" ]
  [ -L "$TMP_HOME/.config/demo/conf" ]
}

@test "an existing real file is backed up" {
  echo old > "$TMP_HOME/.democonf"
  "$REPO/bootstrap.sh" link demo
  [ -L "$TMP_HOME/.democonf" ]; [ "$(cat "$TMP_HOME"/.dotfiles-backup/*/.democonf)" = "old" ]
}

@test "a foreign symlink is backed up" {
  ln -s /etc/hosts "$TMP_HOME/.democonf"
  "$REPO/bootstrap.sh" link demo
  [ "$(cat "$TMP_HOME/.democonf")" = "new" ]; [ -L "$TMP_HOME"/.dotfiles-backup/*/.democonf ]
}

@test "second run changes nothing" {
  "$REPO/bootstrap.sh" link demo
  run "$REPO/bootstrap.sh" link demo; [ "$status" -eq 0 ]
  [ ! -e "$TMP_HOME/.dotfiles-backup" ]
}

@test "works from another directory" {
  run sh -c "cd / && '$REPO/bootstrap.sh' link demo"; [ "$status" -eq 0 ]
  [ -L "$TMP_HOME/.democonf" ]
}

@test "a folded parent symlink is unfolded without moving package files" {
  # Plain `stow` (without --no-folding) folds ~/.config/demo into a single symlink to the package.
  mkdir -p "$TMP_HOME/.config"
  stow -d "$(cd "$PKGS" && pwd -P)" -t "$(cd "$TMP_HOME" && pwd -P)" demo
  [ -L "$TMP_HOME/.config/demo" ]
  run "$REPO/bootstrap.sh" link demo
  [ "$status" -eq 0 ]
  [ -f "$PKGS/demo/.config/demo/conf" ] || { echo "package file was moved"; false; }
  [ ! -L "$TMP_HOME/.config/demo" ]; [ -L "$TMP_HOME/.config/demo/conf" ]
  [ ! -e "$TMP_HOME/.dotfiles-backup" ]
}

@test ".DS_Store files in packages are ignored" {
  touch "$PKGS/demo/.DS_Store" "$PKGS/demo/.config/demo/.DS_Store"
  echo finder > "$TMP_HOME/.DS_Store"
  run "$REPO/bootstrap.sh" link demo
  [ "$status" -eq 0 ]
  [ ! -L "$TMP_HOME/.DS_Store" ]; [ "$(cat "$TMP_HOME/.DS_Store")" = finder ]
  [ ! -e "$TMP_HOME/.config/demo/.DS_Store" ]
  [ ! -e "$TMP_HOME/.dotfiles-backup" ]
}

@test "files under a folder with a space are linked and Library stays a real folder" {
  mkdir -p "$PKGS/demo/Library/Application Support/demo"
  echo spaced > "$PKGS/demo/Library/Application Support/demo/conf"
  run "$REPO/bootstrap.sh" link demo
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  [ -d "$TMP_HOME/Library" ] && [ ! -L "$TMP_HOME/Library" ]
  [ ! -L "$TMP_HOME/Library/Application Support" ] && [ ! -L "$TMP_HOME/Library/Application Support/demo" ]
  [ -L "$TMP_HOME/Library/Application Support/demo/conf" ]
  [ "$(cat "$TMP_HOME/Library/Application Support/demo/conf")" = spaced ]
}

@test "an app's own template under Application Support is backed up, not deleted" {
  mkdir -p "$PKGS/demo/Library/Application Support/demo" "$TMP_HOME/Library/Application Support/demo"
  echo repo > "$PKGS/demo/Library/Application Support/demo/conf"
  echo template > "$TMP_HOME/Library/Application Support/demo/conf"
  run "$REPO/bootstrap.sh" link demo
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  [ "$(cat "$TMP_HOME/Library/Application Support/demo/conf")" = repo ]
  [ "$(cat "$TMP_HOME"/.dotfiles-backup/*/"Library/Application Support/demo/conf")" = template ]
}
