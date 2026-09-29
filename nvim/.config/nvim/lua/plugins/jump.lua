local safely = require('mini.misc').safely

safely('later', function()
  local jump2d = require('mini.jump2d')

  -- NOTE: load-bearing, not tidying. Its default <CR> would shadow Enter in a
  -- quickfix window, which the editor special-cases rather than maps.
  jump2d.setup({ mappings = { start_jumping = '' } })

  vim.keymap.set({ 'n', 'x', 'o' }, '<Leader>js', function() jump2d.start() end,
    { desc = 'Jump to spot' })
end)
