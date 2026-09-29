vim.env.ESLINT_D_PPID = vim.fn.getpid()
require('lint').linters_by_ft = {
  javascript = { 'eslint_d' },
  typescript = { 'eslint_d' },
}
