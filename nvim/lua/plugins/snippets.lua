local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add({ source = 'rafamadriz/friendly-snippets' })

  local snippets = require('mini.snippets')
  snippets.setup({
    snippets = { snippets.gen_loader.from_lang() },
  })
end)
