local safely = require('mini.misc').safely

safely('later', function()
  local clue = require('mini.clue')
  local gen = clue.gen_clues

  clue.setup({
    -- NOTE: no bare 'g' trigger. 12 of its 43 entries are unusable --
    -- hardtime.nvim maps eleven g-keys with desc = 'which_key_ignore', which
    -- mini.clue does not implement, and g% has no desc. Neither can be fixed
    -- here: clue precedence is "config clues < buffer mappings < global
    -- mappings", and set_mapping_desc would need this file to run after
    -- workflow.lua. 'gs' covers surround with no noise.
    triggers = {
      { mode = 'n', keys = '<Leader>' },
      { mode = 'x', keys = '<Leader>' },

      -- The one multi-key trigger: both keys must land within 'timeoutlen'.
      { mode = 'n', keys = 'gs' },
      { mode = 'x', keys = 'gs' },

      { mode = 'n', keys = '<C-z>' },

      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },
      { mode = 'x', keys = '[' },
      { mode = 'x', keys = ']' },

      -- No mappings behind these -- the entries come from the generators below.
      { mode = 'n', keys = 'z' },
      { mode = 'x', keys = 'z' },
      { mode = 'n', keys = '<C-w>' },
      { mode = 'n', keys = '"' },
      { mode = 'x', keys = '"' },
      { mode = 'i', keys = '<C-r>' },
      { mode = 'n', keys = "'" },
      { mode = 'x', keys = "'" },
      { mode = 'n', keys = '`' },
      { mode = 'x', keys = '`' },
      { mode = 'i', keys = '<C-x>' },
    },

    clues = {
      -- NOTE: every prefix needs one, single-leaf included -- without a clue
      -- mini.clue labels a prefix by how many mappings sit under it, giving
      -- seven rows of "+1 choice". These name the verb, matching the verb-first
      -- scheme; they are not domain groups.
      { mode = 'n', keys = '<Leader>a', desc = '+Add label' },
      { mode = 'n', keys = '<Leader>c', desc = '+Close' },
      { mode = 'n', keys = '<Leader>d', desc = '+Debug' },
      { mode = 'n', keys = '<Leader>f', desc = '+Format' },
      { mode = 'x', keys = '<Leader>f', desc = '+Format' },
      { mode = 'n', keys = '<Leader>g', desc = '+Git' },
      { mode = 'n', keys = '<Leader>j', desc = '+Jump' },
      { mode = 'x', keys = '<Leader>j', desc = '+Jump' },
      { mode = 'n', keys = '<Leader>l', desc = '+List' },
      { mode = 'n', keys = '<Leader>p', desc = '+Pick' },
      { mode = 'n', keys = '<Leader>r', desc = '+Remove label' },
      { mode = 'n', keys = '<Leader>s', desc = '+Switch' },
      { mode = 'n', keys = '<Leader>t', desc = '+Trim' },
      { mode = 'n', keys = '<Leader>v', desc = '+View' },
      { mode = 'n', keys = 'gs', desc = '+Surround' },
      { mode = 'x', keys = 'gs', desc = '+Surround' },
      { mode = 'n', keys = '<C-z>', desc = '+Resize window' },

      -- gen.g() is omitted: with no 'g' trigger its entries cannot display.
      gen.builtin_completion(),
      gen.marks(),
      gen.registers(),
      gen.square_brackets(),
      gen.windows(),
      gen.z(),
    },

    window = { delay = 300 }, -- default 1000 is long enough to be no help
  })
end)
