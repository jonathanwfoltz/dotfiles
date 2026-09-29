local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add({ source = 'mhartington/formatter.nvim' })

  local prettierd = function(ft)
    return require('formatter.filetypes.' .. ft).prettierd
  end

  require('formatter').setup({
    logging = false,
    filetype = {
      typescript = { prettierd('typescript') },
      typescriptreact = { prettierd('typescriptreact') },
      python = {
        function()
          return { exe = 'ruff', args = { 'format', '-' }, stdin = true }
        end,
      },
      go = {
        function()
          return { exe = 'gofmt', stdin = true }
        end,
      },
    },
  })

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('format_on_save', { clear = true }),
    desc = 'Format the buffer after writing it',
    command = 'FormatWrite',
  })
end)
