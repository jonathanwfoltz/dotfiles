local safely = require('mini.misc').safely

safely('later', function()
  -- mini.git ships with mini.nvim, which is already installed, so `:Git blame`
  -- replaces blame.nvim at no cost. It also tracks HEAD per buffer, which is
  -- what plugins/visits.lua reads instead of shelling out to git itself.
  require('mini.git').setup()

  vim.keymap.set('n', '<Leader>gb', '<Cmd>vert Git blame -- %<CR>',
    { desc = 'Git blame (toggle)' })

  -- Upstream's recipe: a bare blame split scrolls independently of the source,
  -- which is the one thing blame.nvim did better. Bind the two together.
  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('git_blame_align', { clear = true }),
    pattern = 'MiniGitCommandSplit',
    desc = 'Align a blame split with the window it came from',
    callback = function(args)
      if args.data.git_subcommand ~= 'blame' then return end

      local win_src = args.data.win_source
      vim.wo.wrap = false
      vim.fn.winrestview({ topline = vim.fn.line('w0', win_src) })
      vim.api.nvim_win_set_cursor(0, { vim.fn.line('.', win_src), 0 })
      vim.wo[win_src].scrollbind, vim.wo.scrollbind = true, true
    end,
  })

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
