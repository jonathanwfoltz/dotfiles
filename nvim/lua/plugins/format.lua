local add = require('core.pack')
local safely = require('mini.misc').safely

safely('later', function()
  add({ 'https://github.com/stevearc/conform.nvim' })

  -- conform ships the prettierd, ruff and gofmt definitions, so nothing here
  -- has to spell out an exe/args/stdin table. format_on_save runs on
  -- BufWritePre; the old formatter.nvim wiring ran :FormatWrite on BufWritePost,
  -- which wrote the buffer a second time after the write that triggered it.
  require('conform').setup({
    formatters_by_ft = {
      typescript = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      python = { 'ruff_format' },
      go = { 'gofmt' },
    },
    format_on_save = { timeout_ms = 500, lsp_format = 'fallback' },
  })
end)
