require('mini.files').setup()
vim.api.nvim_set_keymap('n', '<Leader>lf', ':lua MiniFiles.open() <CR>', {noremap = true, silent = true})
