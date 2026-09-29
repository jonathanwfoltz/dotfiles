local add = require('core.pack')
local safely = require('mini.misc').safely

-- The whole set. Per-server settings live in nvim/lsp/<name>.lua; servers
-- needing none have no file, clangd included.
local servers = { 'pyright', 'ruff', 'clangd', 'neocmake', 'lua_ls' }

safely('later', function()
  add({
    -- mason-org, not the widely-documented williamboman, which only redirects.
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    'https://github.com/neovim/nvim-lspconfig',
  })

  -- NOTE: guarded -- plugins/debug.lua also needs mason and either may run
  -- first; setup() appends its registries on every call.
  local mason = require('mason')
  if not mason.has_setup then mason.setup() end

  -- NOTE: defaults to true, which enables every installed mason package
  -- rather than this list -- and nothing at all on a fresh clone.
  require('mason-lspconfig').setup({
    ensure_installed = servers,
    automatic_enable = false,
  })

  vim.lsp.enable(servers)

  -- The full message under the cursor's line, where virtual_text truncates.
  -- Border scoped here rather than set globally via 'winborder'.
  vim.diagnostic.config({
    virtual_lines = { current_line = true },
    severity_sort = true,
    float = { border = 'rounded' },
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
    desc = 'Buffer-local LSP keymaps',
    callback = function(args)
      local buf = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      -- Core already gives grn, gra, grr, gri, gO, K and <C-s>. Definition is
      -- the one with no default.
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition,
        { buffer = buf, desc = 'Go to definition' })

      if client and client:supports_method('textDocument/inlayHint') then
        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
        vim.keymap.set('n', '<Leader>vi', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
        end, { buffer = buf, desc = 'View inlay hints (toggle)' })
      end

      -- NOTE: not in an lsp/clangd.lua -- a user file's on_attach replaces
      -- lspconfig's, deleting the command this maps to.
      if client and client.name == 'clangd' then
        vim.keymap.set('n', '<Leader>sh', '<Cmd>LspClangdSwitchSourceHeader<CR>',
          { buffer = buf, desc = 'Switch between source and header' })
      end
    end,
  })
end)
