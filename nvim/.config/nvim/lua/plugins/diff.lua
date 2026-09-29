local safely = require('mini.misc').safely

safely('later', function()
  local diff = require('mini.diff')
  diff.setup()

  -- The overlay is the one feature with no default mapping.
  vim.keymap.set('n', '<Leader>vd', function() diff.toggle_overlay(0) end,
    { desc = 'View diff overlay' })
end)
