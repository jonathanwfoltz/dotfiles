local safely = require('mini.misc').safely

-- 'now' rather than 'later': all three affect first paint.
safely('now', function()
  require('mini.icons').setup({ style = 'glyph' })
  require('mini.statusline').setup()
  require('mini.tabline').setup() -- sets 'showtabline' itself
end)
