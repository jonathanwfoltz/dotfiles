local safely = require('mini.misc').safely

safely('later', function()
  local bufremove = require('mini.bufremove')
  bufremove.setup()

  -- NOTE: not :bdelete, which closes the window along with the buffer.
  vim.keymap.set('n', '<Leader>cb', function() bufremove.delete() end,
    { desc = 'Close buffer' })
end)
