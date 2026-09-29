-- Leader must be set before any plugin has a chance to map a key.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set('', '<Space>', '<Nop>', { noremap = true, silent = true })

require('core.options')
require('core.keymaps')

-- Bootstrap mini.nvim, which supplies mini.deps for every other plugin.
local path_package = vim.fn.stdpath('data') .. '/site'
local mini_path = path_package .. '/pack/deps/start/mini.nvim'
if not vim.uv.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim', mini_path,
  })
  vim.cmd('packadd mini.nvim | helptags ALL')
end
require('mini.deps').setup({ path = { package = path_package } })

-- Load every file in lua/plugins/. One feature per file, each owning its own
-- MiniDeps.add, setup, keymaps and autocmds -- so adding a plugin is creating a
-- file, and a file can never be silently left out. Order here is alphabetical
-- and irrelevant: files schedule themselves with MiniDeps.now/later.
local plugin_dir = vim.fn.stdpath('config') .. '/lua/plugins'
local names = {}
for name, entry_type in vim.fs.dir(plugin_dir) do
  if entry_type == 'file' and name:sub(-4) == '.lua' then
    table.insert(names, name:sub(1, -5))
  end
end
table.sort(names)

for _, name in ipairs(names) do
  local ok, err = pcall(require, 'plugins.' .. name)
  if not ok then
    vim.notify(('plugins.%s failed to load\n%s'):format(name, err), vim.log.levels.ERROR)
  end
end
