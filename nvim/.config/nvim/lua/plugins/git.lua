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
  -- buffer. An unmerged path has no stage 0, so `git diff --patch` emits a
  -- combined diff (`@@@ ... @@@`) that mini.extra's hunk parser does not match
  -- -- mid conflict the picker is always empty. Fall back to the conflict
  -- blocks themselves so the one key keeps working; `:Pick git_hunks` still
  -- reaches the raw picker.
  local function git_lines(...)
    local out = vim.fn.systemlist({ 'git', ... })
    if vim.v.shell_error ~= 0 then return nil end
    return out
  end

  -- Region items: mini.pick's default show/preview/choose handle them, where
  -- git_hunks needs custom ones because its items are diff text.
  local function conflict_items(root, paths)
    local items = {}
    for _, rel in ipairs(paths) do
      local n = #items
      local ok, lines = pcall(vim.fn.readfile, root .. '/' .. rel)
      if ok then
        local start
        for i, l in ipairs(lines) do
          if l:find('^<<<<<<< ') ~= nil then
            start = i
          elseif l:find('^>>>>>>> ') ~= nil and start ~= nil then
            items[#items + 1] = {
              path = rel, lnum = start, col = 1, end_lnum = i, end_col = 1,
              text = string.format('%s:%d %s', rel, start, lines[start]),
            }
            start = nil
          end
        end
      end

      -- Delete/modify, add/add on a binary, or markers already resolved by
      -- hand: still unmerged, so it must not drop out of the list.
      if #items == n then
        items[#items + 1] = {
          path = rel, lnum = 1, col = 1,
          text = string.format('%s:1 (unmerged, no conflict markers)', rel),
        }
      end
    end
    return items
  end

  -- Required for its return value so this file stays order-free.
  pick.registry.hunks = function()
    local root = git_lines('rev-parse', '--show-toplevel')
    if root == nil then
      return vim.notify('Not inside a git repository', vim.log.levels.WARN)
    end

    local unmerged = git_lines('diff', '--name-only', '--diff-filter=U') or {}
    if #unmerged == 0 then return require('mini.extra').pickers.git_hunks() end

    return pick.start({
      source = {
        items = conflict_items(root[1], unmerged),
        name = 'Git conflicts',
        cwd = root[1],
      },
    })
  end

  vim.keymap.set('n', '<Leader>pH', pick.registry.hunks,
    { desc = 'Pick git hunks' })
end)
