local safely = require('mini.misc').safely

safely('later', function()
  require('mini.indentscope').setup()
  require('mini.trailspace').setup()
end)
