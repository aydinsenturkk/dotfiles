# Shared test helpers. Every .bats file loads them with `load test_helper`.

bats_require_minimum_version 1.5.0   # for run --separate-stderr

# Tests use the native Homebrew tools (not Intel /usr/local).
export PATH="/opt/homebrew/bin:$PATH"

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# A temporary HOME instead of the real ~. bootstrap.sh link links into it.
setup_tmp_home() {
  TMP_HOME="$(mktemp -d)"
  export TMP_HOME DOTFILES_TARGET="$TMP_HOME"
  # The real .zshenv points this at the real ~/.config; keep it out of the tests.
  unset XDG_CONFIG_HOME
}

# Links packages into the temporary HOME: link_into_tmp zsh git ...
link_into_tmp() {
  DOTFILES_TARGET=$TMP_HOME "$REPO/bootstrap.sh" link "$@"
}

# Runs a zsh in the temporary HOME, isolated from the user's environment: zsh_in_tmp -il -c exit
# Extra variables per test: EXTRA_ENV=(KEY=VAL ...)
# Starts in HOME like a real terminal; otherwise mise walks up from the cwd and treats the real ~/.config/mise
# as an untrusted project config.
zsh_in_tmp() {
  ( cd "$TMP_HOME" && env -i HOME="$TMP_HOME" TERM=xterm-256color LC_ALL=en_US.UTF-8 PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    ${EXTRA_ENV[@]+"${EXTRA_ENV[@]}"} /bin/zsh "$@" )
}

teardown_tmp_home() {
  # Only delete the temporary directory mktemp handed out.
  [[ -n "${TMP_HOME:-}" && "$TMP_HOME" == "${TMPDIR:-/tmp}"* && -d "$TMP_HOME" ]] && rm -rf "$TMP_HOME"
  return 0
}
