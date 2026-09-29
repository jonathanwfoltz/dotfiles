local path_package = vim.fn.stdpath('data') .. '/site'
local mini_path = path_package .. '/pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
end

-- Basic Mini plugins with little to no customization
require('mini.deps').setup({ path = { package = path_package } })
require('mini.icons').setup({
    style = 'glyph',
})
require('mini.indentscope').setup()
require('mini.statusline').setup()
require('mini.trailspace').setup({})
require('mini.files').setup({})

-- Non-mini plugins
local add = MiniDeps.add

add({
    source = 'neovim/nvim-lspconfig',
    depends =  { 'williamboman/mason.nvim', 'williamboman/mason-lspconfig' },
})

add({
    source = 'mhartington/formatter.nvim',
    depends =  { 'williamboman/mason.nvim' },
})

add({
    source = 'nvim-treesitter/nvim-treesitter',
})

add({
    source = 'rafamadriz/friendly-snippets',
})

add({
    source = 'FabijanZulj/blame.nvim',
})

add({
    source = 'folke/tokyonight.nvim',
})

local status_ok = pcall(vim.cmd, "colorscheme tokyonight-night")
if not status_ok then
    vim.notify('Colorscheme not found')
end

add({
    source = 'mfussenegger/nvim-lint',
})

add({
    source = 'm4xshen/hardtime.nvim',
    depends =  { 'MunifTanjim/nui.nvim' },
})


add({
    source = 'vinnymeller/swagger-preview.nvim',
})


add({
    source = 'obsidian-nvim/obsidian.nvim'
})

require("hardtime").setup()
