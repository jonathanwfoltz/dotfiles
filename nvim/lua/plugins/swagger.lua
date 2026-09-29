local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add({ source = 'vinnymeller/swagger-preview.nvim' })

  require('swagger-preview').setup({
    port = 8000,
    host = 'localhost',
  })
end)
