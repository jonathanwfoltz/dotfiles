local safely = require('mini.misc').safely

safely('later', function()
  local pick = require('mini.pick')
  local extra = require('mini.extra')
  pick.setup()
  extra.setup()

  local function map(lhs, rhs, desc)
    vim.keymap.set('n', '<Leader>' .. lhs, rhs, { desc = desc })
  end

  -- vim.keymap.set calls its callback with no arguments, so these need no wrapper.
  map('pf', pick.builtin.files, 'Pick files')
  map('pg', pick.builtin.grep_live, 'Pick grep (live)')
  map('pd', extra.pickers.diagnostic, 'Pick diagnostics')
  map('pk', extra.pickers.keymaps, 'Pick keymaps')

  -- Git-tracked files beneath a single directory.
  local function tracked_files(cwd)
    return function()
      pick.builtin.files({ tool = 'git' }, { source = { cwd = cwd } })
    end
  end

  map('ps', tracked_files('./src'), 'Pick source files (./src)')
  map('pt', tracked_files('./test'), 'Pick test files (./test)')

  pick.registry.projects = function()
    local choose = function(item)
      vim.schedule(function()
        pick.builtin.files(nil, { source = { cwd = item.path } })
      end)
    end
    return extra.pickers.explorer(
      { cwd = vim.fn.expand('~/projects') },
      { source = { choose = choose } }
    )
  end

  map('pp', pick.registry.projects, 'Pick projects')
end)
