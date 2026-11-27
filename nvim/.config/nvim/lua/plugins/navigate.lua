local safely = require('mini.misc').safely

-- One key set across nvim splits and tmux panes. tmux.conf passes C-h/j/k/l
-- through to nvim, and at the edge of the layout nvim hands the move back.
safely('later', function()
  local tmux_dir = { h = 'L', j = 'D', k = 'U', l = 'R' }

  local function navigate(dir)
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(dir)
    if vim.api.nvim_get_current_win() == win and vim.env.TMUX and vim.env.TMUX_PANE then
      vim.system({ 'tmux', 'select-pane', '-t', vim.env.TMUX_PANE, '-' .. tmux_dir[dir] })
    end
  end

  local names = { h = 'left', j = 'lower', k = 'upper', l = 'right' }
  for dir, name in pairs(names) do
    vim.keymap.set('n', '<C-' .. dir .. '>', function()
      navigate(dir)
    end, { desc = 'Go to ' .. name .. ' window or tmux pane' })
  end
end)
