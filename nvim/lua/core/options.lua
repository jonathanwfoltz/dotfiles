-- Editor-global options only. Anything that exists to serve one plugin lives in
-- that plugin's file instead: folding is in plugins/treesitter.lua, completeopt
-- in plugins/completion.lua.
local options = {
  backup = false,
  clipboard = 'unnamedplus',
  cmdheight = 2,
  conceallevel = 0,
  cursorline = true,
  expandtab = true,
  fileencoding = 'utf-8',
  guifont = 'monospace:h17',
  hlsearch = true,
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
  termguicolors = true,
  timeoutlen = 1000,
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
