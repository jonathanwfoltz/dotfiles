require('general.helper')

-- Set default ops
local opts = {noremap = true, silent = true}

-- Rebind local leader

KEYMAP("", "<Space>", "<Nop>", opts)
GLOBAL.mapleader = ' '
GLOBAL.maplocalleader = '<Space>'

-- Normal
local mode = 'n'

-- Window Nav
KEYMAP(mode, '<C-h>', '<C-w>h', opts)
KEYMAP(mode, '<C-j>', '<C-w>j', opts)
KEYMAP(mode, '<C-k>', '<C-w>k', opts)
KEYMAP(mode, '<C-l>', '<C-w>l', opts)

-- Pane Resize
KEYMAP(mode, '<C-z>h', ':resize -2<CR>', opts)
KEYMAP(mode, '<C-z>j', ':resize +2<CR>', opts)
KEYMAP(mode, '<C-z>k', ':vertical resize -2<CR>', opts)
KEYMAP(mode, '<C-z>l', ':vertical resize +2<CR>', opts)

-- Navigate
KEYMAP(mode, '<S-l>', ':bnext<CR>', opts)
KEYMAP(mode, '<S-h>', ':bprev<CR>', opts)

KEYMAP(mode, '<Leader>gi', ':lua vim.lsp.buf.implementation()<CR>', opts)
KEYMAP(mode, '<Leader>grn', ':lua vim.lsp.buf.rename()<CR>', opts)
KEYMAP(mode, '<Leader>gr', ':lua vim.lsp.buf.references()<CR>', opts)
KEYMAP(mode, '<Leader>gt', ':lua vim.lsp.buf.type_definition()<CR>', opts)
KEYMAP(mode, '<Leader>gs', ':lua vim.lsp.buf.document_symbol()<CR>', opts)
KEYMAP(mode, '<Leader>ga', ':lua vim.lsp.buf.code_action()<CR>', opts)
