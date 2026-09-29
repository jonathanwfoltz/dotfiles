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
  require('hardtime').setup()
end)
