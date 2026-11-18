load test_helper

setup() {
  setup_tmp_home
  link_into_tmp zsh
  EXTRA_ENV=()
}

teardown() { teardown_tmp_home; }

@test "interactive startup prints nothing to stderr" {
  run --separate-stderr zsh_in_tmp -il -c exit
  [ "$status" -eq 0 ]
  [ -z "$stderr" ] || { echo "stderr: $stderr"; false; }
}

@test "average startup is under 200 ms" {
  zsh_in_tmp -il -c exit   # warm-up: creates the compinit dump
  ms=$(zsh_in_tmp -c 'zmodload zsh/datetime; s=$EPOCHREALTIME; repeat 5 { HOME='"$TMP_HOME"' /bin/zsh -il -c exit }; print $(( (EPOCHREALTIME-s)*200 ))')
  echo "measured: $ms ms"
  (( ${ms%.*} < 200 ))
}

@test "/opt/homebrew/bin comes before /usr/local/bin and PATH has no duplicates" {
  run zsh_in_tmp -il -c 'print -l $path'
  a=$(grep -n '^/opt/homebrew/bin$' <<<"$output" | cut -d: -f1)
  b=$(grep -n '^/usr/local/bin$' <<<"$output" | cut -d: -f1)
  [ -n "$a" ] || { echo "/opt/homebrew/bin not on PATH"; false; }
  [ -z "$b" ] || [ "$a" -lt "$b" ] || { echo "/usr/local/bin comes first: $output"; false; }
  [ -z "$(sort <<<"$output" | uniq -d)" ] || { echo "duplicates: $(sort <<<"$output" | uniq -d)"; false; }
}

@test "zshrc.local in HOME is loaded" {
  echo 'export DOTFILES_TEST=ok' > "$TMP_HOME/.zshrc.local"
  run zsh_in_tmp -il -c 'print $DOTFILES_TEST'
  [ "$output" = "ok" ]
}

@test "starts cleanly without Homebrew" {
  EXTRA_ENV=(HOMEBREW_PREFIX=/nonexistent)
  run --separate-stderr zsh_in_tmp -il -c exit
  [ "$status" -eq 0 ]
  [ -z "$stderr" ] || { echo "stderr: $stderr"; false; }
}

@test "no secret assignments in any package" {
  [ -d "$REPO/home/zsh" ]   # without the package grep fails too; don't let the test pass for nothing
  run grep -rIE '(SECRET|TOKEN|PASSWORD|API_KEY)[A-Z_]*=' "$REPO/home"
  [ "$status" -ne 0 ] || { echo "$output"; false; }
}

@test "keg-only libpq wins over /usr/local/bin (psql)" {
  run zsh_in_tmp -il -c 'whence -p psql'
  [ "$output" = /opt/homebrew/opt/libpq/bin/psql ] || { echo "psql: $output"; false; }
}

@test "history keeps timestamps" {
  run zsh_in_tmp -il -c '[[ -o extended_history ]]'
  [ "$status" -eq 0 ]
}

@test "zprofile keeps OrbStack's own integration line verbatim" {
  # If changed, OrbStack on a fresh Mac may not recognize the line and add it again.
  grep -qxF 'source ~/.orbstack/shell/init.zsh 2>/dev/null || :' "$REPO/home/zsh/.zprofile"
}

@test "a folder's mise.local.toml sets AWS_PROFILE only inside that folder" {
  mkdir -p "$TMP_HOME/proj"
  printf '[env]\nAWS_PROFILE = "example"\n' > "$TMP_HOME/proj/mise.local.toml"
  EXTRA_ENV=(MISE_TRUSTED_CONFIG_PATHS="$(cd "$TMP_HOME" && pwd -P)/proj")
  run zsh_in_tmp -il -c 'cd proj; print -r -- "in:${AWS_PROFILE:-none}"; cd ..; print -r -- "out:${AWS_PROFILE:-none}"'
  [ "${lines[0]}" = "in:example" ] || { echo "$output"; false; }
  [ "${lines[1]}" = "out:none" ] || { echo "$output"; false; }
}

@test "hushlogin hides the Last login line" {
  # With ~/.hushlogin present, login does not print "Last login: … on ttys00N".
  [ -f "$TMP_HOME/.hushlogin" ] && [ -L "$TMP_HOME/.hushlogin" ]
}
