local safely = require('mini.misc').safely

safely('later', function()
  require('mini.indentscope').setup({ symbol = '│' }) -- default is a dashed ╎

  -- setup() only highlights trailing whitespace; trim() is the half that acts.
  local trailspace = require('mini.trailspace')
  trailspace.setup()

  vim.keymap.set('n', '<Leader>tw', trailspace.trim,
    { desc = 'Trim trailing whitespace' })
end)
