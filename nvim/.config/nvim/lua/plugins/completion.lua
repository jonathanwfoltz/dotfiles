local safely = require('mini.misc').safely

-- Neovim 0.12's native insert-mode completion, in place of mini.completion.
safely('later', function()
  vim.o.autocomplete = true
  -- NOTE: 'o' (the LSP) must stay uncapped -- "^5" truncates it.
  vim.o.complete = '.^5,w^5,b^5,o'
  vim.o.completeopt = 'menuone,noselect,popup'
  vim.o.pumborder = 'rounded'
  vim.o.pummaxwidth = 80

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_completion', { clear = true }),
    desc = 'Feed LSP completion items to the autocomplete menu',
    callback = function(args)
      -- NOTE: 'omnifunc' already carries the items; this applies a
      -- completion's additionalTextEdits (auto-imports) on accept.
      vim.lsp.completion.enable(true, args.data.client_id, args.buf)
    end,
  })
end)
