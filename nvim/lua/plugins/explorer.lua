local later = MiniDeps.later

later(function()
  local files = require('mini.files')
  files.setup()

  vim.keymap.set('n', '<Leader>lf', function() files.open() end,
    { desc = 'List files (explorer)' })
end)
