local add = require('core.pack')
local safely = require('mini.misc').safely

safely('later', function()
  add({
    'https://github.com/MunifTanjim/nui.nvim',
    'https://github.com/m4xshen/hardtime.nvim',
  })

  require('hardtime').setup()
end)
