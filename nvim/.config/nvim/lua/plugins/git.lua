local safely = require('mini.misc').safely

safely('later', function()
  -- Also tracks HEAD per buffer, which plugins/visits.lua reads.
  require('mini.git').setup()

  vim.keymap.set('n', '<Leader>gb', '<Cmd>vert Git blame -- %<CR>',
    { desc = 'Git blame in a split' })

  -- Upstream's recipe: a bare blame split scrolls independently of its source.
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

  -- Files with unresolved merge conflicts. builtin.cli streams the output.
  local pick = require('mini.pick')
  pick.registry.conflicts = function()
    return pick.builtin.cli(
      { command = { 'git', 'diff', '--name-only', '--diff-filter=U' } },
      { source = { name = 'Conflicts' } }
    )
  end

  vim.keymap.set('n', '<Leader>pc', pick.registry.conflicts,
    { desc = 'Pick conflicted files' })

  -- Every uncommitted hunk in the repository, where mini.diff's [h/]h walk one
  -- buffer. Required for its return value so this file stays order-free.
  vim.keymap.set('n', '<Leader>pH', function()
    require('mini.extra').pickers.git_hunks()
  end, { desc = 'Pick git hunks' })
end)
