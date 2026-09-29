require('mason').setup()
require('mason-lspconfig').setup({
    ensure_installed = {
      'cssls',
      'ts_ls',
      'html',
      'tailwindcss',
      'pyright',
      'gopls',
    },
    automaticInstallation = true
})

local lspConfig = require('lspconfig')
lspConfig.cssls.setup{}
lspConfig.ts_ls.setup({
  init_options = {
    preferences = {
      importModuleSpecifierPreference = "non-relative",
    },
  },
})

lspConfig.html.setup{}
lspConfig.pyright.setup({
  settings = {
    python = {
      -- Replace with the actual path to your venv's python executable
      pythonPath = './.venv/bin/python'
    }
  }
})
lspConfig.gopls.setup{}

vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, { desc = 'Performs code action on current line.' })
