local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add({ source = 'FabijanZulj/blame.nvim' })

  require('blame').setup()

  vim.keymap.set('n', '<Leader>gb', '<Cmd>BlameToggle<CR>',
    { desc = 'Git blame (toggle)' })

  -- Files with unresolved merge conflicts. Uses MiniPick.builtin.cli, which
  -- streams the command output; the previous implementation passed the result of
  -- vim.schedule as the item list, which is always nil.
  local pick = require('mini.pick')
  pick.registry.conflicts = function()
    return pick.builtin.cli(
      { command = { 'git', 'diff', '--name-only', '--diff-filter=U' } },
      { source = { name = 'Conflicts' } }
    )
  end

  vim.keymap.set('n', '<Leader>pc', pick.registry.conflicts,
    { desc = 'Pick conflicted files' })
end)
