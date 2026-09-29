-- Editor-global options only. Anything serving one plugin lives in that
-- plugin's file, and anything that restates a Neovim default is left out.
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
  sidescrolloff = 8,
  signcolumn = 'yes',
  smartcase = true,
  splitbelow = true,
  splitright = true,
  swapfile = false,
  tabstop = 2,
  -- NOTE: not a restated default. Inside a tmux pane with no COLORTERM,
  -- Neovim's detection settles on false and then sends undercurls with no
  -- colour at all.
  termguicolors = true,
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
