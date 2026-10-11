local add = require('core.pack')
local safely = require('mini.misc').safely

safely('later', function()
  add({ 'https://github.com/vinnymeller/swagger-preview.nvim' })

  -- setup() indexes its argument unconditionally, so the table is required
  -- even though port 8000 and host localhost are the plugin's own defaults.
  require('swagger-preview').setup({})
end)
