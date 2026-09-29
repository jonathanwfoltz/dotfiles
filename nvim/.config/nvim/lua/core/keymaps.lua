-- Editor-global keymaps only. A keymap driving a plugin lives in that plugin's
-- file; every mapping carries a desc.
local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- Window navigation
map('<C-h>', '<C-w>h', 'Go to left window')
map('<C-j>', '<C-w>j', 'Go to lower window')
map('<C-k>', '<C-w>k', 'Go to upper window')
map('<C-l>', '<C-w>l', 'Go to right window')

-- Window resize. Direction follows the key, matching tmux.conf's H/J/K/L.
map('<C-z>h', '<Cmd>vertical resize -2<CR>', 'Shrink window width')
map('<C-z>j', '<Cmd>resize +2<CR>', 'Grow window height')
map('<C-z>k', '<Cmd>resize -2<CR>', 'Shrink window height')
map('<C-z>l', '<Cmd>vertical resize +2<CR>', 'Grow window width')

-- Buffer navigation
map('<S-l>', '<Cmd>bnext<CR>', 'Next buffer')
map('<S-h>', '<Cmd>bprevious<CR>', 'Previous buffer')
