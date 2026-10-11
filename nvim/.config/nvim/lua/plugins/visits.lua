local safely = require('mini.misc').safely

safely('later', function()
  local visits = require('mini.visits')
  visits.setup()

  -- HEAD comes from mini.git's per-buffer tracking, set up in plugins/git.lua.
  -- This is the one accepted cross-file dependency: these keymaps can only fire
  -- on user input, long after both 'later' bodies have run, and a nil head_name
  -- already has a handled path.
  local function current_branch()
    local data = require('mini.git').get_buf_data(0)
    local branch = data and data.head_name
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
end)
