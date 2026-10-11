local add = require('core.pack')
local safely = require('mini.misc').safely

safely('later', function()
  add({ 'https://github.com/rafamadriz/friendly-snippets' })

  local snippets = require('mini.snippets')
  snippets.setup({
    snippets = { snippets.gen_loader.from_lang() },
  })
end)
