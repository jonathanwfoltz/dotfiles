local later = MiniDeps.later

later(function()
  local visits = require('mini.visits')
  visits.setup()

  local function current_branch()
    local result = vim.system(
      { 'git', 'rev-parse', '--abbrev-ref', 'HEAD' },
      { text = true }
    ):wait()
    if result.code ~= 0 then
      vim.notify('Not inside a git repository', vim.log.levels.WARN)
      return nil
    end
    return vim.trim(result.stdout)
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
