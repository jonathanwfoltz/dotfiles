local now = MiniDeps.now

-- Affects first paint, so it runs immediately rather than deferred.
now(function()
  require('mini.icons').setup({ style = 'glyph' })
  require('mini.statusline').setup()
end)
