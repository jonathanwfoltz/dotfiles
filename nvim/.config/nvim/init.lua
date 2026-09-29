-- NOTE: must stay first -- vim.pack is 0.12-only, and below that this would
-- error here and again for all 22 plugin files. Returning stops sourcing.
if vim.fn.has('nvim-0.12') == 0 then
  local v = vim.version()
  vim.notify(
    ('This config needs Neovim 0.12 or newer for vim.pack; this is %d.%d.%d')
      :format(v.major, v.minor, v.patch),
    vim.log.levels.ERROR
  )
  return
end

vim.loader.enable()

-- Leader must be set before any plugin can map a key.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('core.options')
require('core.keymaps')

-- Supplies most features plus MiniMisc.safely, which every plugin file uses.
-- NOTE: the org is nvim-mini, not echasnovski -- the old URL only redirects.
require('core.pack')({ 'https://github.com/nvim-mini/mini.nvim' })

-- Directory scan rather than a list, so a plugin cannot be silently left out.
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
