local safely = require('mini.misc').safely

safely('later', function()
  -- Default symbol is the dashed '╎'; '│' draws a solid line instead.
  require('mini.indentscope').setup({ symbol = '│' })
  -- setup() only highlights trailing whitespace; trim() is the half that acts
  -- on it, and conform covers nothing outside ts/tsx/python/go.
  local trailspace = require('mini.trailspace')
  trailspace.setup()

  vim.keymap.set('n', '<Leader>tw', trailspace.trim,
    { desc = 'Trim trailing whitespace' })
end)
