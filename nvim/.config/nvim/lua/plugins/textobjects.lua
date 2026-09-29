local safely = require('mini.misc').safely

safely('later', function()
  require('mini.ai').setup({
    -- NOTE: emptied so 0.12's v_an/v_in incremental node selection keeps the
    -- keys. al/il and g[/g] are untouched.
    mappings = { around_next = '', inside_next = '' },
  })
end)
