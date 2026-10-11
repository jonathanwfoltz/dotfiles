local safely = require('mini.misc').safely

-- Affects first paint, so it runs immediately rather than deferred.
safely('now', function()
  require('mini.icons').setup({ style = 'glyph' })
  require('mini.statusline').setup()
end)
