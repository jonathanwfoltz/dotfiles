local safely = require('mini.misc').safely

safely('later', function()
  -- NOTE: an opt package is inert until loaded -- without this :Undotree does
  -- not exist. Neovim ships it, so nothing is in nvim-pack-lock.json.
  vim.cmd.packadd('nvim.undotree')

  vim.keymap.set('n', '<Leader>vu', '<Cmd>Undotree<CR>', { desc = 'View undo tree' })
end)
