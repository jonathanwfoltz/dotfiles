local add = require('core.pack')
local safely = require('mini.misc').safely

-- 'lua' is bundled with Neovim, so it is listed as a filetype only. 'c' is too,
-- but installing cpp pulls a local c grammar in alongside it the way tsx pulls
-- in ecma and jsx, so it ends up compiled either way.
local parsers = { 'html', 'css', 'typescript', 'tsx', 'python', 'go', 'cpp' }

-- Filetypes, not parser names: the tsx parser serves typescriptreact. Lua and C
-- get highlighting from $VIMRUNTIME/ftplugin, but only this autocmd gives them
-- treesitter folds and indentation.
local filetypes = {
  'html', 'css', 'typescript', 'typescriptreact', 'python', 'go',
  'lua', 'c', 'cpp',
}

-- The main branch requires Neovim 0.12 and tree-sitter-cli >= 0.26.1, which it
-- shells out to in order to compile parsers locally. The old master branch is
-- frozen at Neovim 0.11.
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

  -- Recompile parsers whenever vim.pack changes the plugin on disk, which is
  -- what the old post_checkout hook did.
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

  -- main attaches nothing by itself. Highlighting, folding and indenting are all
  -- per buffer, so they live here rather than in core/options.lua -- and folding
  -- is now window-local instead of a global that applied to parserless buffers
  -- too.
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
