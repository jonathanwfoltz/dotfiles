local add = require('core.pack')
local safely = require('mini.misc').safely

-- NOTE: 'python' is load-bearing beyond highlighting -- nvim-dap-python's
-- test runner uses the parser to find the test under the cursor.
local parsers = { 'python', 'cpp', 'cmake', 'toml', 'yaml', 'json', 'bash' }

-- Filetypes, not parser names: lua, c and markdown ship their parsers with
-- Neovim, and 'sh' is the filetype whose parser is called 'bash'.
-- NOTE: this autocmd is the only thing that starts treesitter -- the main
-- branch attaches nothing by itself.
local filetypes = {
  'python', 'c', 'cpp', 'cmake', 'lua',
  'toml', 'yaml', 'json', 'sh', 'markdown',
}

-- NOTE: main needs Neovim 0.12 and tree-sitter-cli >= 0.26.1, which it shells
-- out to in order to compile parsers. The master branch is frozen at 0.11.
safely('later', function()
  add({
    {
      src = 'https://github.com/nvim-treesitter/nvim-treesitter',
      version = 'main',
    },
  })

  local ts = require('nvim-treesitter')
  ts.setup()
  ts.install(parsers)

  vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('treesitter_update', { clear = true }),
    desc = 'Update treesitter parsers after the plugin changes',
    callback = function(args)
      local data = args.data
      if data.spec.name ~= 'nvim-treesitter' then return end
      if data.kind ~= 'install' and data.kind ~= 'update' then return end
      require('nvim-treesitter').update()
    end,
  })

  -- Per buffer, so folding is window-local rather than a global that also
  -- applied to parserless buffers.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('treesitter_attach', { clear = true }),
    pattern = filetypes,
    desc = 'Start treesitter and use it for folds and indentation',
    callback = function()
      vim.treesitter.start()
      vim.wo[0][0].foldmethod = 'expr'
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[0][0].foldtext = 'v:lua.vim.treesitter.foldtext()'
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })

  vim.o.foldlevelstart = 99
  vim.o.foldcolumn = '1'
end)
