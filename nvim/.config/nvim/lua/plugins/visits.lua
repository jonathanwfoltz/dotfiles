local safely = require('mini.misc').safely

safely('later', function()
  local visits = require('mini.visits')
  visits.setup()

  -- NOTE: the one accepted cross-file dependency -- HEAD comes from mini.git's
  -- per-buffer tracking, set up in plugins/git.lua. Safe because these keymaps
  -- can only fire on user input, long after both 'later' bodies have run.
  local function current_branch()
    -- mini.git only tracks buffers backed by a readable file, so an unnamed,
    -- scratch or terminal buffer has no data even inside a repository. Ask git
    -- about the cwd instead of giving up.
    local data = require('mini.git').get_buf_data(0)
    local branch = data and data.head_name
    if branch == nil then
      local out = vim.fn.systemlist({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' })
      if vim.v.shell_error == 0 then branch = out[1] end
    end
    if branch == nil then
      vim.notify('Not inside a git repository', vim.log.levels.WARN)
    end
    return branch
  end

  local function map_branch(lhs, action, desc)
    vim.keymap.set('n', '<Leader>' .. lhs, function()
      local branch = current_branch()
      if branch == nil then return end
      visits[action](branch)
    end, { desc = desc })
  end

  map_branch('al', 'add_label', 'Add branch label to current file')
  map_branch('rl', 'remove_label', 'Remove branch label from current file')

  vim.keymap.set('n', '<Leader>vl', function()
    local branch = current_branch()
    if branch == nil then return end
    require('mini.extra').pickers.visit_paths({ filter = branch })
  end, { desc = 'View files labelled with current branch' })

  -- No filter: every visited path in recency-and-frequency order.
  vim.keymap.set('n', '<Leader>vr', function()
    require('mini.extra').pickers.visit_paths()
  end, { desc = 'View recently visited files' })
end)
