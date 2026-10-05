local add = require('core.pack')
local safely = require('mini.misc').safely

-- eslint is a language server here rather than nvim-lint + eslint_d: it
-- publishes the same diagnostics, only attaches in a project that has an
-- eslint config, and needs no guard against a missing executable.
local servers = {
  'cssls', 'ts_ls', 'html', 'tailwindcss', 'pyright', 'gopls', 'eslint',
}

safely('later', function()
  add({
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    'https://github.com/neovim/nvim-lspconfig',
  })

  require('mason').setup()
  require('mason-lspconfig').setup({ ensure_installed = servers })

  -- Per-server settings live in nvim/lsp/<name>.lua, which Neovim reads
  -- natively and merges over the defaults nvim-lspconfig ships. Servers needing
  -- no settings have no file. tailwindcss was previously installed but never
  -- enabled; listing it here is what actually starts it.
  vim.lsp.enable(servers)

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
    desc = 'Buffer-local LSP keymaps',
    callback = function(args)
      -- Neovim already provides grn (rename), gra (code action), grr
      -- (references), gri (implementation), gO (symbols), K (hover) and
      -- <C-s> (signature help). Definition is the one with no default.
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition,
        { buffer = args.buf, desc = 'Go to definition' })
    end,
  })
end)
