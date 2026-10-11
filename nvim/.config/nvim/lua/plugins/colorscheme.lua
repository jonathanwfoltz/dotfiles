local add = require('core.pack')
local safely = require('mini.misc').safely

safely('now', function()
  add({ 'https://github.com/folke/tokyonight.nvim' })

  if not pcall(vim.cmd.colorscheme, 'tokyonight-night') then
    vim.notify('Colorscheme tokyonight-night not found', vim.log.levels.WARN)
  end
end)
