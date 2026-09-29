local add, later = MiniDeps.add, MiniDeps.later

local parsers = { 'html', 'css', 'typescript', 'tsx', 'python', 'go' }

later(function()
  -- Pinned to master deliberately. nvim-treesitter's main branch calls
  -- vim.list.unique, which does not exist before Neovim 0.12, so main requires a
  -- nightly build. To move once you are on 0.12: checkout = 'main', replace the
  -- configs.setup call below with
  --   require('nvim-treesitter').setup()
  --   require('nvim-treesitter').install(parsers)
  -- and attach per buffer from a FileType autocmd via vim.treesitter.start.
  add({
    source = 'nvim-treesitter/nvim-treesitter',
    checkout = 'master',
    monitor = 'master',
    hooks = {
      post_checkout = function() vim.cmd('TSUpdate') end,
    },
  })

  require('nvim-treesitter.configs').setup({
    ensure_installed = parsers,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
      use_languagetree = true,
    },
    indent = { enable = true },
  })

  -- Folding is driven entirely by treesitter, so it is configured here instead
  -- of core/options.lua, where it would error if treesitter failed to load.
  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  vim.opt.foldtext = 'v:lua.vim.treesitter.foldtext()'
  vim.opt.foldlevelstart = 99
  vim.opt.foldcolumn = '1'
end)
