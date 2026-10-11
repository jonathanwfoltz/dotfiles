local safely = require('mini.misc').safely

-- Neovim 0.12 completes in insert mode on its own, so mini.completion is gone.
-- 'autocomplete' drives the menu, 'complete' names the sources, and the "o"
-- (omnifunc) source is what carries LSP items into it.
safely('later', function()
  vim.o.autocomplete = true
  -- "^5" caps a source at five matches, which is right for buffer words and
  -- wrong for the omnifunc source: that one is the LSP, and capping it silently
  -- truncates the list well under 'pumheight'.
  vim.o.complete = '.^5,w^5,b^5,o'
  -- "popup" shows the documentation window mini.completion used to provide,
  -- backed by 0.12's completionItem/resolve support. Signature help is already
  -- core <C-s>, so nothing here duplicates it.
  vim.o.completeopt = 'menuone,noselect,popup'
  vim.o.pumborder = 'rounded'
  vim.o.pummaxwidth = 80

  -- This file owns its own LspAttach so the feature stays self-contained and
  -- independent of whether plugins/lsp.lua has loaded yet.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_completion', { clear = true }),
    desc = 'Feed LSP completion items to the autocomplete menu',
    callback = function(args)
      -- 'omnifunc' is already vim.lsp.omnifunc on attach, so this is not what
      -- gets LSP items into the menu -- it is what applies a completion's
      -- additionalTextEdits (auto-imports) on accept. 'autocomplete' triggers
      -- on every keystroke, so trigger-character autotriggering adds nothing.
      vim.lsp.completion.enable(true, args.data.client_id, args.buf)
    end,
  })
end)
