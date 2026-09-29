local safely = require('mini.misc').safely

-- Three text operators, none needing a leader key.
safely('later', function()
  -- NOTE: on 'gs' rather than upstream's 's'. On 's', substitute-char becomes a
  -- prefix and plain 's' stalls for the full 'timeoutlen'. 'gs' is :sleep.
  require('mini.surround').setup({
    mappings = {
      add = 'gsa',
      delete = 'gsd',
      find = 'gsf',
      find_left = 'gsF',
      highlight = 'gsh',
      replace = 'gsr',
      suffix_last = 'l',
      suffix_next = 'n',
    },
  })

  require('mini.splitjoin').setup() -- gS
  require('mini.move').setup() -- <M-h/j/k/l>
end)
