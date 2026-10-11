-- Leader must be set before any plugin has a chance to map a key.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('core.options')
require('core.keymaps')

-- mini.nvim supplies most features plus MiniMisc.safely, which every file in
-- lua/plugins/ uses to schedule itself. vim.pack (Neovim 0.12) needs no
-- bootstrap: it installs on this call and records the revision in
-- nvim-pack-lock.json, which is tracked alongside this file.
-- The org is nvim-mini, not echasnovski -- the old URL only redirects.
require('core.pack')({ 'https://github.com/nvim-mini/mini.nvim' })

-- Load every file in lua/plugins/. One feature per file, each owning its own
-- add, setup, keymaps and autocmds -- so adding a plugin is creating a
-- file, and a file can never be silently left out. Order here is alphabetical
-- and irrelevant: files schedule themselves with MiniMisc.safely.
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
