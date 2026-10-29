local add = require('core.pack')
local safely = require('mini.misc').safely

safely('later', function()
  add({
    'https://github.com/MunifTanjim/nui.nvim',
    'https://github.com/m4xshen/hardtime.nvim',
  })

  -- NOTE: hardtime maps <CR> and eleven g-keys with desc = 'which_key_ignore',
  -- which plugins/jump.lua and plugins/clue.lua are built around. Its <CR> is
  -- an expr mapping that re-executes the key, so quickfix still works.

  -- Stricter than the defaults, which allow j/k for short hops: max_count 3
  -- and max_time 1000 mean three presses, and any pause over a second starts
  -- the allowance over. allow_different_key compares against the previous
  -- keystroke, so alternating j/k resets the count on every press.
  require('hardtime').setup({
    max_count = 2, -- the third repeat is blocked
    max_time = 2000, -- the allowance survives a pause, so pacing is no escape
    allow_different_key = false, -- one budget across h/j/k/l, not one per key
  })
end)
