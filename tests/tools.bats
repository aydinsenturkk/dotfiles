load test_helper

G=/Applications/Ghostty.app/Contents/MacOS/ghostty
# The macOS default location: Ghostty loads it after XDG (it wins on conflict) and Cmd+, opens it.
GHOSTTY_CONF="$REPO/home/ghostty/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

@test "Ghostty config is valid" {
  [ -f "$GHOSTTY_CONF" ]
  run "$G" +validate-config --config-file="$GHOSTTY_CONF"
  [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "no option-as-alt in Ghostty config (Turkish Q keyboard)" {
  [ -f "$GHOSTTY_CONF" ]   # without the file grep fails too
  run grep -q macos-option-as-alt "$GHOSTTY_CONF"
  [ "$status" -ne 0 ]
}

@test "Ghostty uses GitHub Dark Default with roomy spacing" {
  [ -f "$GHOSTTY_CONF" ]
  "$G" +list-themes 2>/dev/null | grep -qE '^GitHub Dark Default( |$)' || { echo "theme not in Ghostty"; false; }
  for want in 'theme = GitHub Dark Default' 'window-padding-x = 16' 'window-padding-y = 12' \
              'window-padding-balance = true' 'adjust-cell-height = 10%' 'progress-style = false' 'font-size = 16' \
              'working-directory = home' 'window-inherit-working-directory = false'; do
    grep -qxF "$want" "$GHOSTTY_CONF" || { echo "missing: $want"; false; }
  done
}

@test "Ghostty has a single config: no XDG copy in the package" {
  [ ! -e "$REPO/home/ghostty/.config" ]
}

@test "Starship config is read and valid" {
  # print-config returns 0 even without the file; prove the file is read by a value that differs from the default (500).
  run env STARSHIP_CONFIG="$REPO/home/starship/.config/starship.toml" starship print-config command_timeout
  [ "$status" -eq 0 ]
  [[ "$output" == *"command_timeout = 1000"* ]] || { echo "$output"; false; }
}

@test "mise installs the current Node LTS natively" {
  lts=$(mise latest node@lts 2>/dev/null)
  v=$(mise exec -- node -v 2>/dev/null)
  [[ "$v" == "v${lts%%.*}."* ]] || { echo "node: $v, lts: $lts"; false; }
  [ "$(lipo -archs "$(mise which node)")" = "arm64" ]
}

@test "pnpm, go and bun come from mise" {
  for t in pnpm go bun; do
    mise which $t >/dev/null 2>&1 || { echo "missing: $t"; false; }
  done
}

@test "uv finds an arm64 Python" {
  # Ignore an active conda/venv left over from an old shell; the new setup has neither.
  p=$(env -u CONDA_PREFIX -u VIRTUAL_ENV uv python find)
  [ -x "$p" ]
  [[ "$(lipo -archs "$(readlink -f "$p")")" == *arm64* ]]
}

@test "login shell finds node without .zshrc" {
  setup_tmp_home
  link_into_tmp zsh mise
  EXTRA_ENV=(MISE_DATA_DIR="$HOME/.local/share/mise")
  run zsh_in_tmp -lc 'command -v node'
  teardown_tmp_home
  [[ "$output" == *mise* ]] || { echo "node: $output"; false; }
}

@test "yarn (classic) and nest come from mise" {
  # Both were global installs in every nvm Node version; shell history shows yarn 196 and nest 29 uses.
  # `mise exec -- yarn` would also find an old yarn on PATH; check the binary mise installed.
  y=$(mise which yarn 2>/dev/null) || { echo "yarn not installed by mise"; false; }
  [[ "$("$y" --version)" == 1.* ]] || { echo "yarn is not classic: $("$y" --version)"; false; }
  mise which nest >/dev/null 2>&1 || { echo "nest missing"; false; }
}

@test "Ghostty notes are accurate: both files load, spacing needs a new window" {
  # Ghostty also reads XDG (this file loads later and wins on conflict); spacing only changes in a new window.
  grep -q 'wins on conflict' "$GHOSTTY_CONF" || { echo "load order note missing"; false; }
  run grep -qi 'before XDG' "$GHOSTTY_CONF"; [ "$status" -ne 0 ]
  grep -q 'new window' "$GHOSTTY_CONF" || { echo "config: new window note missing"; false; }
  grep -A1 'Ghostty config' "$REPO/README.md" | grep -q 'new window' || { echo "README: new window note missing"; false; }
}

# Neovim (real home; plugins and parsers were installed by `nvim --headless +qa`)
nvim_lua() { nvim --headless -c "lua $1" +qa 2>&1; }

@test "nvim config loads without errors" {
  run --separate-stderr nvim --headless +qa
  [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "status=$status stderr=$stderr"; false; }
}

@test "which-key, fzf-lua and nvim-treesitter are loaded" {
  out=$(nvim_lua 'for _, m in ipairs({"which-key", "fzf-lua", "nvim-treesitter"}) do io.write(m, "=", tostring(package.loaded[m] ~= nil), " ") end')
  [ "$out" = "which-key=true fzf-lua=true nvim-treesitter=true " ] || { echo "$out"; false; }
}

@test "leader maps exist and have descriptions for which-key" {
  for k in f g b r k h '?'; do
    out=$(nvim_lua "io.write(vim.fn.maparg(' $k', 'n', false, true).desc or '')")
    [ -n "$out" ] || { echo "no desc for <leader>$k"; false; }
  done
}

@test "treesitter highlights TypeScript" {
  f=$(mktemp -d)/a.ts; echo 'const a: number = 1' > "$f"
  out=$(nvim --headless -c 'lua io.write(tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil))' +qa "$f" 2>&1)
  rm -r "${f%/*}"
  [ "$out" = "true" ] || { echo "$out"; false; }
}

@test "a filetype without a parser opens without errors" {
  f=$(mktemp -d)/a.unknownext; echo hi > "$f"
  run --separate-stderr nvim --headless -c 'set filetype=nosuchlang' +qa "$f"
  rm -r "${f%/*}"
  [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$stderr"; false; }
}

@test "vim.pack lockfile stays a symlink into the repo when vim.pack writes it" {
  lock=$HOME/.config/nvim/nvim-pack-lock.json
  before=$(stat -f %m "$REPO/home/nvim/.config/nvim/nvim-pack-lock.json")
  sleep 1
  nvim --headless -c "lua vim.pack.update(nil, { offline = true, target = 'lockfile', force = true })" +qa
  [ "$(stat -f %m "$REPO/home/nvim/.config/nvim/nvim-pack-lock.json")" -gt "$before" ] || { echo "vim.pack did not write the lockfile"; false; }
  [ -L "$lock" ]
  [ "$(readlink -f "$lock")" = "$REPO/home/nvim/.config/nvim/nvim-pack-lock.json" ]
}

@test "bootstrap installs nvim plugins and parsers" {
  # The run that installs Homebrew has no /opt/homebrew/bin on PATH; nvim-treesitter needs tree-sitter from there.
  sed -n '/^step_runtimes/,/^}/p' "$REPO/bootstrap.sh" | grep -qF 'PATH=/opt/homebrew/bin:$PATH /opt/homebrew/bin/nvim --headless +qa'
}

@test "headless nvim fails loudly when parsers cannot be built" {
  t=$(mktemp -d); mkdir -p "$t/data/nvim/site"
  ln -s "$HOME/.local/share/nvim/site/pack" "$t/data/nvim/site/pack"   # plugins as installed, parsers missing
  run env XDG_CONFIG_HOME="$REPO/home/nvim/.config" XDG_DATA_HOME="$t/data" XDG_STATE_HOME="$t/state" \
    XDG_CACHE_HOME="$t/cache" PATH=/usr/bin:/bin /opt/homebrew/bin/nvim --headless +qa   # no tree-sitter on PATH
  rm -rf "$t"
  [ "$status" -ne 0 ] || { echo "exit 0 although no parser could be built"; false; }
}

@test "updating nvim-treesitter also updates the parsers (TSUpdate)" {
  out=$(nvim --headless -c "lua vim.api.nvim_create_user_command('TSUpdate', function() io.write('TSUpdate ran') end, { force = true })" \
    -c "lua vim.api.nvim_exec_autocmds('PackChanged', { data = { kind = 'update', active = true, spec = { name = 'nvim-treesitter' }, path = '' } })" +qa 2>&1)
  [[ "$out" == *"TSUpdate ran"* ]] || { echo "$out"; false; }
}

# Bottom bar: the status line as Neovim draws it for the current window
BAR='vim.api.nvim_eval_statusline(vim.o.statusline, {}).str'

@test "bottom bar shows the keys of the current mode and the file name" {
  f=$(mktemp).ts; echo 'let x = 1' > "$f"
  out=$(nvim --headless -c "set columns=200" -c "lua io.write($BAR, '|')" \
    -c "lua vim.api.nvim_feedkeys(vim.keycode('i<Cmd>lua io.write($BAR, \"|\")<CR><Esc>'), 'x', false)" \
    -c "lua vim.api.nvim_feedkeys('v', 'x', false); io.write($BAR)" +qa! "$f" 2>&1)
  IFS='|' read -r normal insert visual <<<"$out"
  [[ "$normal" == *":w save"* && "$normal" == *"Space ? cheat sheet"* && "$normal" == *"$(basename "$f")"* ]] || { echo "normal: $normal"; false; }
  [[ "$insert" == *"Esc normal mode"* && "$insert" != *":w save"* ]] || { echo "insert: $insert"; false; }
  [[ "$visual" == *"y copy"* && "$visual" != *":w save"* ]] || { echo "visual: $visual"; false; }
}

@test "bottom bar drops the hints that do not fit instead of cutting the line" {
  out=$(nvim --headless -c 'set columns=50' -c "lua local s = vim.api.nvim_eval_statusline(vim.o.statusline, {}); io.write(s.width, '|', s.str)" +qa! "$REPO/README.md" 2>&1)
  IFS='|' read -r width bar <<<"$out"
  [ "$width" -le 50 ] && [[ "$bar" == *"README.md"* && "$bar" == *"i insert"* && "$bar" != *"<"* ]] || { echo "$out"; false; }
}

@test "bottom bar of an inactive window shows no key hints" {
  out=$(nvim_lua "vim.cmd('split'); io.write(vim.api.nvim_eval_statusline(vim.o.statusline, { winid = vim.fn.win_getid(2) }).str)")
  [[ -n "$out" && "$out" != *":w save"* ]] || { echo "$out"; false; }
}

@test "bottom bar changes with the mode in a real terminal" {
  t=$(mktemp -d)   # nvim in a pty: press i, then leave; the insert hints must be drawn
  (sleep 2; printf i; sleep 1; printf '\033:qa!\r') | perl -e 'alarm 20; exec @ARGV' script -q "$t/out" nvim "$REPO/README.md" >/dev/null 2>&1
  grep -aq 'delete word' "$t/out" || { echo "insert-mode hints were never drawn"; false; }
}

@test "Space ? opens the cheat sheet in a floating window; the cursor stays in the file; q only closes it" {
  out=$(nvim_lua "vim.fn.maparg(' ?', 'n', false, true).callback(); local sheet; for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative ~= '' then sheet = w end end; local b = vim.api.nvim_win_get_buf(sheet); local text = vim.fn.readfile(vim.fn.stdpath('config') .. '/cheatsheet.txt'); io.write(tostring(vim.api.nvim_get_current_win() ~= sheet), '|', tostring(vim.deep_equal(vim.api.nvim_buf_get_lines(b, 0, -1, false), text) and #text > 10), '|', tostring(vim.bo[b].modifiable), '|', tostring(vim.wo[sheet].number or vim.wo[sheet].relativenumber), '|'); vim.api.nvim_feedkeys('q', 'xt', false); vim.wait(50); io.write(#vim.api.nvim_list_wins(), '|', vim.fn.reg_recording())")
  [ "$out" = "true|true|false|false|1|" ] || { echo "$out"; false; }
}

@test "cheat sheet is linked into the repo" {
  [ "$(readlink -f "$HOME/.config/nvim/cheatsheet.txt")" = "$REPO/home/nvim/.config/nvim/cheatsheet.txt" ]
}

@test "bottom bar shows the keys in their own color and separates the hints" {
  # after a colorscheme reload too: it clears the groups the config made
  out=$(nvim_lua "vim.cmd.colorscheme('default'); local s = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true }); local at, group = s.str:find(':w save', 1, true) - 1; for _, h in ipairs(s.highlights) do if h.start <= at then group = h.group end end; local key, bar = vim.api.nvim_get_hl(0, { name = group, link = false }), vim.api.nvim_get_hl(0, { name = 'StatusLine', link = false }); io.write(tostring(key.fg ~= nil and key.fg ~= bar.fg and key.bg == bar.bg), '|', tostring(s.str:find('save │ :q quit', 1, true) ~= nil))")
  [ "$out" = "true|true" ] || { echo "$out"; false; }
}

@test "cheat sheet fits an 80x24 terminal" {
  out=$(nvim --headless -c 'set columns=80 lines=24' -c "lua vim.fn.maparg(' ?', 'n', false, true).callback(); local sheet; for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative ~= '' then sheet = w end end; local lines, w = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(sheet), 0, -1, false), 0; for _, l in ipairs(lines) do w = math.max(w, vim.fn.strdisplaywidth(l)) end; io.write(vim.api.nvim_win_get_height(sheet), 'x', vim.api.nvim_win_get_width(sheet), ' for ', #lines, 'x', w)" +qa! 2>&1)
  read -r h x w _ n x2 m <<<"${out//x/ x }"
  [ "$h" -ge "$n" ] && [ "$w" -ge "$m" ] || { echo "window $out"; false; }
}

@test "the next key closes the cheat sheet and still runs (Space f opens the picker as usual)" {
  out=$(nvim_lua "vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'a', 'b' }); vim.fn.maparg(' ?', 'n', false, true).callback(); vim.api.nvim_feedkeys('j', 'xt', false); vim.wait(50); io.write(vim.fn.line('.'), '|', #vim.api.nvim_list_wins()); vim.cmd('qa!')")
  [ "$out" = "2|1" ] || { echo "line|windows: $out"; false; }
}

@test "bottom bar keeps the hints for a file deep in a long path" {
  d=$(mktemp -d)/a/very/deep/directory/tree/with/many/levels/for/this/test; mkdir -p "$d"; echo x > "$d/file.ts"
  out=$(nvim --headless -c 'set columns=100' -c "lua io.write($BAR)" +qa! "$d/file.ts" 2>&1)
  [[ "$out" == *"Space ? cheat sheet"* && "$out" == *"file.ts"* ]] || { echo "$out"; false; }
}
