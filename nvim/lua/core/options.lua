-- Editor-global options only. Anything that exists to serve one plugin lives in
-- that plugin's file instead: folding is in plugins/treesitter.lua, completeopt
-- in plugins/completion.lua. Anything that only restates a Neovim default is
-- left out: 'termguicolors' is auto-enabled when the terminal supports it, and
-- 'fileencoding' is buffer-local, so setting it here only ever reached the
-- first buffer anyway.
local options = {
  clipboard = 'unnamedplus',
  cmdheight = 2,
  cursorline = true,
  expandtab = true,
  ignorecase = true,
  mouse = '',
  number = true,
  relativenumber = true,
  pumheight = 10,
  scrolloff = 8,
  shiftwidth = 2,
  showmode = false,
  showtabline = 2,
  sidescrolloff = 8,
  signcolumn = 'yes',
  smartcase = true,
  smartindent = true,
  splitbelow = true,
  splitright = true,
  swapfile = false,
  tabstop = 2,
  undofile = true,
  updatetime = 300,
  writebackup = false,
  wrap = false,
}

for key, value in pairs(options) do
  vim.opt[key] = value
end

vim.opt.shortmess:append('c')
vim.opt.whichwrap:append('<,>,[,],h,l')
vim.opt.iskeyword:append('-')
