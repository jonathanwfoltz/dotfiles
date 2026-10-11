local safely = require('mini.misc').safely

safely('later', function()
  local files = require('mini.files')
  files.setup()

  vim.keymap.set('n', '<Leader>lf', files.open, { desc = 'List files (explorer)' })
end)
