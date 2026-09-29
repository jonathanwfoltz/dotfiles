local safely = require('mini.misc').safely

safely('later', function()
  local hipatterns = require('mini.hipatterns')
  local hi_words = require('mini.extra').gen_highlighter.words

  -- NOTE: gen_highlighter.words matches literally, so each keyword needs its
  -- upper, title and lower forms, with and without a trailing colon. `extra`
  -- carries spellings the derivation cannot produce, such as FixMe.
  local function keyword(word, extra)
    local title = word:sub(1, 1) .. word:sub(2):lower()
    local forms = { word, title, word:lower() }
    vim.list_extend(forms, extra or {})

    local variants = {}
    for _, form in ipairs(forms) do
      table.insert(variants, form)
      table.insert(variants, form .. ':')
    end
    return hi_words(variants, 'MiniHipatterns' .. title)
  end

  hipatterns.setup({
    highlighters = {
      todo = keyword('TODO'),
      fixme = keyword('FIXME', { 'FixMe' }),
      hack = keyword('HACK'),
      note = keyword('NOTE'),
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })

  vim.keymap.set('n', '<Leader>ph', function()
    require('mini.extra').pickers.hipatterns()
  end, { desc = 'Pick hipatterns (TODO/FIXME/HACK/NOTE)' })
end)
