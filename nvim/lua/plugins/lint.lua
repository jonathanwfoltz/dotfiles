local add, later = MiniDeps.add, MiniDeps.later

-- This file was previously never loaded, so linting silently did nothing. The
-- directory scan in init.lua makes that failure mode impossible.
later(function()
  add({ source = 'mfussenegger/nvim-lint' })

  -- Lets eslint_d shut down with this Neovim instance rather than outliving it.
  vim.env.ESLINT_D_PPID = vim.fn.getpid()

  local lint = require('lint')
  lint.linters_by_ft = {
    javascript = { 'eslint_d' },
    javascriptreact = { 'eslint_d' },
    typescript = { 'eslint_d' },
    typescriptreact = { 'eslint_d' },
  }

  -- nvim-lint reports a hard error for every missing executable, which would
  -- otherwise fire on each buffer enter on a machine without eslint_d.
  local function available(name)
    local linter = lint.linters[name]
    if type(linter) == 'function' then linter = linter() end
    if type(linter) ~= 'table' then return false end

    local cmd = linter.cmd
    if type(cmd) == 'function' then cmd = cmd() end
    return type(cmd) ~= 'string' or vim.fn.executable(cmd) == 1
  end

  -- linters_by_ft on its own never runs anything; try_lint has to be called.
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
    group = vim.api.nvim_create_augroup('lint_on_change', { clear = true }),
    desc = 'Run the available linters for the current buffer',
    callback = function(args)
      local names = lint.linters_by_ft[vim.bo[args.buf].filetype]
      if not names then return end

      local runnable = vim.tbl_filter(available, names)
      if #runnable > 0 then lint.try_lint(runnable) end
    end,
  })
end)
