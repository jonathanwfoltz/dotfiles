local later = MiniDeps.later

later(function()
  local hipatterns = require('mini.hipatterns')
  -- Uses the module return value rather than the MiniExtra global, so this file
  -- does not depend on plugins/pick.lua having loaded first.
  local hi_words = require('mini.extra').gen_highlighter.words

  hipatterns.setup({
    highlighters = {
      todo = hi_words({
        'TODO', 'Todo', 'todo', 'TODO:', 'Todo:', 'todo:',
      }, 'MiniHipatternsTodo'),
      fixme = hi_words({
        'FIXME', 'FixMe', 'Fixme', 'fixme', 'FIXME:', 'FixMe:', 'Fixme:', 'fixme:',
      }, 'MiniHipatternsFixme'),
      hack = hi_words({
        'HACK', 'Hack', 'hack', 'HACK:', 'Hack:', 'hack:',
      }, 'MiniHipatternsHack'),
      note = hi_words({
        'NOTE', 'Note', 'note', 'NOTE:', 'Note:', 'note:',
      }, 'MiniHipatternsNote'),
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })

  vim.keymap.set('n', '<Leader>ph', function()
    require('mini.extra').pickers.hipatterns()
  end, { desc = 'Pick hipatterns (TODO/FIXME/HACK/NOTE)' })
end)
