-- Neovim for quick edits, commit messages and reading code. Not an IDE: no LSP, completion or file tree.
-- Learning: press a key such as g, z, d or Space and wait; which-key lists what can follow.
--   Space ?  cheat sheet   Space k  search every key map   Space h  search help   vimtutor tr  Turkish tutorial

vim.g.mapleader = ' '

vim.o.number = true
vim.o.relativenumber = true    -- distances for counts such as 5j or 3dd
vim.o.ignorecase = true        -- search ignores case ...
vim.o.smartcase = true         -- ... unless the pattern has a capital letter
vim.o.clipboard = 'unnamedplus' -- yank and paste use the macOS clipboard (and Pesty)
vim.o.scrolloff = 8            -- keep some lines visible above and below the cursor

-- Bottom bar: the basic keys of the current mode on the left; file, [+] if modified and line:column on the right.
-- Keys are bold in the accent color, hints are split by │, and hints that don't fit are dropped from the end.
-- Inactive windows show only the right part.
local hints = {
  n = { { 'i', 'insert' }, { ':w', 'save' }, { ':q', 'quit' }, { 'Space ?', 'cheat sheet' }, { 'u', 'undo' },
    { '/', 'search' }, { 'v', 'select' }, { 'dd', 'delete line' }, { 'yy', 'copy line' }, { 'p', 'paste' } },
  i = { { 'Esc', 'normal mode' }, { 'Ctrl+W', 'delete word' }, { 'Ctrl+U', 'delete to line start' } },
  v = { { 'y', 'copy' }, { 'd', 'delete' }, { 'c', 'change' }, { '>', 'indent' }, { '<', 'unindent' }, { 'Esc', 'cancel' } },
  c = { { 'Enter', 'run' }, { 'Tab', 'complete' }, { 'Up', 'previous command' }, { 'Esc', 'cancel' } },
}
local modes = { n = 'NORMAL', i = 'INSERT', v = 'VISUAL', V = 'V-LINE', ['\22'] = 'V-BLOCK', c = 'COMMAND', R = 'REPLACE' }
local function hint_colors()   -- on the bar's background; loading a colorscheme clears them, so they are made again
  local get = function(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
  local bar = get('StatusLine')
  vim.api.nvim_set_hl(0, 'KeyHintMode', { fg = bar.fg, bg = bar.bg, bold = true })
  vim.api.nvim_set_hl(0, 'KeyHintKey', { fg = get('Function').fg, bg = bar.bg, bold = true })
  vim.api.nvim_set_hl(0, 'KeyHintSep', { fg = get('Comment').fg, bg = bar.bg })
end
hint_colors()
vim.api.nvim_create_autocmd('ColorScheme', { callback = hint_colors })
function _G.key_hint_bar()
  local win = vim.api.nvim_get_current_win()   -- %{} runs in the window whose bar is drawn
  local buf, pos = vim.api.nvim_win_get_buf(win), vim.api.nvim_win_get_cursor(win)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':~:.')
  local right = (name == '' and '[No Name]' or name) .. (vim.bo[buf].modified and ' [+]' or '')
    .. '  ' .. pos[1] .. ':' .. pos[2] + 1 .. ' '
  local bar = ''
  if tonumber(vim.g.actual_curwin) == win then   -- the window the cursor is in
    local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
    bar = '%#KeyHintMode# ' .. (modes[mode] or mode) .. ' %*'
    local room = vim.api.nvim_win_get_width(win) - vim.api.nvim_strwidth(' ' .. (modes[mode] or mode) .. ' ' .. right)
    for i, hint in ipairs(hints[({ V = 'v', ['\22'] = 'v' })[mode] or mode] or {}) do
      local sep = i > 1 and ' │ ' or '  '
      local width = vim.api.nvim_strwidth(sep .. hint[1] .. ' ' .. hint[2])
      if width + 1 > room then break end
      bar, room = bar .. '%#KeyHintSep#' .. sep .. '%#KeyHintKey#' .. hint[1] .. '%* ' .. hint[2], room - width
    end
  end
  return (bar .. '%=' .. right:gsub('%%', '%%%%'))
end
vim.o.statusline = '%{%v:lua.key_hint_bar()%}'

-- Plugins via the built-in manager. Revisions are pinned in nvim-pack-lock.json (tracked in the repo).
-- Update: :lua vim.pack.update()   then commit the changed lockfile.
-- A new nvim-treesitter needs matching parsers, so an update of it also runs :TSUpdate.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name ~= 'nvim-treesitter' or ev.data.kind ~= 'update' then return end
    if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
    vim.cmd('TSUpdate')
  end,
})
vim.pack.add({
  'https://github.com/folke/which-key.nvim',
  'https://github.com/ibhagwan/fzf-lua',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
}, { confirm = false })

require('which-key').setup({})
require('fzf-lua').setup({})

-- Tree-sitter highlighting for reading code. Parsers are compiled once (tree-sitter-cli and clang).
-- Headless (`nvim --headless +qa`, run by bootstrap) waits for the install and exits 1 if a parser failed
-- (for example tree-sitter not on PATH, or no working C compiler). Otherwise it runs in the background.
local parsers = {
  'bash', 'css', 'diff', 'dockerfile', 'git_rebase', 'gitcommit', 'go', 'gomod', 'html', 'javascript',
  'json', 'python', 'sql', 'toml', 'tsx', 'typescript', 'yaml',
}
local install = require('nvim-treesitter').install(parsers)
if #vim.api.nvim_list_uis() == 0 and not install:wait(300000) then vim.cmd.cquit() end

vim.api.nvim_create_autocmd('FileType', {
  callback = function() pcall(vim.treesitter.start) end, -- no parser for the filetype: regex syntax stays
})

-- Search (fzf-lua uses fzf, fd and ripgrep)
local fzf = require('fzf-lua')
local map = function(key, fn, desc) vim.keymap.set('n', '<leader>' .. key, fn, { desc = desc }) end
map('f', fzf.files, 'Find file')
map('g', fzf.live_grep, 'Search text in files')
map('b', fzf.buffers, 'Open buffers')
map('r', fzf.oldfiles, 'Recent files')
map('k', fzf.keymaps, 'Search key maps')
map('h', fzf.helptags, 'Search help')

-- Space ?: the basic keys (cheatsheet.txt) in a floating window; q or Esc closes it.
map('?', function()
  local lines = vim.fn.readfile(vim.fn.stdpath('config') .. '/cheatsheet.txt')
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable, vim.bo[buf].bufhidden = false, 'wipe'
  local width = math.min(vim.o.columns - 4, math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, lines))))
  local height = math.min(vim.o.lines - 4, #lines)
  vim.api.nvim_open_win(buf, true, { relative = 'editor', width = width, height = height, style = 'minimal',
    row = math.floor((vim.o.lines - height) / 2), col = math.floor((vim.o.columns - width) / 2),
    border = 'rounded', title = ' Cheat sheet  (q closes) ', title_pos = 'center' })
  for _, key in ipairs({ 'q', '<Esc>' }) do vim.keymap.set('n', key, '<Cmd>close<CR>', { buffer = buf }) end
end, 'Cheat sheet of the basic keys')
