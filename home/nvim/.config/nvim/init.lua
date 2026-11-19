-- Neovim for quick edits, commit messages and reading code. Not an IDE: no LSP, completion or file tree.
-- Learning: press a key such as g, z, d or Space and wait; which-key lists what can follow.
--   Space k  search every key map      Space h  search help      vimtutor tr  the Turkish vim tutorial

vim.g.mapleader = ' '

vim.o.number = true
vim.o.relativenumber = true    -- distances for counts such as 5j or 3dd
vim.o.ignorecase = true        -- search ignores case ...
vim.o.smartcase = true         -- ... unless the pattern has a capital letter
vim.o.clipboard = 'unnamedplus' -- yank and paste use the macOS clipboard (and Pesty)
vim.o.scrolloff = 8            -- keep some lines visible above and below the cursor

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
