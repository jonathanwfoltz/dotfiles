local later = MiniDeps.later

later(function()
  -- Required by mini.completion, so it is set here rather than in core/options.
  vim.opt.completeopt = { 'menuone', 'noselect' }

  require('mini.completion').setup({
    lsp_completion = {
      source_func = 'omnifunc',
      auto_setup = true,
    },
  })
end)
